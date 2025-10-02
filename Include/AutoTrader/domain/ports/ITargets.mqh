//+------------------------------------------------------------------+
//| ITargets.mqh - Port for computing SL/TP targets (system core)    |
//+------------------------------------------------------------------+

/**
 * @brief Interface for computing stop loss and take profit targets.
 * This interface defines methods to calculate final SL/TP prices based on trade parameters.
 */
class ITargets {
public:
  /**
   * @brief Computes the final stop loss and take profit prices.
   * @param sym The trading symbol.
   * @param isSell true if the trade is a sell, false for buy.
   * @param entry The entry price.
   * @param sl_in The input stop loss price (may be adjusted).
   * @param sl_out Output parameter for the computed stop loss price.
   * @param tp_out Output parameter for the computed take profit price.
   * @return true if outputs are set, false to keep caller defaults.
   */
  virtual bool
  Compute(const string sym, const bool isSell, const double entry, const double sl_in,
          double &sl_out, double &tp_out) = 0;
};