
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>

//+------------------------------------------------------------------+
//| StorageEventHandler.mqh - Database storage                        |
//+------------------------------------------------------------------+
#include <AutoTrader/adapters/storage/SQLiteStorage.mqh>
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>

class StorageEventHandler : public ITradeEventHandler {
  private:
    SQLiteStorage *m_storage;

  public:
    StorageEventHandler(string dbPath) { m_storage = new SQLiteStorage(dbPath); }

    ~StorageEventHandler() {
        if(m_storage != NULL) {
            m_storage.Flush();
            delete m_storage;
        }
    }

    void SetStrategyHeader(string name, string version, string symbol, ENUM_TIMEFRAMES tf,
                           long magic, string params, string currency) {
        if(m_storage != NULL) {
            m_storage.SetStrategyHeader(name, version, symbol, tf, magic, params, currency);
        }
    }

    void OnTradeEvent(const TradeEventContext &ctx) override {
        if(m_storage == NULL) return;

        switch(ctx.eventType) {
        case TRADE_EVENT_ORDER_PLACED:
            m_storage.SaveOrderOpen(ctx.symbol, ctx.magic, ctx.ticket, ORDER_TYPE_BUY, ctx.volume,
                                    ctx.price, ctx.sl, ctx.tp, ctx.eventTime);
            break;

        case TRADE_EVENT_ORDER_FILLED:
            m_storage.SaveOrderFilled(ctx.symbol, ctx.magic, ctx.ticket, ctx.volume, ctx.price,
                                      ctx.eventTime);
            m_storage.SaveTradeOpen(ctx.symbol, ctx.magic, ctx.ticket, ORDER_TYPE_BUY, ctx.volume,
                                    ctx.price, ctx.sl, ctx.tp, ctx.eventTime);
            break;

        case TRADE_EVENT_ORDER_CANCEL:
            m_storage.SaveOrderCancel(ctx.symbol, ctx.magic, ctx.ticket, ctx.eventTime);
            break;

        case TRADE_EVENT_CLOSE:
            m_storage.SaveTradeClose(ctx.symbol, ctx.magic, ctx.ticket, ctx.volume, ctx.price,
                                     ctx.eventTime, ctx.comment);
            break;

        case TRADE_EVENT_MODIFY:
            m_storage.SaveOrderModify(ctx.symbol, ctx.magic, ctx.ticket, ctx.sl, ctx.tp,
                                      ctx.eventTime);
            break;

        case TRADE_EVENT_TRAILING:
            m_storage.SaveTrailing(ctx.symbol, ctx.magic, ctx.ticket, ctx.sl, ctx.eventTime);
            break;

        case TRADE_EVENT_SYSTEM: m_storage.Flush(); break;
        }
    }
};
