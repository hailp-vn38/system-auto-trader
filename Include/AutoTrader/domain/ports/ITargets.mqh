//+------------------------------------------------------------------+
//| ITargets.mqh - Port for computing SL/TP targets (system core)    |
//+------------------------------------------------------------------+
class ITargets {
public:
  // Compute final SL/TP prices.
  // Return true if outputs are set; false to keep caller defaults.
  virtual bool Compute(const string sym, const bool isSell,
                       const double entry, const double sl_in,
                       double &sl_out, double &tp_out) = 0;
};