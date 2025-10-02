//+------------------------------------------------------------------+
//| Include/AutoTrader/domain/ports/IMarketData.mqh (updated)        |
//+------------------------------------------------------------------+

/**
 * @brief Interface for market data access.
 * This interface provides methods to retrieve real-time prices, symbol properties,
 * and historical OHLC data.
 */
class IMarketData {
public:
  /**
   * @brief Retrieves the last bid and ask prices for a symbol.
   * @param sym The trading symbol.
   * @param bid Output parameter for the bid price.
   * @param ask Output parameter for the ask price.
   * @return true if prices were retrieved successfully, false otherwise.
   */
  virtual bool LastBidAsk(const string sym, double &bid, double &ask) = 0;

  /**
   * @brief Gets the point value for a symbol.
   * @param sym The trading symbol.
   * @return The point value.
   */
  virtual double Point(const string sym) = 0;

  /**
   * @brief Gets the tick size for a symbol.
   * @param sym The trading symbol.
   * @return The tick size.
   */
  virtual double TickSize(const string sym) = 0;

  /**
   * @brief Retrieves OHLC data for a specific candle.
   * @param sym The trading symbol.
   * @param tf The timeframe.
   * @param shift The shift from the current candle (0 = current, 1 = previous, etc.).
   * @param o Output parameter for open price.
   * @param h Output parameter for high price.
   * @param l Output parameter for low price.
   * @param c Output parameter for close price.
   * @return true if data was retrieved successfully, false otherwise.
   */
  virtual bool OHLC(const string sym, ENUM_TIMEFRAMES tf, int shift, double &o, double &h,
                    double &l, double &c) = 0;
};
