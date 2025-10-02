//+------------------------------------------------------------------+
//| Sizer_RiskPercent.mqh - Risk percent sizer                       |
//| Calculates lot size based on percentage of account balance       |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/ports/ISizer.mqh>

//+------------------------------------------------------------------+
//| Risk percent sizer                                               |
//| Lot = (Balance × Risk%) / (Stop Points × Money Per Point)        |
//+------------------------------------------------------------------+
class Sizer_RiskPercent : public ISizer {
  private:
    double m_riskPercent; ///< Risk percentage (e.g., 2.0 for 2%)

  public:
    /**
     * @brief Constructor
     * @param riskPercent Risk percentage of account balance (e.g., 2.0 for 2%)
     */
    Sizer_RiskPercent(const double riskPercent = 1.0) : m_riskPercent(riskPercent) {}

    /**
     * @brief Calculate lot size based on risk percentage
     * @param sym Symbol name
     * @param stopPoints Stop loss distance in points
     * @param suggested Suggested lot (not used)
     * @param magic Magic number (not used)
     * @return Calculated lot size
     */
    virtual double
    Lots(const string sym, const int stopPoints, const double suggested, const long magic) {
        // Validate inputs
        if(stopPoints <= 0 || m_riskPercent <= 0.0) { return 0.0; }

        // Get account balance
        const double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        if(balance <= 0.0) { return 0.0; }

        // Calculate money value per point for 1.0 lot
        const double money_per_point_1lot = MoneyPerPoint1Lot(sym);
        if(money_per_point_1lot <= 0.0) { return 0.0; }

        // Calculate risk money from balance percentage
        const double risk_money = balance * (m_riskPercent / 100.0);

        // Formula: lot = risk_money / (stop_points × money_per_point_1lot)
        const double lot = risk_money / (stopPoints * money_per_point_1lot);

        return NormalizeLot(sym, lot);
    }

    // Setter/getter
    void SetRiskPercent(const double percent) { m_riskPercent = percent; }
    double GetRiskPercent() const { return m_riskPercent; }

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
