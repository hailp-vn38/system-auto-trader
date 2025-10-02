//+------------------------------------------------------------------+
//| Sizer_FixedMoney.mqh - Fixed money risk sizer                    |
//| Calculates lot size based on fixed money amount at risk          |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/ports/ISizer.mqh>

//+------------------------------------------------------------------+
//| Fixed money risk sizer                                           |
//| Lot size = Risk Money / (Stop Points × Money Per Point Per Lot)  |
//+------------------------------------------------------------------+
class Sizer_FixedMoney : public ISizer {
  private:
    double m_riskMoney; ///< Fixed money amount to risk (e.g., $100)

  public:
    /**
     * @brief Constructor
     * @param riskMoney Fixed money amount to risk (e.g., 100.0 for $100)
     */
    Sizer_FixedMoney(const double riskMoney = 100.0) : m_riskMoney(riskMoney) {}

    /**
     * @brief Calculate lot size based on fixed money risk
     * @param sym Symbol name
     * @param stopPoints Stop loss distance in points
     * @param suggested Suggested lot (not used)
     * @param magic Magic number (not used)
     * @return Calculated lot size
     */
    virtual double
    Lots(const string sym, const int stopPoints, const double suggested, const long magic) {
        // Validate inputs
        if(stopPoints <= 0 || m_riskMoney <= 0.0) { return 0.0; }

        // Calculate money value per point for 1.0 lot
        const double money_per_point_1lot = MoneyPerPoint1Lot(sym);
        if(money_per_point_1lot <= 0.0) { return 0.0; }

        // Formula: lot = risk_money / (stop_points × money_per_point_1lot)
        const double lot = m_riskMoney / (stopPoints * money_per_point_1lot);

        return NormalizeLot(sym, lot);
    }

    // Setter/getter
    void SetRiskMoney(const double money) { m_riskMoney = money; }
    double GetRiskMoney() const { return m_riskMoney; }

  private:
    //+------------------------------------------------------------------+
    //| Calculate money value per point for 1.0 lot                      |
    //+------------------------------------------------------------------+
    double MoneyPerPoint1Lot(const string symbol) const {
        const double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        const double tick_size  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
        const double point      = SymbolInfoDouble(symbol, SYMBOL_POINT);

        if(tick_value <= 0.0 || tick_size <= 0.0 || point <= 0.0) { return 0.0; }

        // Convert tick value to point value
        // money_per_point = tick_value × (point / tick_size)
        return tick_value * (point / tick_size);
    }

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
