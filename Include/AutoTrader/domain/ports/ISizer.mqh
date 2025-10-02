
/**
 * @brief Interface for position sizing calculations.
 * This interface defines methods to calculate the appropriate lot size for trades.
 */
class ISizer {
public:
  /**
   * @brief Calculates the lot size for a trade.
   * @param sym The trading symbol.
   * @param stopPoints The stop loss in points.
   * @param suggested Suggested lot size (may be ignored or adjusted).
   * @param magic The magic number.
   * @return The calculated lot size.
   */
  virtual double Lots(const string sym, const int stopPoints, const double suggested,
                      const long magic) = 0;
};
