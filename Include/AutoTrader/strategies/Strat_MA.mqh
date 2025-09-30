
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ISignal.mqh>
#include <AutoTrader/utils/PriceCalc.mqh>

class Strat_MA : public ISignal {
  IMarketData *md;
  int fast, slow, sl_pts, tp_pts;

public:
  Strat_MA(IMarketData *market, int fastMA, int slowMA, int slPoints, int tpPoints)
      : md(market), fast(fastMA), slow(slowMA), sl_pts(slPoints), tp_pts(tpPoints) {}

  virtual bool ShouldEnter(string sym, ENUM_TIMEFRAMES tf, TradeSignal &out) {
    if(!md) return false;
    double f1 = md.MA(sym, tf, fast, 1);
    double s1 = md.MA(sym, tf, slow, 1);
    double f2 = md.MA(sym, tf, fast, 2);
    double s2 = md.MA(sym, tf, slow, 2);
    if(f2 <= s2 && f1 > s1) {
      out.orderType  = ORDER_TYPE_BUY;
      out.sl         = PriceCalc::SL(sym, ORDER_TYPE_BUY, sl_pts);
      out.tp         = PriceCalc::TP(sym, ORDER_TYPE_BUY, tp_pts);
      out.stopPoints = sl_pts;
      out.valid      = true;
      return true;
    }
    if(f2 >= s2 && f1 < s1) {
      out.orderType  = ORDER_TYPE_SELL;
      out.sl         = PriceCalc::SL(sym, ORDER_TYPE_SELL, sl_pts);
      out.tp         = PriceCalc::TP(sym, ORDER_TYPE_SELL, tp_pts);
      out.stopPoints = sl_pts;
      out.valid      = true;
      return true;
    }
    out.valid = false;
    return false;
  }
};
