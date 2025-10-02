//+------------------------------------------------------------------+
//| Include/AutoTrader/strategies/Strat_SwingStructure.mqh           |
//| Multi-level swing structure analysis strategy                    |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/entities/TradeSignal.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ISignal.mqh>
#include <AutoTrader/domain/ports/ITelemetry.mqh>
#include <AutoTrader/strategies/swing/SwingTypes.mqh>

//+------------------------------------------------------------------+
//| @brief Multi-level swing structure analysis strategy             |
//| @details Identifies market structure across multiple levels      |
//|          using ATR-based swing detection                         |
//+------------------------------------------------------------------+
class Strat_SwingStructure : public ISignal {
  private:
    IMarketData *m_md;       ///< Market data interface
    ITelemetry *m_telemetry; ///< Logging interface (optional)

    string m_symbol;      ///< Trading symbol
    ENUM_TIMEFRAMES m_tf; ///< Timeframe

    int m_atrHandle;        ///< ATR indicator handle
    int m_atrPeriod;        ///< ATR period
    double m_atrMultiplier; ///< ATR multiplier for threshold

    int m_levels;      ///< Number of structure levels
    int m_signalLevel; ///< Level to generate trading signals from

    // State tracking for base swing detection
    double m_highMax;       ///< Current maximum high
    datetime m_highMaxTime; ///< Timestamp of maximum high
    double m_lowMin;        ///< Current minimum low
    datetime m_lowMinTime;  ///< Timestamp of minimum low
    bool m_moveUp;          ///< Current market direction flag

    LevelExtremes m_levelExtremes[]; ///< Extremes organized by level

    //+------------------------------------------------------------------+
    //| Helper: Price comparison based on extreme type                  |
    //+------------------------------------------------------------------+
    bool ComparePrice(const double x, const double y, const int extType) const {
        return (extType == 1) ? (x > y) : (x < y);
    }

    //+------------------------------------------------------------------+
    //| Helper: Find new extreme points based on price action           |
    //+------------------------------------------------------------------+
    LocalExtreme FindBaseExtreme(const double high, const double low, const double close,
                                 const datetime timestamp, const double atrThreshold) {
        LocalExtreme result;

        // Initialize on first call
        if(m_highMax == 0.0 && m_lowMin == 0.0) {
            m_highMax     = high;
            m_highMaxTime = timestamp;
            m_lowMin      = low;
            m_lowMinTime  = timestamp;
            return result; // Invalid
        }

        if(m_moveUp) {
            // Looking for swing high
            if(high > m_highMax) {
                m_highMax     = high;
                m_highMaxTime = timestamp;
            } else if(low < m_highMax - atrThreshold) {
                // Confirmed swing high
                m_moveUp              = false;
                m_lowMin              = low;
                m_lowMinTime          = timestamp;

                result.ext_type       = 1; // Swing high
                result.price          = m_highMax;
                result.timestamp      = m_highMaxTime;
                result.conf_price     = close;
                result.conf_timestamp = timestamp;
            }
        } else {
            // Looking for swing low
            if(low < m_lowMin) {
                m_lowMin     = low;
                m_lowMinTime = timestamp;
            } else if(high > m_lowMin + atrThreshold) {
                // Confirmed swing low
                m_moveUp              = true;
                m_highMax             = high;
                m_highMaxTime         = timestamp;

                result.ext_type       = -1; // Swing low
                result.price          = m_lowMin;
                result.timestamp      = m_lowMinTime;
                result.conf_price     = close;
                result.conf_timestamp = timestamp;
            }
        }

        return result;
    }

    //+------------------------------------------------------------------+
    //| Helper: Add extreme to specified level                          |
    //+------------------------------------------------------------------+
    bool AddExtreme(const int level, LocalExtreme &ext) {
        if(level < 0 || level >= m_levels) return false;
        return m_levelExtremes[level].Add(ext);
    }

    //+------------------------------------------------------------------+
    //| Helper: Promote significant extreme points to higher levels     |
    //+------------------------------------------------------------------+
    void UpgradeExtremes(const int level, const datetime confTime, const double confPrice,
                         const int extType) {
        if(level >= m_levels - 1) return;

        int extIndex        = m_levelExtremes[level].Size() - 1;
        LocalExtreme newExt = m_levelExtremes[level].At(extIndex);

        if(!newExt.IsValid() || newExt.ext_type != extType) return;
        if(m_levelExtremes[level].Size() < 4) return;

        // Get previous extreme of same type (2 positions back)
        LocalExtreme prevExt = m_levelExtremes[level].At(extIndex - 2);
        if(!prevExt.IsValid() || prevExt.ext_type != extType) return;

        // Check if previous is more extreme than new
        if(!ComparePrice(prevExt.price, newExt.price, extType)) return;

        // Check against previous extreme on next level
        LocalExtreme prevNextLevel;
        int nextLevelSize = m_levelExtremes[level + 1].Size();

        if(nextLevelSize > 0) {
            prevNextLevel = m_levelExtremes[level + 1].At(nextLevelSize - 1);
            if(prevNextLevel.ext_type != extType) {
                if(!ComparePrice(prevExt.price, prevNextLevel.price, extType)) { return; }
            }
        }

        // Scan backwards to find most extreme point
        for(int i = extIndex - 4; i >= 0; i -= 2) {
            LocalExtreme priorExt = m_levelExtremes[level].At(i);
            if(priorExt.ext_type != extType) break;

            if(ComparePrice(priorExt.price, prevExt.price, extType)) { return; }

            if(prevNextLevel.IsValid() && priorExt.timestamp <= prevNextLevel.timestamp) {
                break;
            } else if(MathAbs(priorExt.price - prevExt.price) < 0.00001) {
                prevExt = priorExt;
            } else if(ComparePrice(priorExt.price, prevExt.price, -extType)) {
                break;
            }
        }

        // Create new extreme for next level
        LocalExtreme newLevelExt   = prevExt;
        newLevelExt.conf_timestamp = confTime;
        newLevelExt.conf_price     = confPrice;

        // Handle same-type extremes at next level
        if(prevNextLevel.IsValid() && prevNextLevel.ext_type == extType) {
            LocalExtreme upgradePoint;
            bool foundUpgrade = false;

            for(int i = extIndex - 1; i >= 0; i -= 2) {
                LocalExtreme priorTmp = m_levelExtremes[level].At(i);
                if(priorTmp.ext_type == extType) break;
                if(priorTmp.timestamp >= newLevelExt.timestamp) continue;
                if(priorTmp.timestamp <= prevNextLevel.timestamp) break;

                if(!foundUpgrade || !ComparePrice(priorTmp.price, upgradePoint.price, extType)) {
                    upgradePoint = priorTmp;
                    foundUpgrade = true;
                }
            }

            if(foundUpgrade) {
                LocalExtreme upgraded   = upgradePoint;
                upgraded.conf_timestamp = confTime;
                upgraded.conf_price     = confPrice;
                AddExtreme(level + 1, upgraded);

                if(m_telemetry) {
                    m_telemetry.Info(
                        StringFormat("Swing: Upgraded opposite extreme to level %d", level + 1));
                }

                UpgradeExtremes(level + 1, confTime, confPrice, -extType);
            }
        }

        // Add new extreme to next level
        AddExtreme(level + 1, newLevelExt);

        if(m_telemetry) {
            m_telemetry.Info(
                StringFormat("Swing: Upgraded extreme to level %d, type=%d", level + 1, extType));
        }

        UpgradeExtremes(level + 1, confTime, confPrice, extType);
    }

  public:
    //+------------------------------------------------------------------+
    //| Constructor                                                       |
    //+------------------------------------------------------------------+
    Strat_SwingStructure(IMarketData *md, const string symbol, const ENUM_TIMEFRAMES tf,
                         const int atrPeriod, const int levels, const int signalLevel,
                         const double atrMultiplier = 1.0, ITelemetry *telemetry = NULL)
        : m_md(md), m_telemetry(telemetry), m_symbol(symbol), m_tf(tf), m_atrPeriod(atrPeriod),
          m_levels(levels), m_signalLevel(signalLevel), m_atrMultiplier(atrMultiplier),
          m_highMax(0.0), m_lowMin(0.0), m_highMaxTime(0), m_lowMinTime(0), m_moveUp(true) {
        // Initialize ATR indicator
        m_atrHandle = iATR(m_symbol, m_tf, m_atrPeriod);

        // Initialize level extremes array
        ArrayResize(m_levelExtremes, m_levels);
        for(int i = 0; i < m_levels; i++) { m_levelExtremes[i].level = i; }

        if(m_telemetry) {
            m_telemetry.Info(
                StringFormat("SwingStructure initialized: %d levels, signal from level %d",
                             m_levels, m_signalLevel));
        }
    }

    //+------------------------------------------------------------------+
    //| Destructor                                                       |
    //+------------------------------------------------------------------+
    ~Strat_SwingStructure() {
        if(m_atrHandle != INVALID_HANDLE) { IndicatorRelease(m_atrHandle); }
    }

    //+------------------------------------------------------------------+
    //| Check if strategy is ready                                      |
    //+------------------------------------------------------------------+
    bool IsReady() const {
        return (m_md != NULL && m_atrHandle != INVALID_HANDLE && m_signalLevel >= 0
                && m_signalLevel < m_levels);
    }

    //+------------------------------------------------------------------+
    //| Check if should enter a trade                                   |
    //+------------------------------------------------------------------+
    bool ShouldEnter(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &signal) override {
        if(!IsReady()) return false;

        // Get ATR value
        double atr[1];
        if(CopyBuffer(m_atrHandle, 0, 1, 1, atr) != 1) {
            if(m_telemetry) m_telemetry.Warn("SwingStructure: Failed to get ATR value");
            return false;
        }

        // Get OHLC data
        if(m_md == NULL) {
            if(m_telemetry) m_telemetry.Error("SwingStructure: MarketData not initialized");
            return false;
        }

        double open, high, low, close;
        if(!m_md.OHLC(sym, tf, 1, open, high, low, close)) {
            if(m_telemetry) m_telemetry.Warn("SwingStructure: Failed to get OHLC data");
            return false;
        }

        const datetime time = iTime(sym, tf, 1);

        if(high == 0.0 || low == 0.0 || close == 0.0 || time == 0) {
            if(m_telemetry) m_telemetry.Warn("SwingStructure: Invalid OHLC data");
            return false;
        }

        // Find base extreme
        LocalExtreme baseExt = FindBaseExtreme(high, low, close, time, atr[0] * m_atrMultiplier);
        if(!baseExt.IsValid()) return false;

        // Add to level 0
        if(!AddExtreme(0, baseExt)) {
            if(m_telemetry) m_telemetry.Error("SwingStructure: Failed to add base extreme");
            return false;
        }

        // Track signal level size before upgrade
        int sizeBefore = m_levelExtremes[m_signalLevel].Size();

        // Upgrade extremes to higher levels
        UpgradeExtremes(0, time, close, baseExt.ext_type);

        // Check if new extreme was added to signal level
        int sizeAfter = m_levelExtremes[m_signalLevel].Size();
        if(sizeBefore == sizeAfter) return false;

        // New extreme at signal level - generate trade signal
        LocalExtreme signalExt = m_levelExtremes[m_signalLevel].At(sizeAfter - 1);

        // Signal opposite to extreme type (break of structure)
        // Swing high -> potential sell, Swing low -> potential buy
        signal.valid          = true;
        signal.isSell         = (signalExt.ext_type == 1); // High = Sell, Low = Buy
        signal.type           = signal.isSell ? TRADE_TYPE_SELL : TRADE_TYPE_BUY;
        signal.isOrderPending = false; // Market order
        signal.price          = 0.0;   // Market price (set by execution adapter)
        signal.sl             = 0.0;   // Will be set by targets
        signal.tp             = 0.0;   // Will be set by targets
        signal.stopPoints     = 0;
        signal.comment        = StringFormat("SwingBreak_L%d", m_signalLevel);

        if(m_telemetry) {
            string direction = signal.isSell ? "SELL" : "BUY";
            m_telemetry.Info(
                StringFormat("SwingStructure: Signal generated - %s at level %d (extreme type=%d)",
                             direction, m_signalLevel, signalExt.ext_type));
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| Accessor methods                                                 |
    //+------------------------------------------------------------------+
    int GetLevels() const { return m_levels; }
    int GetSignalLevel() const { return m_signalLevel; }

    //+------------------------------------------------------------------+
    //| Get extreme at specific level and index                         |
    //+------------------------------------------------------------------+
    LocalExtreme GetExtreme(const int level, const int index) const {
        if(level < 0 || level >= m_levels) return LocalExtreme();
        return m_levelExtremes[level].At(index);
    }

    //+------------------------------------------------------------------+
    //| Get last extreme at specific level                              |
    //+------------------------------------------------------------------+
    LocalExtreme GetLastExtreme(const int level) const {
        if(level < 0 || level >= m_levels) return LocalExtreme();
        return m_levelExtremes[level].GetLast();
    }

    //+------------------------------------------------------------------+
    //| Get level extremes collection                                   |
    //+------------------------------------------------------------------+
    LevelExtremes GetLevelExtremes(const int level) const {
        if(level < 0 || level >= m_levels) return LevelExtremes();
        return m_levelExtremes[level];
    }

    //+------------------------------------------------------------------+
    //| Get total extremes at specific level                            |
    //+------------------------------------------------------------------+
    int GetLevelSize(const int level) const {
        if(level < 0 || level >= m_levels) return 0;
        return m_levelExtremes[level].Size();
    }
};
