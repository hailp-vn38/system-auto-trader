//+------------------------------------------------------------------+
//| Sizer_MultiMode.mqh - Multi-mode sizer wrapper                   |
//| Delegates to appropriate sizer based on mode selection           |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/enums/Enum.mqh>
#include <AutoTrader/domain/ports/ISizer.mqh>
#include <AutoTrader/sizers/Sizer_FixedLot.mqh>
#include <AutoTrader/sizers/Sizer_FixedMoney.mqh>
#include <AutoTrader/sizers/Sizer_RiskPercent.mqh>

//+------------------------------------------------------------------+
//| Multi-mode sizer - wrapper for backward compatibility            |
//| Delegates to specific sizer implementation based on mode         |
//+------------------------------------------------------------------+
class Sizer_MultiMode : public ISizer {
  private:
    ISizer *m_activeSizer; ///< Active sizer instance
    ENUM_LOT_CALC_MODE m_mode;
    double m_value;

    // Internal sizer instances
    Sizer_FixedLot *m_fixedLotSizer;
    Sizer_FixedMoney *m_fixedMoneySizer;
    Sizer_RiskPercent *m_riskPercentSizer;

  public:
    /**
     * @brief Constructor
     * @param value Value for sizing (lot | money | percent)
     * @param mode Calculation mode
     */
    Sizer_MultiMode(const double value = 0.01, const ENUM_LOT_CALC_MODE mode = CALC_MODE_FIXED)
        : m_activeSizer(NULL), m_mode(mode), m_value(value), m_fixedLotSizer(NULL),
          m_fixedMoneySizer(NULL), m_riskPercentSizer(NULL) {
        UpdateMode(value, mode);
    }

    ~Sizer_MultiMode() {
        if(m_fixedLotSizer != NULL) delete m_fixedLotSizer;
        if(m_fixedMoneySizer != NULL) delete m_fixedMoneySizer;
        if(m_riskPercentSizer != NULL) delete m_riskPercentSizer;
    }

    /**
     * @brief Calculate lot size using active sizer
     */
    virtual double
    Lots(const string sym, const int stopPoints, const double suggested, const long magic) {
        if(m_activeSizer == NULL) return 0.0;
        return m_activeSizer.Lots(sym, stopPoints, suggested, magic);
    }

    /**
     * @brief Update sizing mode and value
     */
    void UpdateMode(const double value, const ENUM_LOT_CALC_MODE mode) {
        m_value = value;
        m_mode  = mode;

        // Clean up old sizers
        if(m_fixedLotSizer != NULL) {
            delete m_fixedLotSizer;
            m_fixedLotSizer = NULL;
        }
        if(m_fixedMoneySizer != NULL) {
            delete m_fixedMoneySizer;
            m_fixedMoneySizer = NULL;
        }
        if(m_riskPercentSizer != NULL) {
            delete m_riskPercentSizer;
            m_riskPercentSizer = NULL;
        }

        // Create appropriate sizer
        switch(mode) {
        case CALC_MODE_FIXED:
            m_fixedLotSizer = new Sizer_FixedLot(value);
            m_activeSizer   = m_fixedLotSizer;
            break;

        case CALC_MODE_FIXED_MONEY:
            m_fixedMoneySizer = new Sizer_FixedMoney(value);
            m_activeSizer     = m_fixedMoneySizer;
            break;

        case CALC_MODE_RISK_PERCENT:
            m_riskPercentSizer = new Sizer_RiskPercent(value);
            m_activeSizer      = m_riskPercentSizer;
            break;

        default:
            m_fixedLotSizer = new Sizer_FixedLot(value);
            m_activeSizer   = m_fixedLotSizer;
            break;
        }
    }

    // Getters
    ENUM_LOT_CALC_MODE GetMode() const { return m_mode; }
    double GetValue() const { return m_value; }
};
