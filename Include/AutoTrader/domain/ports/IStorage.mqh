// Include/AutoTrader/domain/ports/IStorage.mqh

/**
 * @brief Interface for data storage operations.
 * This interface defines methods for saving trade and order data,
 * including openings, closings, modifications, and cancellations.
 */
class IStorage {
public:
  // ==== Trades (đã có từ trước) ====================================
  /**
   * @brief Saves information when a trade position is opened.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @param ticket The position ticket.
   * @param order_type The order type.
   * @param volume The volume in lots.
   * @param price The opening price.
   * @param sl The stop loss price.
   * @param tp The take profit price.
   * @param ts The timestamp.
   */
  virtual void SaveTradeOpen(const string sym, long magic, ulong ticket, ENUM_ORDER_TYPE order_type,
                             double volume, double price, double sl, double tp, datetime ts)
                                          = 0;

  /**
   * @brief Saves information when a trade position is closed.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @param ticket The position ticket.
   * @param close_price The closing price.
   * @param profit The profit/loss.
   * @param ts The timestamp.
   * @param reason The reason for closing.
   */
  virtual void SaveTradeClose(const string sym, long magic, ulong ticket, double close_price,
                              double profit, datetime ts, const string reason)
                                          = 0;

  /**
   * @brief Saves information when a position's stop loss is trailed.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @param ticket The position ticket.
   * @param new_sl The new stop loss price.
   * @param ts The timestamp.
   */
  virtual void SaveTrailing(const string sym, long magic, ulong ticket, double new_sl, datetime ts)
                                          = 0;

  /**
   * @brief Saves information for partial position closures (optional).
   * Default implementation does nothing.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @param ticket The position ticket.
   * @param closed_volume The volume closed.
   * @param price The closing price.
   * @param profit The profit from the closure.
   * @param ts The timestamp.
   */
  virtual void SavePartialClose(const string sym, long magic, ulong ticket, double closed_volume,
                                double price, double profit, datetime ts) { /* default no-op */ }

  // ==== Orders (MỚI) ===============================================
  /**
   * @brief Saves information when a pending order is placed.
   * Default implementation does nothing.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @param order_ticket The order ticket.
   * @param order_type The order type.
   * @param volume The volume in lots.
   * @param price The order price.
   * @param sl The stop loss price.
   * @param tp The take profit price.
   * @param ts The timestamp.
   */
  virtual void SaveOrderOpen(const string sym, long magic, ulong order_ticket,
                             ENUM_ORDER_TYPE order_type, double volume, double price, double sl,
                             double tp, datetime ts) { /* default no-op */ }

  /**
   * @brief Saves information when a pending order is modified.
   * Default implementation does nothing.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @param order_ticket The order ticket.
   * @param new_price The new order price.
   * @param new_sl The new stop loss price.
   * @param new_tp The new take profit price.
   * @param ts The timestamp.
   */
  virtual void SaveOrderModify(const string sym, long magic, ulong order_ticket, double new_price,
                               double new_sl, double new_tp, datetime ts) { /* default no-op */ }

  /**
   * @brief Saves information when a pending order is canceled.
   * Default implementation does nothing.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @param order_ticket The order ticket.
   * @param reason The reason for cancellation.
   * @param ts The timestamp.
   */
  virtual void SaveOrderCancel(const string sym, long magic, ulong order_ticket,
                               const string reason, datetime ts) { /* default no-op */ }

  /**
   * @brief Saves information when a pending order is filled.
   * Default implementation does nothing.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @param order_ticket The order ticket.
   * @param position_ticket The resulting position ticket.
   * @param fill_price The fill price.
   * @param volume The filled volume.
   * @param ts The timestamp.
   */
  virtual void
  SaveOrderFilled(const string sym, long magic, ulong order_ticket, ulong position_ticket,
                  double fill_price, double volume, datetime ts) { /* default no-op */ }

  // ==== Flush =======================================================
  /**
   * @brief Flushes any buffered data to storage.
   */
  virtual void Flush() = 0;
};
