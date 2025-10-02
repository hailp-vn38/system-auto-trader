
/**
 * @brief Interface for trailing stop management.
 * This interface defines methods for managing trailing stops on open positions.
 */
class ITrailing {
public:
  /**
   * @brief Checks if the trailing strategy is ready.
   * @return true if ready, false otherwise.
   */
  virtual bool IsReady() const = 0;

  /**
   * @brief Manages trailing stops for positions matching the symbol and magic.
   * @param sym The trading symbol.
   * @param tf The timeframe.
   * @param magic The magic number.
   * @return true if trailing was applied, false otherwise.
   */
  virtual bool Manage(const string sym, const ENUM_TIMEFRAMES tf, const long magic) = 0;
};
