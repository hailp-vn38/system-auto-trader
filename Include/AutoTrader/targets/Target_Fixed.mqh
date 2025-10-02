//+------------------------------------------------------------------+
//| Target_Fixed.mqh - Fixed lot target implementation               |
//| Calculates SL/TP based on fixed lot strategy                     |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/enums/Enum.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ITargets.mqh>

//+------------------------------------------------------------------+
//| Fixed lot target - always returns the same SL/TP values          |
//+------------------------------------------------------------------+
class Target_Fixed : public ITargets {
  private:
    IMarketData *m_md;
    double m_slPoints; ///< Stop loss in points
    double m_tpPoints; ///< Take profit in points

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
     * @param slPoints Stop loss in points
     * @param tpPoints Take profit in points
     */
    Target_Fixed(IMarketData *md, const double slPoints, const double tpPoints)
        : m_md(md), m_slPoints(slPoints), m_tpPoints(tpPoints) {}

    /**
     * @brief Compute SL/TP based on fixed points
     */
    virtual bool Compute(const string sym, const bool isSell, const double entry,
                         const double sl_in, double &sl_out, double &tp_out) override {
        const double point = m_md ? m_md.Point(sym) : 0.0;
        if(point <= 0) return false;

        // Calculate SL/TP
        if(m_slPoints > 0) {
            const double sl_diff = m_slPoints * point;
            sl_out               = isSell ? (entry + sl_diff) : (entry - sl_diff);
            sl_out               = SnapToTick(sym, sl_out);
        }

        if(m_tpPoints > 0) {
            const double tp_diff = m_tpPoints * point;
            tp_out               = isSell ? (entry - tp_diff) : (entry + tp_diff);
            tp_out               = SnapToTick(sym, tp_out);
        }

        return (sl_out > 0 || tp_out > 0);
    }

    // Setters
    void SetSL(const double slPoints) { m_slPoints = slPoints; }
    void SetTP(const double tpPoints) { m_tpPoints = tpPoints; }
};
