// domain/ports/ITradeEventHandler.mqh
#ifndef ITRADE_EVENT_HANDLER_MQH
#define ITRADE_EVENT_HANDLER_MQH

enum TRADE_EVENT_TYPE {
  TRADE_EVENT_OPEN,
  TRADE_EVENT_CLOSE,
  TRADE_EVENT_MODIFY,
  TRADE_EVENT_PARTIAL_CLOSE,
  TRADE_EVENT_TRAILING,
  TRADE_EVENT_ORDER_PLACED,
  TRADE_EVENT_ORDER_FILLED,
  TRADE_EVENT_ORDER_CANCEL,
  TRADE_EVENT_SYSTEM // Thêm loại này cho các event hệ thống
};

struct TradeEventContext {
  TRADE_EVENT_TYPE eventType;
  string symbol;
  ulong magic;
  ulong ticket;
  double volume;
  double price;
  double sl;
  double tp;
  string comment;
  datetime eventTime;

  string ToString() const {
    return StringFormat("EventType: %d, Symbol: %s, Magic: %I64u, Ticket: %I64u, Volume: %.2f, "
                        "Price: %.5f, SL: %.5f, TP: %.5f, Comment: %s, EventTime: %s",
                        eventType, symbol, magic, ticket, volume, price, sl, tp, comment,
                        TimeToString(eventTime, TIME_DATE | TIME_SECONDS));
  }
};

class ITradeEventHandler {
public:
  virtual ~ITradeEventHandler() {}

  // Method chính - được gọi khi có sự kiện trade
  virtual void OnTradeEvent(const TradeEventContext &context) = 0;

  // Optional: filter theo loại event
  virtual bool ShouldHandle(TRADE_EVENT_TYPE eventType) { return true; }
};

#endif