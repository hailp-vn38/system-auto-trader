//+------------------------------------------------------------------+
//| Sizer_FixedLot.mqh - Fixed lot size sizer                        |
//| Returns a constant lot size regardless of stop loss distance     |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/ports/ISizer.mqh>

//+------------------------------------------------------------------+
//| Fixed lot sizer - always returns the same lot size               |
//+------------------------------------------------------------------+
class Sizer_FixedLot : public ISizer {
  private:
    double m_fixedLot;

  public:
    Sizer_FixedLot(const double lot = 0.10) : m_fixedLot(lot) {}

    virtual double
    Lots(const string sym, const int stopPoints, const double suggested, const long magic) {
        // Normalize to broker's lot constraints
        return NormalizeLot(sym, m_fixedLot);
    }

    // Setter/getter
    void SetLot(const double lot) { m_fixedLot = lot; }
    double GetLot() const { return m_fixedLot; }

  private:
    //+------------------------------------------------------------------+
    //| Normalize lot to broker constraints                              |
    //+------------------------------------------------------------------+
    double NormalizeLot(const string symbol, double lot) const {
        const double vol_min  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
        const double vol_max  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
        const double vol_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

        if(vol_step <= 0.0) return 0.0;

        // Snap to step (floor)
        lot = MathFloor(lot / vol_step) * vol_step;

        // Clamp to broker limits
        if(lot < vol_min) lot = vol_min;
        if(lot > vol_max) lot = vol_max;

        return lot;
    }
};
