//+------------------------------------------------------------------+
//|                                     TradingPanelEventHandler.mqh |
//|                  Event handler với TradingPanel UI integration    |
//+------------------------------------------------------------------+
#property copyright "AutoTrader"
#property version "1.00"

#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/IOrders.mqh>
#include <AutoTrader/domain/ports/IPositions.mqh>
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>
#include <AutoTrader/ui/TradingPanel.mqh>

//+------------------------------------------------------------------+
//| TradingPanelEventHandler - Hiển thị trade events trên panel     |
//+------------------------------------------------------------------+
class TradingPanelEventHandler : public ITradeEventHandler {
  private:
    TradingPanel *m_panel;
    bool m_ownPanel; // True nếu handler tự tạo panel

    // Dependencies
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    ulong m_magic;
    IPositions *m_positions;
    IOrders *m_orders;
    IMarketData *m_marketData;

    // Statistics
    int m_totalTrades;
    int m_openPositions;
    int m_pendingOrders;
    double m_totalProfit;
    double m_totalLoss;
    int m_winTrades;
    int m_lossTrades;
    string m_banlanle;

    // Last event info
    string m_lastEventType;
    string m_lastSymbol;
    double m_lastPrice;
    datetime m_lastEventTime;

  public:
    //--- Constructor chính với dependencies
    TradingPanelEventHandler(string symbol, ENUM_TIMEFRAMES timeframe, ulong magic,
                             IPositions *positions, IOrders *orders, IMarketData *marketData,
                             string title = "Trading Monitor", int x = 10, int y = 30,
                             int width = 420) {
        m_symbol     = symbol;
        m_timeframe  = timeframe;
        m_magic      = magic;
        m_positions  = positions;
        m_orders     = orders;
        m_marketData = marketData;

        m_panel      = new TradingPanel(title, x, y, width);
        m_panel.Create(symbol, EnumToString(timeframe), (int)magic);
        m_ownPanel = true;
        InitStats();
        SetupPanel();
    }

    //--- Constructor đơn giản (backward compatible)
    TradingPanelEventHandler(string title = "Trading Monitor", int x = 10, int y = 30,
                             int width = 350) {
        m_symbol     = _Symbol;
        m_timeframe  = PERIOD_CURRENT;
        m_magic      = 0;
        m_positions  = NULL;
        m_orders     = NULL;
        m_marketData = NULL;

        m_panel      = new TradingPanel(title, x, y, width);
        m_panel.Create(_Symbol, EnumToString(PERIOD_CURRENT), 0);
        m_ownPanel = true;
        InitStats();
        SetupPanel();
    }

    //--- Constructor với panel có sẵn
    TradingPanelEventHandler(TradingPanel *panel, string symbol, ENUM_TIMEFRAMES timeframe,
                             ulong magic, IPositions *positions, IOrders *orders,
                             IMarketData *marketData) {
        m_symbol     = symbol;
        m_timeframe  = timeframe;
        m_magic      = magic;
        m_positions  = positions;
        m_orders     = orders;
        m_marketData = marketData;
        m_panel      = panel;
        m_ownPanel   = false;
        InitStats();
    }

    //--- Destructor
    ~TradingPanelEventHandler() {
        if(m_ownPanel && m_panel != NULL) {
            m_panel.Destroy();
            delete m_panel;
        }
    }

    //--- Handle trade events
    void OnTradeEvent(const TradeEventContext &ctx) override {
        UpdateStats(ctx);
        UpdatePanel(ctx);
        LogEvent(ctx);
    }

    //--- Filter events
    bool ShouldHandle(TRADE_EVENT_TYPE eventType) override {
        // Handle tất cả events
        return true;
    }

    //--- Get panel reference
    TradingPanel *GetPanel() { return m_panel; }

    //--- Reset statistics
    void ResetStats() {
        InitStats();
        UpdatePanelStats();
    }

  private:
    //--- Initialize statistics
    void InitStats() {
        m_totalTrades   = 0;
        m_openPositions = CountCurrentPositions();
        m_pendingOrders = CountCurrentOrders();
        m_totalProfit   = 0.0;
        m_totalLoss     = 0.0;
        m_winTrades     = 0;
        m_lossTrades    = 0;
        m_banlanle      = "N/A";
        m_lastEventType = "N/A";
        m_lastSymbol    = "";
        m_lastPrice     = 0.0;
        m_lastEventTime = 0;
    }

    //--- Count positions for symbol and magic
    int CountCurrentPositions() {
        if(m_positions == NULL) { return PositionsTotal(); }
        return m_positions.CountBySymbolMagic(m_symbol, m_magic);
    }

    //--- Count orders for symbol and magic
    int CountCurrentOrders() {
        if(m_orders == NULL) { return OrdersTotal(); }
        return m_orders.CountBySymbolMagic(m_symbol, m_magic);
    }

    //--- Setup panel initial state
    void SetupPanel() {
        // Status text
        m_panel.AddText("📊 Trading Monitor Active");

        // Statistics rows
        m_panel.AddRow("Total Trades", IntegerToString(m_totalTrades));
        m_panel.AddRow("Open Positions", IntegerToString(m_openPositions));
        m_panel.AddRow("Pending Orders", IntegerToString(m_pendingOrders));
        m_panel.AddRow("banlanle", "N/A");
        m_panel.AddRow("Last Event", m_lastEventType);

        // Set log limit
        m_panel.SetMaxLogs(5);

        // Initial log
        m_panel.AddLog("✅ Trading panel initialized");
    }

    //--- Update statistics from event
    void UpdateStats(const TradeEventContext &ctx) {
        m_lastEventType = EventTypeToString(ctx.eventType);
        m_lastSymbol    = ctx.symbol;
        m_lastPrice     = ctx.price;
        m_lastEventTime = ctx.eventTime;

        switch(ctx.eventType) {
        case TRADE_EVENT_OPEN:
        case TRADE_EVENT_ORDER_FILLED:
            m_totalTrades++;
            m_openPositions = CountCurrentPositions();
            UpdateBanlanle(ctx);
            break;

        case TRADE_EVENT_CLOSE:
            m_openPositions = CountCurrentPositions();
            UpdateProfitStats(ctx);
            UpdateBanlanle(ctx);
            break;

        case TRADE_EVENT_PARTIAL_CLOSE:
            UpdateProfitStats(ctx);
            UpdateBanlanle(ctx);
            break;

        case TRADE_EVENT_ORDER_PLACED:
            m_pendingOrders = CountCurrentOrders();
            UpdateBanlanle(ctx);
            break;

        case TRADE_EVENT_ORDER_CANCEL:
            m_pendingOrders = CountCurrentOrders();
            UpdateBanlanle(ctx);
            break;

        case TRADE_EVENT_MODIFY:
        case TRADE_EVENT_TRAILING: UpdateBanlanle(ctx); break;
        }
    }

    //--- Update banlanle từ event context
    void UpdateBanlanle(const TradeEventContext &ctx) {
        // Lấy balance từ account
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_banlanle     = StringFormat("%.2f USD", balance);
    }

    //--- Update profit/loss statistics
    void UpdateProfitStats(const TradeEventContext &ctx) {
        // Get position profit from ticket
        if(PositionSelectByTicket(ctx.ticket)) {
            double profit = PositionGetDouble(POSITION_PROFIT);

            if(profit > 0) {
                m_totalProfit += profit;
                m_winTrades++;
            } else if(profit < 0) {
                m_totalLoss += profit;
                m_lossTrades++;
            }
        }
    }

    //--- Update panel display
    void UpdatePanel(const TradeEventContext &ctx) {
        // Update info row với dependencies
        m_panel.UpdateInfo(m_symbol, EnumToString(m_timeframe), (int)m_magic);

        // Update market data nếu có
        UpdateMarketInfo();

        // Update statistics rows
        UpdatePanelStats();
    }

    //--- Update market information
    void UpdateMarketInfo() {
        if(m_marketData == NULL) return;

        // Có thể thêm rows hiển thị thông tin market
        double bid, ask;
        if(m_marketData.LastBidAsk(m_symbol, bid, ask)) {
            // Update existing rows hoặc thêm mới nếu cần
            // m_panel.UpdateRow("Bid", DoubleToString(bid, _Digits));
            // m_panel.UpdateRow("Ask", DoubleToString(ask, _Digits));
        }
    }

    //--- Update panel statistics display
    void UpdatePanelStats() {
        m_panel.UpdateRow("Total Trades", IntegerToString(m_totalTrades));
        m_panel.UpdateRow("Open Positions", IntegerToString(m_openPositions));
        m_panel.UpdateRow("Pending Orders", IntegerToString(m_pendingOrders));
        m_panel.UpdateRow("banlanle", m_banlanle);

        // Last event
        m_panel.UpdateRow("Last Event", m_lastEventType);
    }

    //--- Log event to panel
    void LogEvent(const TradeEventContext &ctx) {
        string emoji = GetEventEmoji(ctx.eventType);
        string msg   = StringFormat("%s %s | %s @ %.5f", emoji, EventTypeToString(ctx.eventType),
                                    ctx.symbol, ctx.price);

        if(ctx.volume > 0) { msg += " | Vol: " + DoubleToString(ctx.volume, 2); }

        if(ctx.comment != "") { msg += " | " + ctx.comment; }

        m_panel.AddLog(msg);
    }

    //--- Convert event type to string
    string EventTypeToString(TRADE_EVENT_TYPE eventType) {
        switch(eventType) {
        case TRADE_EVENT_OPEN: return "OPEN";
        case TRADE_EVENT_CLOSE: return "CLOSE";
        case TRADE_EVENT_MODIFY: return "MODIFY";
        case TRADE_EVENT_PARTIAL_CLOSE: return "PARTIAL";
        case TRADE_EVENT_TRAILING: return "TRAILING";
        case TRADE_EVENT_ORDER_PLACED: return "ORDER_PLACED";
        case TRADE_EVENT_ORDER_FILLED: return "ORDER_FILLED";
        case TRADE_EVENT_ORDER_CANCEL: return "ORDER_CANCEL";
        case TRADE_EVENT_SYSTEM: return "SYSTEM";
        default: return "UNKNOWN";
        }
    }

    //--- Get emoji for event type
    string GetEventEmoji(TRADE_EVENT_TYPE eventType) {
        switch(eventType) {
        case TRADE_EVENT_OPEN: return "🟢";
        case TRADE_EVENT_CLOSE: return "🔴";
        case TRADE_EVENT_MODIFY: return "🔧";
        case TRADE_EVENT_PARTIAL_CLOSE: return "🟠";
        case TRADE_EVENT_TRAILING: return "📈";
        case TRADE_EVENT_ORDER_PLACED: return "📋";
        case TRADE_EVENT_ORDER_FILLED: return "✅";
        case TRADE_EVENT_ORDER_CANCEL: return "❌";
        case TRADE_EVENT_SYSTEM: return "⚙️";
        default: return "❓";
        }
    }

    //--- Format profit/loss with color indicator
    string FormatProfitLoss(double pl) {
        string sign  = pl >= 0 ? "+" : "";
        string emoji = pl > 0 ? "💰" : (pl < 0 ? "💸" : "➖");
        return emoji + " " + sign + DoubleToString(pl, 2) + " USD";
    }
};
//+------------------------------------------------------------------+
