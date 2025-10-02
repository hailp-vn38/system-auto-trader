//+------------------------------------------------------------------+
//| Target_Percent.mqh - Percentage-based target implementation      |
//| Calculates SL/TP as percentage of entry price                    |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/enums/Enum.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ITargets.mqh>

//+------------------------------------------------------------------+
//| Percent-based target - SL/TP as % of entry price                 |
//+------------------------------------------------------------------+
class Target_Percent : public ITargets {
  private:
    IMarketData *m_md;
    double m_slPercent; ///< Stop loss percentage (e.g., 2.0 = 2%)
    double m_tpPercent; ///< Take profit percentage (e.g., 4.0 = 4%)

    //+------------------------------------------------------------------+
    //| Snap price to tick size                                          |
    //+------------------------------------------------------------------+
    double SnapToTick(const string sym, const double price) const {
        if(!m_md) return price;
        const double tick = m_md.TickSize(sym);
        if(tick <= 0) return price;
        const double steps = MathRound(price / tick);
        return steps * tick;
    }

  public:
    /**
     * @brief Constructor
     * @param md Market data interface
     * @param slPercent Stop loss percentage (e.g., 2.0 for 2%)
     * @param tpPercent Take profit percentage (e.g., 4.0 for 4%)
     */
    Target_Percent(IMarketData *md, const double slPercent = 0.0, const double tpPercent = 0.0)
        : m_md(md), m_slPercent(slPercent), m_tpPercent(tpPercent) {}

    /**
     * @brief Compute SL/TP based on percentage of entry
     */
    virtual bool Compute(const string sym, const bool isSell, const double entry,
                         const double sl_in, double &sl_out, double &tp_out) override {
        if(entry <= 0) return false;

        // Calculate SL
        if(m_slPercent > 0) {
            const double sl_diff = entry * (m_slPercent / 100.0);
            sl_out               = isSell ? (entry + sl_diff) : (entry - sl_diff);
            sl_out               = SnapToTick(sym, sl_out);
        } else if(sl_in > 0) {
            sl_out = SnapToTick(sym, sl_in); // Use input SL
        }

        // Calculate TP
        if(m_tpPercent > 0) {
            const double tp_diff = entry * (m_tpPercent / 100.0);
            tp_out               = isSell ? (entry - tp_diff) : (entry + tp_diff);
            tp_out               = SnapToTick(sym, tp_out);
        }

        return (sl_out > 0 || tp_out > 0);
    }

    // Setters
    void SetSLPercent(const double percent) { m_slPercent = percent; }
    void SetTPPercent(const double percent) { m_tpPercent = percent; }
};
