//+------------------------------------------------------------------+
//|                                        SimpleLoggingHandler.mqh |
//|                                  Copyright 2025, AutoTrader Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AutoTrader Team"
#property version "1.00"
#property strict

#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>

//+------------------------------------------------------------------+
//| Simple Logging Event Handler (console only)                      |
//+------------------------------------------------------------------+
class SimpleLoggingHandler : public ITradeEventHandler {
  public:
    SimpleLoggingHandler() {}
    ~SimpleLoggingHandler() {}

    void OnTradeEvent(const TradeEventContext &ctx) override {
        string eventName = GetEventName(ctx.eventType);

        PrintFormat("[%s] %s | Ticket: %I64u | Symbol: %s | Price: %.5f | Vol: %.2f | SL: %.5f | "
                    "TP: %.5f | Comment: %s",
                    TimeToString(ctx.eventTime, TIME_DATE | TIME_SECONDS), eventName, ctx.ticket,
                    ctx.symbol, ctx.price, ctx.volume, ctx.sl, ctx.tp, ctx.comment);
    }

  private:
    string GetEventName(TRADE_EVENT_TYPE type) {
        switch(type) {
        case TRADE_EVENT_OPEN: return "OPEN";
        case TRADE_EVENT_CLOSE: return "CLOSE";
        case TRADE_EVENT_MODIFY: return "MODIFY";
        case TRADE_EVENT_PARTIAL_CLOSE: return "PARTIAL_CLOSE";
        case TRADE_EVENT_TRAILING: return "TRAILING";
        case TRADE_EVENT_ORDER_PLACED: return "ORDER_PLACED";
        case TRADE_EVENT_ORDER_FILLED: return "ORDER_FILLED";
        case TRADE_EVENT_ORDER_CANCEL: return "ORDER_CANCEL";
        case TRADE_EVENT_SYSTEM: return "SYSTEM";
        default: return "UNKNOWN";
        }
    }
};
