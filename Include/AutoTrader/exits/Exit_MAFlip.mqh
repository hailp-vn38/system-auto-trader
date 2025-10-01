
#include <AutoTrader/domain/ports/IExitSignal.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/utils/Positions.mqh>

class Exit_MAFlip : public IExitSignal {
  IMarketData *md;
  int fast, slow;

public:
  Exit_MAFlip(IMarketData *market, int fastMA, int slowMA)
      : md(market), fast(fastMA), slow(slowMA) {}

  virtual bool ShouldExit(const string sym,const ENUM_TIMEFRAMES tf, long magic) {
    ulong ticket;
    if(!PositionsEx::SelectFirstBySymbolMagic(sym, magic, ticket)) return false;
    long type = PositionGetInteger(POSITION_TYPE);
    double f1 = md.MA(sym, tf, fast, 1);
    double s1 = md.MA(sym, tf, slow, 1);
    double f2 = md.MA(sym, tf, fast, 2);
    double s2 = md.MA(sym, tf, slow, 2);
    if(type == POSITION_TYPE_BUY && f2 >= s2 && f1 < s1) return true;
    if(type == POSITION_TYPE_SELL && f2 <= s2 && f1 > s1) return true;
    return false;
  }
};
