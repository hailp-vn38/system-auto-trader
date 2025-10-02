
/**
 * @brief Interface for risk management.
 * This interface defines methods to check if a trade is allowed based on risk criteria.
 */
class IRisk {
public:
  /**
   * @brief Checks if a trade is allowed for a symbol and magic number.
   * @param sym The trading symbol.
   * @param magic The magic number.
   * @return true if the trade is allowed, false otherwise.
   */
  virtual bool AllowTrade(const string sym, const long magic) = 0;
};
