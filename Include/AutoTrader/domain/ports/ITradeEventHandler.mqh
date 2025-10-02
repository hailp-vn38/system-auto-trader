// domain/ports/ITradeEventHandler.mqh
#ifndef ITRADE_EVENT_HANDLER_MQH
#define ITRADE_EVENT_HANDLER_MQH

/**
 * @brief Enumeration of trade event types.
 */
enum TRADE_EVENT_TYPE {
  TRADE_EVENT_OPEN,          /**< Position opened. */
  TRADE_EVENT_CLOSE,         /**< Position closed. */
  TRADE_EVENT_MODIFY,        /**< Position modified. */
  TRADE_EVENT_PARTIAL_CLOSE, /**< Partial position closure. */
  TRADE_EVENT_TRAILING,      /**< Trailing stop adjusted. */
  TRADE_EVENT_ORDER_PLACED,  /**< Pending order placed. */
  TRADE_EVENT_ORDER_FILLED,  /**< Pending order filled. */
  TRADE_EVENT_ORDER_CANCEL,  /**< Pending order canceled. */
  TRADE_EVENT_SYSTEM         /**< System event. */
};

/**
 * @brief Structure containing context information for a trade event.
 */
struct TradeEventContext {
  TRADE_EVENT_TYPE eventType; /**< The type of the trade event. */
  string symbol;              /**< Trading symbol. */
  ulong magic;                /**< Magic number. */
  ulong ticket;               /**< Ticket number. */
  double volume;              /**< Volume in lots. */
  double price;               /**< Price associated with the event. */
  double sl;                  /**< Stop loss price. */
  double tp;                  /**< Take profit price. */
  string comment;             /**< Comment. */
  datetime eventTime;         /**< Time of the event. */

  /**
   * @brief Converts the context to a string representation.
   * @return A formatted string describing the event context.
   */
  string ToString() const {
    return StringFormat("EventType: %d, Symbol: %s, Magic: %I64u, Ticket: %I64u, Volume: %.2f, "
                        "Price: %.5f, SL: %.5f, TP: %.5f, Comment: %s, EventTime: %s",
                        eventType, symbol, magic, ticket, volume, price, sl, tp, comment,
                        TimeToString(eventTime, TIME_DATE | TIME_SECONDS));
  }
};

/**
 * @brief Interface for handling trade events.
 * This interface defines methods for processing various trade-related events.
 */
class ITradeEventHandler {
public:
  virtual ~ITradeEventHandler() {}

  /**
   * @brief Called when a trade event occurs.
   * @param context The context of the trade event.
   */
  virtual void OnTradeEvent(const TradeEventContext &context) = 0;

  /**
   * @brief Optionally filters events by type.
   * @param eventType The type of event.
   * @return true if the event should be handled, false otherwise (default: true).
   */
  virtual bool ShouldHandle(TRADE_EVENT_TYPE eventType) { return true; }
};

#endif