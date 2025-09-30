//+------------------------------------------------------------------+
//| Include/AutoTrader/trailing/Trailing_Distance.mqh                |
//| ITrailing adapter (fixed-distance TSL) using IMarketData/IPositions
//+------------------------------------------------------------------+

#include <AutoTrader/domain/ports/IExecution.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/IPositions.mqh>   // <-- NEW
#include <AutoTrader/domain/ports/ITrailing.mqh>

// Giữ nguyên enum tính khoảng cách như bản gốc
enum ENUM_TSL_CALC_MODE {
  TSL_CALC_OFF     = 0,
  TSL_CALC_POINTS  = 1, // theo points
  TSL_CALC_PERCENT = 2, // theo %
  TSL_CALC_RR      = 3  // theo R so với SL ban đầu
};

class Trailing_Distance : public ITrailing {
private:
  IMarketData *m_md;   // dùng Point()/TickSize()
  IExecution  *m_exec;
  IPositions  *m_pos;  // dùng để đọc PositionInfo (không gọi API MQL5 trực tiếp)

  const double           m_trigger;     // Ngưỡng kích hoạt
  const double           m_slDistance;  // Khoảng cách SL giữ sau giá hiện tại
  const double           m_stepValue;   // Cải thiện tối thiểu giữa các lần trail
  const ENUM_TSL_CALC_MODE m_mode;

  //--- Helpers ------------------------------------------------------
  inline double PointOf(const string sym) const {
    return (m_md ? m_md.Point(sym) : 0.0);
  }
  inline double TickSnap(const string sym, const double price) const {
    const double tick = (m_md ? m_md.TickSize(sym) : 0.0);
    if(tick <= 0.0) return price;
    return MathRound(price / tick) * tick;
  }

  // Tính ngưỡng kích hoạt theo mode
  double TriggerDistance(const string sym, const double openPrice, const double slInitial) const {
    switch(m_mode) {
      case TSL_CALC_POINTS:  { const double p = PointOf(sym); return (p>0.0) ? (m_trigger * p) : 0.0; }
      case TSL_CALC_PERCENT: return openPrice * m_trigger / 100.0;
      case TSL_CALC_RR: {
        if(slInitial == 0.0) return 0.0;
        const double oneR = MathAbs(openPrice - slInitial);
        return oneR * m_trigger;
      }
      default: return 0.0;
    }
  }

  // Tính khoảng cách SL bám theo mode
  double FollowDistance(const string sym, const double refPrice,
                        const double openPrice, const double slInitial) const
  {
    switch(m_mode) {
      case TSL_CALC_POINTS:  { const double p = PointOf(sym); return (p>0.0) ? (m_slDistance * p) : 0.0; }
      case TSL_CALC_PERCENT: return refPrice * m_slDistance / 100.0; // theo giá hiện tại
      case TSL_CALC_RR: {
        if(slInitial == 0.0) return 0.0;
        const double oneR = MathAbs(openPrice - slInitial);
        return oneR * m_slDistance;
      }
      default: return 0.0;
    }
  }

  // Bước cải thiện tối thiểu
  double StepDistance(const string sym, const double refPrice,
                      const double openPrice, const double slInitial) const
  {
    switch(m_mode) {
      case TSL_CALC_POINTS:  { const double p = PointOf(sym); return (p>0.0) ? (m_stepValue * p) : 0.0; }
      case TSL_CALC_PERCENT: return refPrice * m_stepValue / 100.0;
      case TSL_CALC_RR: {
        if(slInitial == 0.0) return 0.0;
        const double oneR = MathAbs(openPrice - slInitial);
        return oneR * m_stepValue;
      }
      default: return 0.0;
    }
  }

public:
  // trigger/slDistance/stepValue đều tính theo m_mode
  Trailing_Distance(IMarketData *md, IExecution *exec, IPositions *pos,
                    const double trigger, const double slDistance, const double stepValue,
                    const ENUM_TSL_CALC_MODE mode = TSL_CALC_POINTS)
  : m_md(md), m_exec(exec), m_pos(pos),
    m_trigger(trigger), m_slDistance(slDistance), m_stepValue(stepValue), m_mode(mode) {}

  // ITrailing::Manage
  bool Manage(const string sym, const ENUM_TIMEFRAMES tf, const long magic) override {
    if(m_exec == NULL || m_pos == NULL) return false;

    // Lấy position qua IPositions
    PositionInfo pi;
    if(!m_pos.FirstBySymbolMagic(sym, magic, pi)) return false;

    const bool   isSell    = (pi.type == POSITION_TYPE_SELL);
    const double openPrice = pi.price_open;
    const double slInit    = pi.sl;            // dùng cho RR
    const double curPrice  = pi.price_current;
    const double curSL     = pi.sl;
    const double curTP     = pi.tp;

    // 1) Lợi nhuận tạm tính từ open
    const double delta = isSell ? (openPrice - curPrice) : (curPrice - openPrice);

    // 2) Kiểm tra kích hoạt
    const double trig = TriggerDistance(sym, openPrice, slInit);
    if(trig <= 0.0 || delta < trig) return false;

    // 3) Khoảng cách SL cần giữ sau giá hiện tại
    const double dist = FollowDistance(sym, curPrice, openPrice, slInit);
    if(dist <= 0.0) return false;

    // 4) Tính SL mong muốn
    double newSL = isSell ? (curPrice + dist) : (curPrice - dist);

    // 5) Áp dụng step cải thiện tối thiểu (nếu đã có SL)
    if(curSL != 0.0) {
      const double step = StepDistance(sym, curPrice, openPrice, slInit);
      if(step > 0.0) {
        const double improve = isSell ? (curSL - newSL) : (newSL - curSL);
        if(improve < step) return false; // chưa cải thiện đủ
      }
    }

    // 6) Trail một chiều + hợp lệ so với giá hiện tại
    if(!isSell) {
      // BUY: SL chỉ tăng & luôn < giá hiện tại
      if(curSL > 0.0 && newSL <= curSL) return false;
      if(newSL >= curPrice) return false;
    } else {
      // SELL: SL chỉ giảm & luôn > giá hiện tại
      if(curSL > 0.0 && newSL >= curSL) return false;
      if(newSL <= curPrice) return false;
    }

    // 7) Snap theo tick và gửi lệnh sửa
    newSL = TickSnap(sym, newSL);
    return m_exec.ModifySLTPBySymbolMagic(sym, magic, newSL, curTP);
  }
};
