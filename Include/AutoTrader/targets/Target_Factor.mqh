//+------------------------------------------------------------------+
//| Target_Factor.mqh - Risk/Reward factor target implementation     |
//| Calculates TP based on R:R ratio (e.g., 2R, 3R)                  |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/enums/Enum.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ITargets.mqh>

//+------------------------------------------------------------------+
//| Factor-based target - TP = SL distance × factor                  |
//+------------------------------------------------------------------+
class Target_Factor : public ITargets {
  private:
    IMarketData *m_md;
    double m_tpFactor; ///< Risk/Reward factor (e.g., 2.0 = 2R)
    double m_slFactor; ///< SL adjustment factor (default 1.0 = no change)

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
     * @param tpFactor Take profit factor (R:R ratio, e.g., 2.0 for 2R)
     * @param slFactor Stop loss adjustment factor (default 1.0)
     */
    Target_Factor(IMarketData *md, const double tpFactor = 2.0, const double slFactor = 1.0)
        : m_md(md), m_tpFactor(tpFactor), m_slFactor(slFactor) {}

    /**
     * @brief Compute SL/TP based on R:R factor
     */
    virtual bool Compute(const string sym, const bool isSell, const double entry,
                         const double sl_in, double &sl_out, double &tp_out) override {
        if(sl_in <= 0) return false;

        // Calculate risk distance
        const double risk_dist = MathAbs(entry - sl_in);
        if(risk_dist <= 0) return false;

        // Adjust SL if needed
        if(m_slFactor != 1.0) {
            const double sl_diff = risk_dist * m_slFactor;
            sl_out               = isSell ? (entry + sl_diff) : (entry - sl_diff);
            sl_out               = SnapToTick(sym, sl_out);
        } else {
            sl_out = SnapToTick(sym, sl_in);
        }

        // Calculate TP based on factor
        if(m_tpFactor > 0) {
            const double tp_diff = risk_dist * m_tpFactor;
            tp_out               = isSell ? (entry - tp_diff) : (entry + tp_diff);
            tp_out               = SnapToTick(sym, tp_out);
        }

        return (sl_out > 0 || tp_out > 0);
    }

    // Setters
    void SetTPFactor(const double factor) { m_tpFactor = factor; }
    void SetSLFactor(const double factor) { m_slFactor = factor; }
};
