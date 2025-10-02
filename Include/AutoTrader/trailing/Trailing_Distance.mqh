//+------------------------------------------------------------------+
//| Include/AutoTrader/trailing/Trailing_Distance.mqh                |
//| ITrailing adapter (fixed-distance TSL) using IMarketData/IPositions
//+------------------------------------------------------------------+

#include <AutoTrader/domain/ports/IExecution.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/IPositions.mqh>
#include <AutoTrader/domain/ports/ITelemetry.mqh>
#include <AutoTrader/domain/ports/ITrailing.mqh>
#include <AutoTrader/trailing/TrailingTypes.mqh>

class Trailing_Distance : public ITrailing {
  private:
    IMarketData *m_md; // dùng Point()/TickSize()
    IExecution *m_exec;
    IPositions *m_pos;       // dùng để đọc PositionInfo (không gọi API MQL5 trực tiếp)
    ITelemetry *m_telemetry; // logging

    const double m_trigger;    // Ngưỡng kích hoạt
    const double m_slDistance; // Khoảng cách SL giữ sau giá hiện tại
    const double m_stepValue;  // Cải thiện tối thiểu giữa các lần trail
    const ENUM_TSL_CALC_MODE m_mode;

    //+------------------------------------------------------------------+
    //| Helper: Tính khoảng cách theo mode (chung cho cả 3 loại)        |
    //+------------------------------------------------------------------+
    double CalcDistance(const string sym, const double cfgVal, const double refPrice,
                        const double openPrice, const double slInitial) const {
        if(cfgVal <= 0.0) return 0.0;
        switch(m_mode) {
        case TSL_CALC_POINTS: {
            const double point = (m_md ? m_md.Point(sym) : 0.0);
            return (point > 0.0) ? (cfgVal * point) : 0.0;
        }
        case TSL_CALC_PERCENT: return refPrice * (cfgVal / 100.0);
        case TSL_CALC_RR: {
            if(slInitial == 0.0 || slInitial == EMPTY_VALUE) return 0.0;
            const double riskDistance = MathAbs(openPrice - slInitial); // 1R
            return cfgVal * riskDistance;
        }
        default: return 0.0;
        }
    }

    //+------------------------------------------------------------------+
    //| Helper: Snap giá về tick size hợp lệ                             |
    //+------------------------------------------------------------------+
    double SnapToTick(const string sym, double price) const {
        const double tick = (m_md ? m_md.TickSize(sym) : 0.0);
        if(tick <= 0.0) return price;
        const double steps = MathRound(price / tick);
        return steps * tick;
    }

    //--- Legacy Helpers (giữ lại để tương thích) ----------------------
    inline double PointOf(const string sym) const { return (m_md ? m_md.Point(sym) : 0.0); }
    inline double TickSnap(const string sym, const double price) const {
        return SnapToTick(sym, price);
    }

    // Tính ngưỡng kích hoạt theo mode
    double TriggerDistance(const string sym, const double openPrice, const double slInitial) const {
        switch(m_mode) {
        case TSL_CALC_POINTS: {
            const double p = PointOf(sym);
            return (p > 0.0) ? (m_trigger * p) : 0.0;
        }
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
    double FollowDistance(const string sym, const double refPrice, const double openPrice,
                          const double slInitial) const {
        switch(m_mode) {
        case TSL_CALC_POINTS: {
            const double p = PointOf(sym);
            return (p > 0.0) ? (m_slDistance * p) : 0.0;
        }
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
    double StepDistance(const string sym, const double refPrice, const double openPrice,
                        const double slInitial) const {
        switch(m_mode) {
        case TSL_CALC_POINTS: {
            const double p = PointOf(sym);
            return (p > 0.0) ? (m_stepValue * p) : 0.0;
        }
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
    //+------------------------------------------------------------------+
    //| Constructor                                                       |
    //+------------------------------------------------------------------+
    Trailing_Distance(IMarketData *md, IExecution *exec, IPositions *pos, const double trigger,
                      const double slDistance, const double stepValue,
                      const ENUM_TSL_CALC_MODE mode = TSL_CALC_POINTS, ITelemetry *telemetry = NULL)
        : m_md(md), m_exec(exec), m_pos(pos), m_telemetry(telemetry), m_trigger(trigger),
          m_slDistance(slDistance), m_stepValue(stepValue), m_mode(mode) {}

    //+------------------------------------------------------------------+
    //| Kiểm tra dependencies sẵn sàng                                   |
    //+------------------------------------------------------------------+
    bool IsReady() const { return (m_md != NULL && m_exec != NULL && m_pos != NULL); }

    //+------------------------------------------------------------------+
    //| Trailing cho một position cụ thể theo ticket                     |
    //+------------------------------------------------------------------+
    bool ManageSingle(const ulong ticket) {
        if(!IsReady()) {
            if(m_telemetry)
                m_telemetry.Error("Trailing_Distance::ManageSingle - Dependencies not ready");
            return false;
        }

        // Lấy thông tin position từ MT5
        if(!PositionSelectByTicket(ticket)) {
            if(m_telemetry)
                m_telemetry.Warn(StringFormat("Position ticket %I64u not found", ticket));
            return false;
        }

        // Đọc thông tin position
        const string sym       = PositionGetString(POSITION_SYMBOL);
        const bool isSell      = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL);
        const double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        const double slInit    = PositionGetDouble(POSITION_SL);
        const double curPrice  = PositionGetDouble(POSITION_PRICE_CURRENT);
        const double curSL     = PositionGetDouble(POSITION_SL);
        const double curTP     = PositionGetDouble(POSITION_TP);

        // 1) Lợi nhuận tạm tính từ open
        const double delta = isSell ? (openPrice - curPrice) : (curPrice - openPrice);

        // 2) Kiểm tra kích hoạt
        const double trig = CalcDistance(sym, m_trigger, openPrice, openPrice, slInit);
        if(trig <= 0.0 || delta < trig) return false;

        // 3) Khoảng cách SL cần giữ sau giá hiện tại
        const double dist = CalcDistance(sym, m_slDistance, curPrice, openPrice, slInit);
        if(dist <= 0.0) return false;

        // 4) Tính SL mong muốn
        double newSL = isSell ? (curPrice + dist) : (curPrice - dist);

        // 5) Áp dụng step cải thiện tối thiểu (nếu đã có SL)
        if(curSL != 0.0) {
            const double step = CalcDistance(sym, m_stepValue, curPrice, openPrice, slInit);
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
        newSL   = SnapToTick(sym, newSL);
        bool ok = m_exec.ModifyPositionByTicket(ticket, newSL, curTP);

        if(ok) {
            if(m_telemetry) {
                m_telemetry.Info(StringFormat(
                    "Trailing Distance executed for ticket %I64u: newSL=%.5f (old=%.5f)", ticket,
                    newSL, curSL));
            }
        } else {
            if(m_telemetry) {
                m_telemetry.Warn(StringFormat("Trailing Distance failed for ticket %I64u", ticket));
            }
        }

        return ok;
    }

    //+------------------------------------------------------------------+
    //| Trailing cho toàn bộ positions theo symbol & magic               |
    //+------------------------------------------------------------------+
    bool ManageAll(const string sym, const long magic) {
        if(!IsReady()) {
            if(m_telemetry)
                m_telemetry.Error("Trailing_Distance::ManageAll - Dependencies not ready");
            return false;
        }

        // Lấy danh sách tất cả positions theo symbol & magic
        PositionInfo positions[];
        const int total = m_pos.ListBySymbolMagic(sym, magic, positions);

        if(total <= 0) return false;

        bool anyTrailed = false;
        for(int i = 0; i < total; i++) {
            PositionInfo pi        = positions[i];

            const bool isSell      = pi.IsSell();
            const double openPrice = pi.price_open;
            const double slInit    = pi.sl;
            const double curPrice  = pi.price_current;
            const double curSL     = pi.sl;
            const double curTP     = pi.tp;

            // 1) Lợi nhuận tạm tính từ open
            const double delta = isSell ? (openPrice - curPrice) : (curPrice - openPrice);

            // 2) Kiểm tra kích hoạt
            const double trig = CalcDistance(sym, m_trigger, openPrice, openPrice, slInit);
            if(trig <= 0.0 || delta < trig) continue;

            // 3) Khoảng cách SL cần giữ sau giá hiện tại
            const double dist = CalcDistance(sym, m_slDistance, curPrice, openPrice, slInit);
            if(dist <= 0.0) continue;

            // 4) Tính SL mong muốn
            double newSL = isSell ? (curPrice + dist) : (curPrice - dist);

            // 5) Áp dụng step cải thiện tối thiểu (nếu đã có SL)
            if(curSL != 0.0) {
                const double step = CalcDistance(sym, m_stepValue, curPrice, openPrice, slInit);
                if(step > 0.0) {
                    const double improve = isSell ? (curSL - newSL) : (newSL - curSL);
                    if(improve < step) continue; // chưa cải thiện đủ
                }
            }

            // 6) Trail một chiều + hợp lệ so với giá hiện tại
            if(!isSell) {
                // BUY: SL chỉ tăng & luôn < giá hiện tại
                if(curSL > 0.0 && newSL <= curSL) continue;
                if(newSL >= curPrice) continue;
            } else {
                // SELL: SL chỉ giảm & luôn > giá hiện tại
                if(curSL > 0.0 && newSL >= curSL) continue;
                if(newSL <= curPrice) continue;
            }

            // 7) Snap theo tick và gửi lệnh sửa
            newSL   = SnapToTick(sym, newSL);
            bool ok = m_exec.ModifyPositionByTicket(pi.ticket, newSL, curTP);

            if(ok) {
                anyTrailed = true;
                if(m_telemetry) {
                    m_telemetry.Info(StringFormat(
                        "Trailing Distance executed for ticket %I64u: newSL=%.5f (old=%.5f)",
                        pi.ticket, newSL, curSL));
                }
            } else {
                if(m_telemetry) {
                    m_telemetry.Warn(
                        StringFormat("Trailing Distance failed for ticket %I64u", pi.ticket));
                }
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
