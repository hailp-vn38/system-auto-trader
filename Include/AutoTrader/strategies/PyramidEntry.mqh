//+------------------------------------------------------------------+
//| PyramidEntry.mqh - Multiple Entries on Trend Continuation        |
//| Thêm vị thế khi trend tiếp diễn (scale in)                        |
//+------------------------------------------------------------------+
#property strict

#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ISignal.mqh>

//+------------------------------------------------------------------+
//| Pyramid Entry Strategy - Add positions on trend continuation     |
//| Use case: Trend following, Scale-in strategy                     |
//+------------------------------------------------------------------+
class PyramidEntry : public ISignal {
private:
  IMarketData *m_md;
  string m_sym;
  ENUM_TIMEFRAMES m_tf;

  int m_hMA;              // Moving Average handle
  int m_maPeriod;         // MA period
  int m_pyramidLevels;    // Số cấp pyramid
  double m_levelStepPips; // Khoảng cách giữa các cấp
  int m_slPips;           // Stop loss

  double m_lastMAValue; // Track MA for trend
  datetime m_lastCheck;

public:
  //+------------------------------------------------------------------+
  //| Constructor                                                       |
  //+------------------------------------------------------------------+
  PyramidEntry(IMarketData *md, const string sym, const ENUM_TIMEFRAMES tf, const int maPeriod = 50,
               const int pyramidLevels = 3, const double levelStepPips = 20.0,
               const int slPips = 100)
      : m_md(md), m_sym(sym), m_tf(tf), m_maPeriod(maPeriod), m_pyramidLevels(pyramidLevels),
        m_levelStepPips(levelStepPips), m_slPips(slPips), m_lastMAValue(0), m_lastCheck(0) {
    m_hMA = iMA(m_sym, m_tf, m_maPeriod, 0, MODE_EMA, PRICE_CLOSE);
    if(m_hMA != INVALID_HANDLE) { ChartIndicatorAdd(0, 0, m_hMA); }
  }

  //+------------------------------------------------------------------+
  //| Check if strategy is ready                                       |
  //+------------------------------------------------------------------+
  bool IsReady() const override { return (m_md != NULL && m_hMA != INVALID_HANDLE); }

  //+------------------------------------------------------------------+
  //| Single signal (backward compatible)                              |
  //+------------------------------------------------------------------+
  bool ShouldEnter(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &out) override {
    TradeSignal signals[];
    if(!ShouldEnterMulti(sym, tf, signals)) return false;
    if(ArraySize(signals) == 0) return false;

    out = signals[0];
    return true;
  }

  //+------------------------------------------------------------------+
  //| Multiple signals - Pyramid logic                                 |
  //+------------------------------------------------------------------+
  bool
  ShouldEnterMulti(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &signals[]) override {
    if(sym != m_sym || tf != m_tf) return false;
    if(!IsReady()) return false;

    // Check only once per bar
    datetime barTime = iTime(m_sym, m_tf, 0);
    if(barTime <= m_lastCheck) return false;
    m_lastCheck = barTime;

    // Get current MA value
    double maBuffer[1];
    if(CopyBuffer(m_hMA, 0, 0, 1, maBuffer) != 1) return false;
    double currentMA = maBuffer[0];
    if(currentMA == EMPTY_VALUE) return false;

    // Get current price
    double currentPrice = m_md.Ask(m_sym);
    if(currentPrice <= 0) return false;

    // Check for strong uptrend (price > MA and MA rising)
    bool isUptrend = (currentPrice > currentMA);
    if(m_lastMAValue > 0) {
      isUptrend = isUptrend && (currentMA > m_lastMAValue); // MA rising
    }

    m_lastMAValue = currentMA;

    if(!isUptrend) return false;

    // Calculate point value
    double point   = SymbolInfoDouble(m_sym, SYMBOL_POINT);
    int digits     = (int)SymbolInfoInteger(m_sym, SYMBOL_DIGITS);
    double pipSize = (digits == 3 || digits == 5) ? point * 10 : point;

    // Build pyramid signals - Buy Stop orders above current price
    ArrayResize(signals, m_pyramidLevels);

    for(int i = 0; i < m_pyramidLevels; i++) {
      signals[i].valid          = true;
      signals[i].isSell         = false;
      signals[i].isOrderPending = true;
      signals[i].type           = TRADE_TYPE_BUY_STOP;

      // Each level is placed higher
      double offset    = (i + 1) * m_levelStepPips * pipSize;
      signals[i].price = NormalizeDouble(currentPrice + offset, digits);

      // Common SL for all levels
      signals[i].sl = NormalizeDouble(currentMA - m_slPips * pipSize, digits);

      // TP increases with each level (risk-reward improvement)
      signals[i].tp         = NormalizeDouble(signals[i].price + (m_slPips * 2 * (i + 1)) * pipSize,
                                              digits);

      signals[i].stopPoints = m_slPips * 10;
      signals[i].comment    = StringFormat("Pyramid_%d", i + 1);

      Print("Pyramid[", i, "] BUY_STOP @ ", signals[i].price, " sl=", signals[i].sl,
            " tp=", signals[i].tp);
    }

    Print("PyramidEntry: Created ", m_pyramidLevels, " BUY_STOP orders for uptrend continuation");

    return true;
  }
};
