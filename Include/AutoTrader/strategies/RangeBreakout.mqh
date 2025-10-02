
#include <AutoTrader/domain/entities/TradeSignal.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ISignal.mqh>
#include <AutoTrader/utils/ChartObjects.mqh>

enum ENUM_RECORD_STATE {
    RECORD_STATE_NOT_STARTED = 0,
    RECORD_STATE_RECORDING   = 1,
    RECORD_STATE_FINISHED    = 2,
    RECORD_STATE_WAITING     = 3
};

struct RB_RecordRange {
    datetime timeStart, timeEnd, prevRecord;
    double priceHigh, priceLow;
    int sizePoints;
    ENUM_RECORD_STATE state;
    void Reset() {
        timeStart  = 0;
        timeEnd    = 0;
        prevRecord = 0;
        priceHigh  = 0.0;
        priceLow   = 0.0;
        sizePoints = 0;
        state      = RECORD_STATE_NOT_STARTED;
    }
    void Update(double high, double low, const double point) {
        if(high > 0 && (priceHigh == 0.0 || high > priceHigh)) priceHigh = high;
        if(low > 0 && (priceLow == 0.0 || low < priceLow)) priceLow = low;
        if(point > 0 && priceHigh > 0 && priceLow > 0)
            sizePoints = (int)MathRound((priceHigh - priceLow) / point);
    }
};

class RangeBreakout : public ISignal {
  private:
    IMarketData *m_md;
    int m_startHour, m_startMin, m_endHour, m_endMin;
    double m_minRangePts, m_maxRangePts, m_orderBufferPoints;
    RB_RecordRange m_cur;
    datetime m_lastDay;
    bool m_breakUsed;
    string m_sym;

    // NEW: tuỳ chọn xoá box cũ
    bool m_deleteOldBox;

    // Chart object cho hộp range
    ChartObject m_box;

    // --- helpers ------------------------------------------------------
    static datetime TodayAt(int h, int m) {
        MqlDateTime t;
        TimeCurrent(t);
        t.sec  = 0;
        t.hour = h;
        t.min  = m;
        return StructToTime(t);
    }
    // Bucket ngày (00:00) của một thời điểm
    static datetime DayBucket(datetime ts) { return (datetime)((int)(ts / 86400) * 86400); }
    // Tạo tên hộp theo ngày/symbol/tf: RB_15_20250930
    string MakeBoxName() const {
        // Ưu tiên ngày từ m_cur.timeStart; nếu chưa có, dùng m_lastDay; fallback TimeCurrent
        datetime d = m_cur.timeStart > 0 ? DayBucket(m_cur.timeStart)
                                         : (m_lastDay > 0 ? m_lastDay : DayBucket(TimeCurrent()));
        MqlDateTime md;
        TimeToStruct(d, md);
        return StringFormat("RB_%s_%04d%02d%02d", m_sym, md.year, md.mon, md.day);
    }

    void ClearBoxIfExists() {
        if(m_box.Name() != "" && m_box.Exists()) m_box.Delete();
    }

    void EnsureDailyReset() {
        const datetime dayBucket = (datetime)((int)(TimeCurrent() / 86400) * 86400);
        if(m_lastDay == 0 || m_lastDay != dayBucket) {
            m_lastDay = dayBucket;
            if(m_deleteOldBox) ClearBoxIfExists(); // <--- áp dụng cờ
            m_cur.Reset();
            m_breakUsed = false;
        }
    }

    void UpsertRangeBox(const color col, const int width, const bool back, const bool fill) {
        if(m_cur.timeStart <= 0 || m_cur.timeEnd <= 0 || m_cur.priceHigh <= 0
           || m_cur.priceLow <= 0)
            return;

        const string boxName = MakeBoxName();

        // Nếu chưa có đối tượng hoặc đã bị xoá trên chart ➜ tạo mới với TÊN CỤ THỂ
        if(m_box.Name() == "" || !m_box.Exists()) {
            if(!m_box.Rectangle(boxName, m_cur.timeStart, m_cur.priceHigh, m_cur.timeEnd,
                                m_cur.priceLow))
                return;
        } else {
            // Nếu tên hiện tại khác với tên chuẩn (qua ngày mới chẳng hạn) ➜ xoá và tạo lại để đúng
            // name
            if(m_box.Name() != boxName) {
                ClearBoxIfExists();
                if(!m_box.Rectangle(boxName, m_cur.timeStart, m_cur.priceHigh, m_cur.timeEnd,
                                    m_cur.priceLow))
                    return;
            } else {
                // Cùng một box ➜ cập nhật toạ độ
                m_box.UpdateRectangle(m_cur.timeStart, m_cur.priceHigh, m_cur.timeEnd,
                                      m_cur.priceLow);
            }
        }

        // Áp style mỗi lần upsert để đảm bảo đồng bộ
        m_box.SetColor(col);
        m_box.SetWidth(width);
        m_box.SetBack(back);
        m_box.SetFill(fill);
    }

    void DrawRangeBoxRecording() { UpsertRangeBox(clrAqua, 1, true, true); }
    void DrawRangeBoxFinal() { UpsertRangeBox(clrPaleGreen, 1, true, true); }

    void UpdateRecordState(const string sym, const ENUM_TIMEFRAMES tf) {
        EnsureDailyReset();
        const datetime now    = TimeCurrent();
        const datetime tStart = TodayAt(m_startHour, m_startMin);
        const datetime tEnd   = TodayAt(m_endHour, m_endMin);

        if(now < tStart) {
            if(m_cur.state != RECORD_STATE_NOT_STARTED
               && (m_cur.prevRecord == 0
                   || (int)(m_cur.prevRecord / 86400) != (int)(now / 86400))) {
                if(m_deleteOldBox) ClearBoxIfExists(); // <--- áp dụng cờ khi reset sớm
                m_cur.Reset();
                m_cur.state = RECORD_STATE_NOT_STARTED;
            }
            return;
        }

        if(now >= tStart && now <= tEnd) {
            if(m_cur.state != RECORD_STATE_RECORDING) {
                // Khi bắt đầu phiên mới, tuỳ chọn xoá box cũ (giúp chart sạch)
                if(m_deleteOldBox) ClearBoxIfExists(); // <--- áp dụng cờ khi bắt đầu record mới

                m_cur.state      = RECORD_STATE_RECORDING;
                m_cur.timeStart  = tStart;
                m_cur.timeEnd    = tEnd;
                m_cur.priceHigh  = 0.0;
                m_cur.priceLow   = 0.0;
                m_cur.sizePoints = 0;
                m_breakUsed      = false;
            }
            double o, h, l, c;
            if(m_md.OHLC(sym, tf, 1, o, h, l, c)) {
                const double p = m_md.Point(sym);
                m_cur.Update(h, l, p);
            }
            DrawRangeBoxRecording();
            return;
        }

        if(now > tEnd && m_cur.state == RECORD_STATE_RECORDING) {
            m_cur.state      = RECORD_STATE_FINISHED;
            m_cur.prevRecord = m_cur.timeStart;
            DrawRangeBoxFinal(); // khoá màu hộp
            return;
        }

        if(now > tEnd && m_cur.state == RECORD_STATE_FINISHED) {
            m_cur.state = RECORD_STATE_WAITING;
        }
    }

    bool RangeFilterOK(const string) const {
        if(m_cur.priceHigh <= 0 || m_cur.priceLow <= 0) return false;
        if(m_minRangePts > 0 && m_cur.sizePoints < m_minRangePts) return false;
        if(m_maxRangePts > 0 && m_cur.sizePoints > m_maxRangePts) return false;
        return true;
    }

  public:
    // NEW: tham số deleteOldBox (mặc định true)
    RangeBreakout(IMarketData *md, int startHour, int startMin, int endHour, int endMin,
                  double minRangePts = 0, double maxRangePts = 0, double orderBufferPoints = 0,
                  bool deleteOldBox = true)
        : m_md(md), m_startHour(startHour), m_startMin(startMin), m_endHour(endHour),
          m_endMin(endMin), m_minRangePts(minRangePts), m_maxRangePts(maxRangePts),
          m_orderBufferPoints(orderBufferPoints), m_lastDay(0), m_breakUsed(false), m_sym(""),
          m_deleteOldBox(deleteOldBox) {
        m_cur.Reset();
    }

    bool IsReady() const override { return m_md != NULL; }

    bool ShouldEnter(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &out) override {
        return false;
    }

    bool ShouldEnterMulti(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &out[]) override {
        // Mặc định trả về 2 phần tử (1 BUY, 1 SELL)
        ArrayResize(out, 2);
        if(m_sym == "") m_sym = sym;

        const datetime now    = TimeCurrent();
        const datetime tStart = TodayAt(m_startHour, m_startMin);
        const datetime tEnd   = TodayAt(m_endHour, m_endMin);

        if(now < tStart) {
            UpdateRecordState(sym, tf);
            return false;
        }

        if(now >= tStart && now <= tEnd) {
            UpdateRecordState(sym, tf);
            return false;
        }

        UpdateRecordState(sym, tf);

        if(!(m_cur.state == RECORD_STATE_FINISHED || m_cur.state == RECORD_STATE_WAITING))
            return false;
        if(m_breakUsed) return false;
        if(!RangeFilterOK(sym)) return false;
        if(m_cur.priceHigh <= 0.0 || m_cur.priceLow <= 0.0) return false;

        const double hi       = m_cur.priceHigh;
        const double lo       = m_cur.priceLow;

        out[0].isOrderPending = true;
        out[0].type           = TRADE_TYPE_BUY_STOP;
        out[0].sl             = lo;
        out[0].tp             = 0.0;
        out[0].price          = hi + m_orderBufferPoints * m_md.Point(sym); // buffer
        out[0].stopPoints     = m_cur.sizePoints;
        out[0].valid          = true;
        out[0].isSell         = false;
        out[0].comment        = StringFormat("RB_RANGE_BUY %.5f/%.5f", hi, lo);

        out[1].isOrderPending = true;
        out[1].type           = TRADE_TYPE_SELL_STOP;
        out[1].sl             = hi;
        out[1].tp             = 0.0;
        out[1].price          = lo - m_orderBufferPoints * m_md.Point(sym); // buffer
        out[1].stopPoints     = m_cur.sizePoints;
        out[1].valid          = true;
        out[1].isSell         = true;
        out[1].comment        = StringFormat("RB_RANGE_SELL %.5f/%.5f", hi, lo);

        m_breakUsed           = true;

        return true;
    }

    void GetRange(double &high, double &low, int &size, int &state) {
        high  = m_cur.priceHigh;
        low   = m_cur.priceLow;
        size  = m_cur.sizePoints;
        state = (int)m_cur.state;
    }
};
