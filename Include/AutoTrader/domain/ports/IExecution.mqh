// Include/AutoTrader/domain/ports/IExecution.mqh

#include <AutoTrader/domain/enums/Enum.mqh>

/**
 * @brief Interface for trade execution operations.
 * This interface defines methods for opening, modifying, and closing trades,
 * as well as managing pending orders.
 */
class IExecution {
public:
  // Common
  /**
   * @brief Opens a new trade position or pending order.
   * @param sym The trading symbol (e.g., "EURUSD").
   * @param magic The magic number for identifying the trade.
   * @param type The trade type (buy or sell).
   * @param volume The volume of the trade in lots.
   * @param price The price at which to open the trade (for pending orders).
   * @param sl The stop loss price.
   * @param tp The take profit price.
   * @param deviation_points The maximum price deviation in points.
   * @param ticket_out Output parameter for the ticket of the opened trade.
   * @param comment Optional comment for the trade.
   * @param type_time The order expiration type (default: GTC).
   * @param expiration The expiration time for pending orders (default: 0).
   * @return true if the trade was opened successfully, false otherwise.
   */
  virtual bool
  OpenTrade(const string sym, long magic, const ENUM_TRADE_TYPE type, double volume, double price,
            double sl, double tp, int deviation_points, ulong &ticket_out,
            const string comment = "", ENUM_ORDER_TYPE_TIME type_time = ORDER_TIME_GTC,
            datetime expiration = 0) = 0;

  /**
   * @brief Modifies the stop loss and take profit of an existing position by ticket.
   * @param ticket The ticket of the position to modify.
   * @param sl The new stop loss price.
   * @param tp The new take profit price.
   * @return true if the modification was successful, false otherwise.
   */
  virtual bool ModifyPositionByTicket(const ulong ticket, const double sl, const double tp) = 0;

  /**
   * @brief Closes multiple positions by their tickets.
   * @param tickets Array of position tickets to close.
   * @return The number of positions successfully closed.
   */
  virtual int ClosePositionsByTickets(const ulong &tickets[]) = 0;

  /**
   * @brief Closes all positions for a specific symbol and magic number.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @return The number of positions closed.
   */
  virtual int CloseAllBySymbolMagic(const string sym, long magic) = 0;

  // Modify/Delete pending
  /**
   * @brief Modifies a pending order.
   * @param order_ticket The ticket of the pending order to modify.
   * @param price The new price for the pending order.
   * @param sl The new stop loss price.
   * @param tp The new take profit price.
   * @return true if the modification was successful, false otherwise.
   */
  virtual bool ModifyPending(ulong order_ticket, double price, double sl, double tp) = 0;

  /**
   * @brief Deletes a pending order.
   * @param order_ticket The ticket of the pending order to delete.
   * @return true if the deletion was successful, false otherwise.
   */
  virtual bool DeletePending(ulong order_ticket) = 0;

  /**
   * @brief Deletes all pending orders for a specific symbol and magic number.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @return The number of pending orders deleted.
   */
  virtual int DeleteAllPendings(const string sym, long magic) = 0;
};
