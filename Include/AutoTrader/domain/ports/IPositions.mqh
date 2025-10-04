//+------------------------------------------------------------------+
//| Include/AutoTrader/domain/ports/IPositions.mqh                   |
//+------------------------------------------------------------------+

/**
 * @brief Enumeration for position sides.
 */
enum ENUM_POS_SIDE { POS_SIDE_BUY = POSITION_TYPE_BUY, POS_SIDE_SELL = POSITION_TYPE_SELL };

/**
 * @brief Structure containing detailed information about a position.
 */
struct PositionInfo {
    // --- string props ---
    string symbol;      /**< Trading symbol. */
    ulong magic;        /**< Magic number. */
    string comment;     /**< Position comment. */
    string external_id; /**< External ID. */

    // --- integer/datetime props ---
    ulong ticket;    /**< Position ticket. */
    long identifier; /**< Identifier of the order that opened the position. */

    long type;   /**< Position type (buy or sell). */
    long reason; /**< Reason for opening the position. */

    datetime time;        /**< Time when the position was opened. */
    long time_msc;        /**< Time in milliseconds. */
    datetime time_update; /**< Last update time. */
    long time_update_msc; /**< Last update time in milliseconds. */

    // --- double props ---
    double volume;        /**< Position volume in lots. */
    double price_open;    /**< Opening price. */
    double price_current; /**< Current price. */
    double sl;            /**< Stop loss price. */
    double tp;            /**< Take profit price. */
    double swap;          /**< Swap value. */
    double profit;        /**< Current profit. */

    // tiện ích
    /**
     * @brief Checks if the position is a sell position.
     * @return true if sell, false otherwise.
     */
    bool IsSell() const { return (type == POSITION_TYPE_SELL); }

    /**
     * @brief Checks if the position is a buy position.
     * @return true if buy, false otherwise.
     */
    bool IsBuy() const { return (type == POSITION_TYPE_BUY); }
};

/**
 * @brief Interface for accessing position information.
 * This interface provides methods to query and retrieve details about open positions.
 */
class IPositions {
  public:
    /**
     * @brief Gets the total number of open positions.
     * @return The total number of positions.
     */
    virtual int Total() = 0;

    /**
     * @brief Retrieves the most recent position for a symbol and magic number.
     * @param sym The trading symbol.
     * @param magic The magic number.
     * @param out Output parameter for the position information.
     * @return true if the position was found, false otherwise.
     */
    virtual bool Current(const string sym, const long magic, PositionInfo &out) = 0;

    /**
     * @brief Retrieves the oldest position for a symbol and magic number.
     * @param sym The trading symbol.
     * @param magic The magic number.
     * @param out Output parameter for the position information.
     * @return true if the position was found, false otherwise.
     */
    virtual bool FirstBySymbolMagic(const string sym, const long magic, PositionInfo &out) = 0;

    /**
     * @brief Counts the number of positions for a symbol and magic number.
     * @param sym The trading symbol.
     * @param magic The magic number.
     * @return The number of positions.
     */
    virtual int CountBySymbolMagic(const string sym, const long magic) = 0;

    /**
     * @brief Lists all positions for a symbol and magic number.
     * @param sym The trading symbol.
     * @param magic The magic number.
     * @param buffer Output array to store the position information.
     * @return The number of positions retrieved.
     */
    virtual int ListBySymbolMagic(const string sym, const long magic, PositionInfo &buffer[]) = 0;

    //+------------------------------------------------------------------+
    //| Kiểm tra xem có positions nào đang mở không                       |
    //| @param magic   Magic number để lọc positions                      |
    //| @param symbol  Symbol để lọc positions                            |
    //| @return       true nếu có ít nhất 1 position đang mở             |
    //+------------------------------------------------------------------+
    virtual bool HasOpenPositions(const string symbol, const ulong magic) = 0;
};
//+------------------------------------------------------------------+
