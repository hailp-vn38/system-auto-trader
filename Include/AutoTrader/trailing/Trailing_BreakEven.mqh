//+------------------------------------------------------------------+
//| Trailing_BreakEven.mqh (dùng IPositions + IMarketData)           |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/ports/IExecution.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/IPositions.mqh>   // <-- NEW
#include <AutoTrader/domain/ports/ITrailing.mqh>

enum ENUM_TSL_CALC_MODE { TSL_CALC_OFF=0, TSL_CALC_POINTS=1, TSL_CALC_PERCENT=2, TSL_CALC_RR=3 };

class Trailing_BreakEven : public ITrailing {
private:
  IMarketData *m_md;
  IExecution  *m_exec;
  IPositions  *m_pos;     // <-- NEW

  double             m_trigger;
  double             m_buffer;
  ENUM_TSL_CALC_MODE m_mode;

  double CalcDistance(const string sym, const double cfgVal,
                      const double openPrice, const double slInitial) const
  {
    if(cfgVal <= 0) return 0.0;
    switch(m_mode) {
      case TSL_CALC_POINTS: {
        const double point = (m_md ? m_md.Point(sym) : 0.0);
        return (point>0.0) ? (cfgVal * point) : 0.0;
      }
      case TSL_CALC_PERCENT: return openPrice * (cfgVal / 100.0);
      case TSL_CALC_RR: {
        if(slInitial==0.0 || slInitial==EMPTY_VALUE) return 0.0;
        const double riskDistance = MathAbs(openPrice - slInitial); // 1R
        return cfgVal * riskDistance;
      }
      default: return 0.0;
    }
  }

  double SnapToTick(const string sym, double price) const {
    const double tick = (m_md ? m_md.TickSize(sym) : 0.0);
    if(tick <= 0) return price;
    const double steps = MathRound(price / tick);
    return steps * tick;
  }

public:
  Trailing_BreakEven(IMarketData *md, IExecution *exec, IPositions *pos,
                     const double trigger, const double buffer,
                     const ENUM_TSL_CALC_MODE mode = TSL_CALC_POINTS)
  : m_md(md), m_exec(exec), m_pos(pos),
    m_trigger(trigger), m_buffer(buffer), m_mode(mode) {}

  bool Manage(const string sym, const ENUM_TIMEFRAMES tf, const long magic) override {
    if(m_exec == NULL || m_pos == NULL) return false;

    PositionInfo pi;
    if(!m_pos.FirstBySymbolMagic(sym, magic, pi)) return false;

    const bool   isSell    = (pi.type == POSITION_TYPE_SELL);
    const double openPrice = pi.price_open;
    const double slInitial = pi.sl;
    const double curPrice  = pi.price_current;
    const double curSL     = pi.sl;
    const double curTP     = pi.tp;

    // 1) Kích hoạt?
    const double delta       = isSell ? (openPrice - curPrice) : (curPrice - openPrice);
    const double triggerDist = CalcDistance(sym, m_trigger, openPrice, slInitial);
    if(triggerDist <= 0.0 || delta < triggerDist) return false;

    // 2) Buffer
    const double bufferDist = CalcDistance(sym, m_buffer, openPrice, slInitial);
    if(bufferDist <= 0.0) return false;

    // 3) SL BE ± buffer
    double newSL = isSell ? (openPrice - bufferDist) : (openPrice + bufferDist);

    // 4) Snap tick
    newSL = SnapToTick(sym, newSL);

    // 5) One-way trailing + hợp lệ
    if(!isSell){
      if(curSL>0 && newSL<=curSL) return false;
      if(newSL>=curPrice)         return false;
    } else {
      if(curSL>0 && newSL>=curSL) return false;
      if(newSL<=curPrice)         return false;
    }

    // 6) Sửa SL
    return m_exec.ModifySLTPBySymbolMagic(sym, magic, newSL, curTP);
  }
};
