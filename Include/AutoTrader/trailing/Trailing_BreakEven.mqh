//+------------------------------------------------------------------+
//| Trailing_BreakEven.mqh (dùng IPositions + IMarketData)           |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/ports/IExecution.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/IPositions.mqh>
#include <AutoTrader/domain/ports/ITrailing.mqh>

enum ENUM_TSL_CALC_MODE {
  TSL_CALC_OFF     = 0,
  TSL_CALC_POINTS  = 1,
  TSL_CALC_PERCENT = 2,
  TSL_CALC_RR      = 3
};

class Trailing_BreakEven : public ITrailing {
private:
  IMarketData *m_md;
  IExecution *m_exec;
  IPositions *m_pos;
  double m_trigger;
  double m_buffer;
  ENUM_TSL_CALC_MODE m_mode;

  //+------------------------------------------------------------------+
  //| Tính khoảng cách theo mode đã chọn                               |
  //+------------------------------------------------------------------+
  double CalcDistance(const string sym, const double cfgVal, const double openPrice,
                      const double slInitial) const {
    if(cfgVal <= 0) return 0.0;
    switch(m_mode) {
    case TSL_CALC_POINTS: {
      const double point = (m_md ? m_md.Point(sym) : 0.0);
      return (point > 0.0) ? (cfgVal * point) : 0.0;
    }
    case TSL_CALC_PERCENT: return openPrice * (cfgVal / 100.0);
    case TSL_CALC_RR: {
      if(slInitial == 0.0 || slInitial == EMPTY_VALUE) return 0.0;
      const double riskDistance = MathAbs(openPrice - slInitial); // 1R
      return cfgVal * riskDistance;
    }
    default: return 0.0;
    }
  }

  //+------------------------------------------------------------------+
  //| Snap giá về tick size hợp lệ                                     |
  //+------------------------------------------------------------------+
  double SnapToTick(const string sym, double price) const {
    const double tick = (m_md ? m_md.TickSize(sym) : 0.0);
    if(tick <= 0) return price;
    const double steps = MathRound(price / tick);
    return steps * tick;
  }

public:
  //+------------------------------------------------------------------+
  //| Constructor                                                       |
  //+------------------------------------------------------------------+
  Trailing_BreakEven(IMarketData *md, IExecution *exec, IPositions *pos, const double trigger,
                     const double buffer, const ENUM_TSL_CALC_MODE mode = TSL_CALC_POINTS)
      : m_md(md), m_exec(exec), m_pos(pos), m_trigger(trigger), m_buffer(buffer), m_mode(mode) {}

  //+------------------------------------------------------------------+
  //| Kiểm tra dependencies sẵn sàng                                   |
  //+------------------------------------------------------------------+
  bool IsReady() const { return (m_md != NULL && m_exec != NULL && m_pos != NULL); }

  //+------------------------------------------------------------------+
  //| Trailing cho toàn bộ positions theo symbol & magic               |
  //+------------------------------------------------------------------+
  bool ManageAll(const string sym, const long magic) {
    if(!IsReady()) return false;

    // Lấy danh sách tất cả positions theo symbol & magic
    PositionInfo positions[];
    const int total = m_pos.ListBySymbolMagic(sym, magic, positions);

    if(total <= 0) return false;

    bool anyTrailed = false;
    for(int i = 0; i < total; i++) {
      PositionInfo pi        = positions[i];

      const bool isSell      = pi.IsSell();
      const double openPrice = pi.price_open;
      const double slInitial = pi.sl;
      const double curPrice  = pi.price_current;
      const double curSL     = pi.sl;
      const double curTP     = pi.tp;

      // 1. Kiểm tra trigger distance
      const double triggerDist = CalcDistance(sym, m_trigger, openPrice, slInitial);
      const double delta       = isSell ? (openPrice - curPrice) : (curPrice - openPrice);
      if(triggerDist <= 0.0 || delta < triggerDist) continue;

      // 2. Tính buffer distance
      const double bufferDist = CalcDistance(sym, m_buffer, openPrice, slInitial);
      if(bufferDist <= 0.0) continue;

      // 3. Tính SL mới
      double newSL = isSell ? (openPrice - bufferDist) : (openPrice + bufferDist);
      newSL        = SnapToTick(sym, newSL);

      // 4. One-way trailing + không vượt qua giá hiện tại
      if(!isSell) {
        if(curSL > 0 && newSL <= curSL) continue; // Không lùi SL
        if(newSL >= curPrice) continue;           // SL không vượt giá hiện tại
      } else {
        if(curSL > 0 && newSL >= curSL) continue; // Không lùi SL
        if(newSL <= curPrice) continue;           // SL không vượt giá hiện tại
      }

      // 5. Thực hiện modify SL
      bool ok = m_exec.ModifyPositionByTicket(pi.ticket, newSL, curTP);
      if(ok) {
        anyTrailed = true;
        Print("Trailing BE executed for ticket ", pi.ticket, " new SL: ", newSL);
      } else {
        Print("Trailing BE failed for ticket ", pi.ticket);
      }
    }
    return anyTrailed;
  }

  //+------------------------------------------------------------------+
  //| Interface method từ ITrailing (backward compatibility)           |
  //+------------------------------------------------------------------+
  bool Manage(const string sym, const ENUM_TIMEFRAMES tf, const long magic) override {
    return ManageAll(sym, magic);
  }
};
