//+------------------------------------------------------------------+
//| Include/AutoTrader/app/Orchestrator.mqh                          |
//| Orchestrator with Event Handler - Clean Architecture             |
//+------------------------------------------------------------------+

#property strict

// Required ports
#include <AutoTrader/domain/entities/TradeSignal.mqh>
#include <AutoTrader/domain/ports/IExecution.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ISignal.mqh>

// Optional ports
#include <AutoTrader/domain/ports/IExitSignal.mqh>
#include <AutoTrader/domain/ports/IRisk.mqh>
#include <AutoTrader/domain/ports/ISizer.mqh>
#include <AutoTrader/domain/ports/ITargets.mqh>
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>
#include <AutoTrader/domain/ports/ITrailing.mqh>

class Orchestrator {
  private:
    // === Required dependencies ===
    ISignal *m_signal;
    IExecution *m_exec;
    IMarketData *m_md;

    // === Optional dependencies ===
    IExitSignal *m_exitSig;
    ITrailing *m_trailer;
    IRisk *m_risk;
    ISizer *m_sizer;
    ITargets *m_targets;
    ITradeEventHandler *m_event; // === Context ===
    string m_sym;
    ENUM_TIMEFRAMES m_tf;
    int m_deviation;
    long m_magic;

    //+------------------------------------------------------------------+
    //| Trigger trade event with safety checks                           |
    //+------------------------------------------------------------------+
    void TriggerEvent(TRADE_EVENT_TYPE type, ulong ticket, double volume, double price, double sl,
                      double tp, string comment = "") {
        if(m_event == NULL) return;
        if(!m_event.ShouldHandle(type)) return;

        TradeEventContext ctx;
        ctx.eventType = type;
        ctx.symbol    = m_sym;
        ctx.magic     = m_magic;
        ctx.ticket    = ticket;
        ctx.volume    = volume;
        ctx.price     = price;
        ctx.sl        = sl;
        ctx.tp        = tp;
        ctx.comment   = comment;
        ctx.eventTime = TimeCurrent();

        m_event.OnTradeEvent(ctx);
    }

    //+------------------------------------------------------------------+
    //| Handle exit logic                                                |
    //+------------------------------------------------------------------+
    bool HandleExit() {
        if(m_exitSig == NULL) return false;

        ulong closeTickets[];
        if(!m_exitSig.ShouldExit(m_sym, m_tf, m_magic, closeTickets)) return false;
        if(ArraySize(closeTickets) == 0) return false;
        int closed = m_exec.ClosePositionsByTickets(closeTickets);
        return closed > 0;
    }

    //+------------------------------------------------------------------+
    //| Handle trailing stop logic                                       |
    //+------------------------------------------------------------------+
    bool HandleTrailing() {
        if(m_trailer == NULL) return false;
        return m_trailer.Manage(m_sym, m_tf, m_magic);
    }

    //+------------------------------------------------------------------+
    //| Handle pending orders cancellation                               |
    //| Exit strategy now self-contains order query logic                |
    //+------------------------------------------------------------------+
    bool HandleOrderCancellation() {
        if(m_exitSig == NULL) return false;

        // Exit strategy decides which orders to cancel (has access to m_orders internally)
        ulong cancelTickets[];
        if(!m_exitSig.GetOrdersToCancel(m_sym, m_tf, m_magic, cancelTickets)) return false;
        if(ArraySize(cancelTickets) == 0) return false;

        // Execute cancellation
        int deleted = 0;
        for(int i = 0; i < ArraySize(cancelTickets); i++) {
            if(m_exec.DeletePending(cancelTickets[i])) deleted++;
        }

        return deleted > 0;
    } //+------------------------------------------------------------------+
    //| Handle trade entry logic - supports multiple signals             |
    //+------------------------------------------------------------------+
    bool HandleEntry() {
        // Get signals (may return 1 or more)
        TradeSignal signals[];
        if(!m_signal.ShouldEnterMulti(m_sym, m_tf, signals)) return false;
        if(ArraySize(signals) == 0) return false;

        bool anySuccess                = false;
        int successCount               = 0;
        const int MAX_ENTRIES_PER_TICK = 10; // Safety limit

        // Process each signal
        for(int i = 0; i < ArraySize(signals) && i < MAX_ENTRIES_PER_TICK; i++) {
            TradeSignal sig = signals[i];

            // Validate signal
            if(!sig.valid) {
                Print("Signal[", i, "] invalid, skipping");
                continue;
            }

            if(sig.price <= 0) {
                Print("Signal[", i, "] has invalid price=", sig.price, ", skipping");
                continue;
            }

            Print("Signal[", i, "] received: type=", EnumToString(sig.type), " isSell=", sig.isSell,
                  " price=", sig.price, " stopPoints=", sig.stopPoints, " sl=", sig.sl,
                  " tp=", sig.tp);

            // Risk gate for EACH signal
            if(m_risk != NULL && !m_risk.AllowTrade(m_sym, m_magic)) {
                Print("Signal[", i, "] blocked by risk policy");
                break; // Stop processing remaining signals if risk doesn't allow
            }

            // Compute targets for this signal
            double sl_final = sig.sl;
            double tp_final = sig.tp;
            if(m_targets != NULL) {
                if(!m_targets.Compute(m_sym, sig.isSell, sig.price, sig.sl, sl_final, tp_final)) {
                    sl_final = sig.sl;
                    tp_final = sig.tp;
                }
            }
            // Calculate lot size for this signal
            const double lots
                = (m_sizer != NULL) ? m_sizer.Lots(m_sym, sig.stopPoints, 0.10, m_magic) : 0.10;
            if(lots <= 0) {
                Print("Signal[", i, "] calculated lots=", lots, " invalid, skipping");
                continue;
            }

            // Execute trade
            ulong ticket = 0;
            bool success = m_exec.OpenTrade(m_sym, m_magic, sig.type, lots, sig.price, sl_final,
                                            tp_final, m_deviation, ticket, sig.comment);

            if(success && ticket > 0) {
                anySuccess = true;
                successCount++;
                Print("Signal[", i, "] executed successfully, ticket=", ticket);
            } else {
                Print("Signal[", i, "] execution failed");
            }
        }

        if(successCount > 0) {
            Print("HandleEntry: ", successCount, "/", ArraySize(signals), " signals executed");
        }

        return anySuccess;
    }

    // AccTest1998
  public:
    //+------------------------------------------------------------------+
    //| Constructor - only required dependencies                         |
    //+------------------------------------------------------------------+
    Orchestrator(const string symbol, const ENUM_TIMEFRAMES timeframe, const int deviation_points,
                 const long magic, ISignal *signal, IExecution *exec, IMarketData *md)
        : m_signal(signal), m_exec(exec), m_md(md), m_exitSig(NULL), m_trailer(NULL), m_risk(NULL),
          m_sizer(NULL), m_targets(NULL), m_event(NULL), m_sym(symbol), m_tf(timeframe),
          m_deviation(deviation_points), m_magic(magic) {
        if(m_signal == NULL || m_exec == NULL || m_md == NULL) {
            Print("ERROR: Orchestrator requires Signal, Execution, and MarketData!");
        }
    }
    // Hàm kiểm tra trạng thái sẵn sàng
    bool IsReady() const { return (m_signal != NULL && m_exec != NULL && m_md != NULL); }

    //+------------------------------------------------------------------+
    //| Setters for optional dependencies                                |
    //+------------------------------------------------------------------+
    void SetExitSignal(IExitSignal *ex) { m_exitSig = ex; }
    void SetTrailing(ITrailing *tr) { m_trailer = tr; }
    void SetRisk(IRisk *rk) { m_risk = rk; }
    void SetSizer(ISizer *sz) { m_sizer = sz; }
    void SetTargets(ITargets *tg) { m_targets = tg; }
    void SetEventHandler(ITradeEventHandler *eh) {
        m_event = eh;
    } //+------------------------------------------------------------------+
    //| Main tick processing loop                                        |
    //+------------------------------------------------------------------+
    void OnTick() {
        if(m_signal == NULL || m_exec == NULL || m_md == NULL) return;

        // 1) Exit positions (highest priority)
        if(HandleExit()) return;

        // 2) Trailing stop management
        HandleTrailing();

        // 3) Cancel pending orders if needed
        if(HandleOrderCancellation()) return;

        // 4) Entry logic
        HandleEntry();
    }

    //+------------------------------------------------------------------+
    //| Handle MT5 trade transactions                                    |
    //+------------------------------------------------------------------+
    void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request,
                            const MqlTradeResult &result) {
        // Chỉ xử lý transaction của symbol và magic hiện tại
        if(trans.symbol != m_sym) return;

        // Lọc theo magic number (nếu có)
        if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
            ulong deal = trans.deal;
            if(HistoryDealSelect(deal)) {
                long dealMagic = HistoryDealGetInteger(deal, DEAL_MAGIC);
                if(dealMagic != m_magic) return;
            }
        }

        // Xử lý các loại transaction
        switch(trans.type) {
        case TRADE_TRANSACTION_ORDER_ADD: HandleOrderAdd(trans); break;

        case TRADE_TRANSACTION_ORDER_DELETE: HandleOrderDelete(trans); break;

        case TRADE_TRANSACTION_DEAL_ADD: HandleDealAdd(trans); break;

        case TRADE_TRANSACTION_POSITION: HandlePositionChange(trans); break;

        case TRADE_TRANSACTION_REQUEST:
            // Request đã được xử lý, có thể log nếu cần
            break;
        }
    }

  private:
    //+------------------------------------------------------------------+
    //| Handle order added (pending order placed)                        |
    //+------------------------------------------------------------------+
    void HandleOrderAdd(const MqlTradeTransaction &trans) {
        if(trans.order_state != ORDER_STATE_PLACED) return;

        ulong ticket = trans.order;
        if(!OrderSelect(ticket)) return;

        double volume  = OrderGetDouble(ORDER_VOLUME_CURRENT);
        double price   = OrderGetDouble(ORDER_PRICE_OPEN);
        double sl      = OrderGetDouble(ORDER_SL);
        double tp      = OrderGetDouble(ORDER_TP);
        string comment = OrderGetString(ORDER_COMMENT);

        TriggerEvent(TRADE_EVENT_ORDER_PLACED, ticket, volume, price, sl, tp, comment);
    }

    //+------------------------------------------------------------------+
    //| Handle order deleted (cancelled or filled)                       |
    //+------------------------------------------------------------------+
    void HandleOrderDelete(const MqlTradeTransaction &trans) {
        ulong ticket = trans.order;

        // Kiểm tra xem order bị cancel hay filled
        if(trans.order_state == ORDER_STATE_CANCELED || trans.order_state == ORDER_STATE_REJECTED) {
            if(HistoryOrderSelect(ticket)) {
                double volume = HistoryOrderGetDouble(ticket, ORDER_VOLUME_INITIAL);
                double price  = HistoryOrderGetDouble(ticket, ORDER_PRICE_OPEN);

                TriggerEvent(TRADE_EVENT_ORDER_CANCEL, ticket, volume, price, 0, 0, "Cancelled");
            }
        }
        // Nếu order_state == FILLED thì sẽ có DEAL_ADD event theo sau
    }

    //+------------------------------------------------------------------+
    //| Handle deal added (order filled or position closed)              |
    //+------------------------------------------------------------------+
    void HandleDealAdd(const MqlTradeTransaction &trans) {
        ulong deal = trans.deal;
        if(!HistoryDealSelect(deal)) return;

        ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
        ENUM_DEAL_TYPE dealType   = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);

        // Bỏ qua deal balance/credit
        if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL) return;

        ulong ticket   = HistoryDealGetInteger(deal, DEAL_POSITION_ID);
        double volume  = HistoryDealGetDouble(deal, DEAL_VOLUME);
        double price   = HistoryDealGetDouble(deal, DEAL_PRICE);
        double profit  = HistoryDealGetDouble(deal, DEAL_PROFIT);
        double sl      = HistoryDealGetDouble(deal, DEAL_SL);
        double tp      = HistoryDealGetDouble(deal, DEAL_TP);
        string comment = HistoryDealGetString(deal, DEAL_COMMENT);

        switch(dealEntry) {
        case DEAL_ENTRY_IN:
            // Order được fill -> Mở position mới
            TriggerEvent(TRADE_EVENT_ORDER_FILLED, ticket, volume, price, sl, tp, comment);
            break;

        case DEAL_ENTRY_OUT:
            // Position đóng hoàn toàn
            TriggerEvent(TRADE_EVENT_CLOSE, ticket, volume, price, 0, 0,
                         StringFormat("%s P/L:%.2f", comment, profit));
            break;

        case DEAL_ENTRY_INOUT:
            // Reverse position
            TriggerEvent(TRADE_EVENT_CLOSE, ticket, volume, price, 0, 0, "Reverse");
            break;

        case DEAL_ENTRY_OUT_BY:
            // Position đóng bởi opposite position
            TriggerEvent(TRADE_EVENT_CLOSE, ticket, volume, price, 0, 0, "ClosedBy");
            break;
        }
    }

    //+------------------------------------------------------------------+
    //| Handle position modification (SL/TP changed)                     |
    //+------------------------------------------------------------------+
    void HandlePositionChange(const MqlTradeTransaction &trans) {
        ulong ticket = trans.position;
        if(!PositionSelectByTicket(ticket)) return;

        double volume = PositionGetDouble(POSITION_VOLUME);
        double price  = PositionGetDouble(POSITION_PRICE_CURRENT);
        double sl     = PositionGetDouble(POSITION_SL);
        double tp     = PositionGetDouble(POSITION_TP);

        // Phân biệt trailing vs modify thông thường qua comment hoặc logic
        TriggerEvent(TRADE_EVENT_MODIFY, ticket, volume, price, sl, tp, "Modified");
    }

  public:
    //+------------------------------------------------------------------+
    //| Cleanup on deinit                                                |
    //+------------------------------------------------------------------+

    void OnDeinit() {
        if(m_event != NULL) { TriggerEvent(TRADE_EVENT_SYSTEM, 0, 0, 0, 0, 0, "OnDeinit"); }
    }
};