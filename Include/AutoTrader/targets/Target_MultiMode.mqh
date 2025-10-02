//+------------------------------------------------------------------+
//| Target_MultiMode.mqh - Multi-mode target wrapper                 |
//| Delegates to specific target implementation based on mode        |
//| Backward compatible with MultisTargetMode                        |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/enums/Enum.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ITargets.mqh>

//+------------------------------------------------------------------+
//| Multi-mode target implementation                                 |
//+------------------------------------------------------------------+
class Target_MultiMode : public ITargets {
  private:
    IMarketData *m_md;
    double m_targetValue;
    ENUM_TARGET_CALC_MODE m_targetMode;
    double m_stopValue;
    ENUM_TARGET_CALC_MODE m_stopMode;

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

    //+------------------------------------------------------------------+
    //| Calculate target based on mode                                   |
    //+------------------------------------------------------------------+
    double CalculateTarget(const string sym, const double entry, const double sl_price,
                           const bool isSell) const {
        switch(m_targetMode) {
        case CALC_MODE_OFF:
        case CALC_MODE_DEFAULT: return 0.0;

        case CALC_MODE_FACTOR: {
            const double diff = MathAbs(entry - sl_price) * m_targetValue;
            return isSell ? (entry - diff) : (entry + diff);
        }

        case CALC_MODE_PERCENT: {
            const double diff = entry * (m_targetValue / 100.0);
            return isSell ? (entry - diff) : (entry + diff);
        }

        case CALC_MODE_POINTS: {
            const double point = m_md ? m_md.Point(sym) : 0.0;
            if(point <= 0) return 0.0;
            const double diff = m_targetValue * point;
            return isSell ? (entry - diff) : (entry + diff);
        }

        default: return 0.0;
        }
    }

    //+------------------------------------------------------------------+
    //| Calculate stop loss based on mode                                |
    //+------------------------------------------------------------------+
    double CalculateStop(const string sym, const double entry, const double sl_price,
                         const bool isSell) const {
        switch(m_stopMode) {
        case CALC_MODE_OFF: return 0.0; // No SL

        case CALC_MODE_DEFAULT: return sl_price; // Use input SL

        case CALC_MODE_FACTOR: {
            const double diff = MathAbs(entry - sl_price) * m_stopValue;
            return isSell ? (entry + diff) : (entry - diff);
        }

        case CALC_MODE_PERCENT: {
            const double diff = entry * (m_stopValue / 100.0);
            return isSell ? (entry + diff) : (entry - diff);
        }

        case CALC_MODE_POINTS: {
            const double point = m_md ? m_md.Point(sym) : 0.0;
            if(point <= 0) return sl_price;
            const double diff = m_stopValue * point;
            return isSell ? (entry + diff) : (entry - diff);
        }

        default: return sl_price;
        }
    }

  public:
    /**
     * @brief Constructor
     * @param md Market data interface
     * @param targetValue Target value (meaning depends on mode)
     * @param targetMode Target calculation mode
     * @param stopValue Stop loss value (meaning depends on mode)
     * @param stopMode Stop loss calculation mode
     */
    Target_MultiMode(IMarketData *md, const double targetValue,
                     const ENUM_TARGET_CALC_MODE targetMode, const double stopValue,
                     const ENUM_TARGET_CALC_MODE stopMode)
        : m_md(md), m_targetValue(targetValue), m_targetMode(targetMode), m_stopValue(stopValue),
          m_stopMode(stopMode) {}

    /**
     * @brief Compute SL/TP based on selected modes
     */
    virtual bool Compute(const string sym, const bool isSell, const double entry,
                         const double sl_in, double &sl_out, double &tp_out) override {
        // Calculate SL
        if(m_stopMode == CALC_MODE_DEFAULT) {
            sl_out = (sl_out > 0) ? sl_out : sl_in; // Keep existing or use input
        } else {
            sl_out = CalculateStop(sym, entry, sl_in, isSell);
        }

        // Calculate TP
        if(m_targetMode == CALC_MODE_DEFAULT) {
            // Keep existing tp_out (may be 0)
        } else {
            tp_out = CalculateTarget(sym, entry, sl_in, isSell);
        }

        // Normalize to tick size
        if(sl_out > 0) sl_out = SnapToTick(sym, sl_out);
        if(tp_out > 0) tp_out = SnapToTick(sym, tp_out);

        return (sl_out > 0 || tp_out > 0);
    }

    // Setters for runtime configuration
    void SetTargetMode(const ENUM_TARGET_CALC_MODE mode, const double value) {
        m_targetMode  = mode;
        m_targetValue = value;
    }

    void SetStopMode(const ENUM_TARGET_CALC_MODE mode, const double value) {
        m_stopMode  = mode;
        m_stopValue = value;
    }
};
