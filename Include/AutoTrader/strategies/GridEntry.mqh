//+------------------------------------------------------------------+
//| GridEntry.mqh - Multi-Entry Grid Strategy                        |
//| Đặt nhiều lệnh pending order theo dạng lưới (grid)                |
//+------------------------------------------------------------------+
#property strict

#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ISignal.mqh>

//+------------------------------------------------------------------+
//| Grid Entry Strategy - Places multiple pending orders             |
//| Use case: Grid trading, DCA (Dollar Cost Averaging)              |
//+------------------------------------------------------------------+
class GridEntry : public ISignal {
private:
  IMarketData *m_md;
  string m_sym;
  ENUM_TIMEFRAMES m_tf;

  // Grid parameters
  int m_numOrders;       // Số lượng lệnh trong grid
  double m_gridStepPips; // Khoảng cách giữa các lệnh (pips)
  int m_stopLossPips;    // Stop loss cho mỗi lệnh
  int m_takeProfitPips;  // Take profit cho mỗi lệnh
  bool m_isBuyGrid;      // true = Buy grid, false = Sell grid

  datetime m_lastSignalTime; // Tránh tạo grid liên tục

public:
  //+------------------------------------------------------------------+
  //| Constructor                                                       |
  //+------------------------------------------------------------------+
  GridEntry(IMarketData *md, const string sym, const ENUM_TIMEFRAMES tf, const int numOrders = 3,
            const double gridStepPips = 10.0, const int slPips = 50, const int tpPips = 100,
            const bool isBuyGrid = true)
      : m_md(md), m_sym(sym), m_tf(tf), m_numOrders(numOrders), m_gridStepPips(gridStepPips),
        m_stopLossPips(slPips), m_takeProfitPips(tpPips), m_isBuyGrid(isBuyGrid),
        m_lastSignalTime(0) {}

  //+------------------------------------------------------------------+
  //| Check if strategy is ready                                       |
  //+------------------------------------------------------------------+
  bool IsReady() const override { return (m_md != NULL && m_numOrders > 0); }

  //+------------------------------------------------------------------+
  //| Single signal (backward compatible)                              |
  //+------------------------------------------------------------------+
  bool ShouldEnter(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &out) override {
    // Default: return first signal only
    TradeSignal signals[];
    if(!ShouldEnterMulti(sym, tf, signals)) return false;
    if(ArraySize(signals) == 0) return false;

    out = signals[0];
    return true;
  }

  //+------------------------------------------------------------------+
  //| Multiple signals - Grid logic                                    |
  //+------------------------------------------------------------------+
  bool
  ShouldEnterMulti(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &signals[]) override {
    if(sym != m_sym || tf != m_tf) return false;
    if(!IsReady()) return false;

    // Cooldown: chỉ tạo grid 1 lần mỗi 1 giờ
    datetime currentTime = TimeCurrent();
    if(currentTime - m_lastSignalTime < 3600) return false;

    // Get current price
    double currentPrice;
    if(m_isBuyGrid) {
      currentPrice = m_md.Ask(m_sym);
    } else {
      currentPrice = m_md.Bid(m_sym);
    }

    if(currentPrice <= 0) return false;

    // Calculate point value
    double point   = SymbolInfoDouble(m_sym, SYMBOL_POINT);
    int digits     = (int)SymbolInfoInteger(m_sym, SYMBOL_DIGITS);
    double pipSize = (digits == 3 || digits == 5) ? point * 10 : point;

    // Build grid signals
    ArrayResize(signals, m_numOrders);

    for(int i = 0; i < m_numOrders; i++) {
      signals[i].valid          = true;
      signals[i].isSell         = !m_isBuyGrid;
      signals[i].isOrderPending = true;

      // Calculate grid level price
      double offset = (i + 1) * m_gridStepPips * pipSize;

      if(m_isBuyGrid) {
        // Buy grid: place orders below current price (Buy Limit)
        signals[i].type  = TRADE_TYPE_BUY_LIMIT;
        signals[i].price = NormalizeDouble(currentPrice - offset, digits);
        signals[i].sl    = NormalizeDouble(signals[i].price - m_stopLossPips * pipSize, digits);
        signals[i].tp    = NormalizeDouble(signals[i].price + m_takeProfitPips * pipSize, digits);
      } else {
        // Sell grid: place orders above current price (Sell Limit)
        signals[i].type  = TRADE_TYPE_SELL_LIMIT;
        signals[i].price = NormalizeDouble(currentPrice + offset, digits);
        signals[i].sl    = NormalizeDouble(signals[i].price + m_stopLossPips * pipSize, digits);
        signals[i].tp    = NormalizeDouble(signals[i].price - m_takeProfitPips * pipSize, digits);
      }

      signals[i].stopPoints = m_stopLossPips * 10; // For position sizing
      signals[i].comment    = StringFormat("Grid_%d_%.2f", i + 1, m_gridStepPips * (i + 1));

      Print("Grid[", i, "] price=", signals[i].price, " sl=", signals[i].sl, " tp=", signals[i].tp);
    }

    m_lastSignalTime = currentTime;
    Print("GridEntry: Created ", m_numOrders, " ", (m_isBuyGrid ? "BUY" : "SELL"), " limit orders");

    return true;
  }
};
