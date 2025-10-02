// Include/AutoTrader/domain/ports/IOrders.mqh

/**
 * @brief Structure containing information about an order.
 */
struct OrderInfo {
  ulong ticket;        /**< Order ticket number. */
  string symbol;       /**< Trading symbol. */
  long magic;          /**< Magic number. */
  long type;           /**< Order type (e.g., ORDER_TYPE_BUY_LIMIT). */
  double volume;       /**< Order volume in lots. */
  double price_open;   /**< Opening price. */
  double sl;           /**< Stop loss price. */
  double tp;           /**< Take profit price. */
  datetime time_setup; /**< Time when the order was set up. */
};

/**
 * @brief Interface for accessing order information.
 * This interface provides methods to query and retrieve details about pending orders.
 */
class IOrders {
public:
  /**
   * @brief Gets the total number of orders.
   * @return The total number of orders.
   */
  virtual int Total() = 0;

  /**
   * @brief Retrieves the most recent order for a symbol and magic number.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @param out Output parameter for the order information.
   * @return true if the order was found, false otherwise.
   */
  virtual bool Current(const string sym, const long magic, OrderInfo &out) = 0;

  /**
   * @brief Retrieves the oldest order for a symbol and magic number.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @param out Output parameter for the order information.
   * @return true if the order was found, false otherwise.
   */
  virtual bool FirstBySymbolMagic(const string sym, const long magic, OrderInfo &out) = 0;

  /**
   * @brief Counts the number of orders for a symbol and magic number.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @return The number of orders.
   */
  virtual int CountBySymbolMagic(const string sym, const long magic) = 0;

  /**
   * @brief Lists all orders for a symbol and magic number.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @param buffer Output array to store the order information.
   * @return The number of orders retrieved.
   */
  virtual int ListBySymbolMagic(const string sym, const long magic, OrderInfo &buffer[]) = 0;
};
