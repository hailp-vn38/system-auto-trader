//+------------------------------------------------------------------+
//| RangeBreakoutSignal_System.mqh - ISignal adapter (system core)   |
//| Ported from custom RangeBreakoutSignal to use ISignal            |
//| Logic: record a time-window range, then enter on breakout        |
//+------------------------------------------------------------------+

// Include/AutoTrader/strategies/RangeBreakoutSignal_System.mqh

#include <AutoTrader/domain/entities/TradeSignal.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ISignal.mqh>

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
  int m_minRangePts, m_maxRangePts, m_breakBufferPts;
  RB_RecordRange m_cur;
  datetime m_lastDay;
  bool m_breakUsed;

  static datetime TodayAt(int h, int m) {
    MqlDateTime t;
    TimeCurrent(t);
    t.sec  = 0;
    t.hour = h;
    t.min  = m;
    return StructToTime(t);
  }

  void EnsureDailyReset() {
    const datetime dayBucket = (datetime)((int)(TimeCurrent() / 86400) * 86400);
    if(m_lastDay == 0 || m_lastDay != dayBucket) {
      m_lastDay = dayBucket;
      m_cur.Reset();
      m_breakUsed = false;
    }
  }

  void UpdateRecordState(const string sym, const ENUM_TIMEFRAMES tf) {
    EnsureDailyReset();
    const datetime now    = TimeCurrent();
    const datetime tStart = TodayAt(m_startHour, m_startMin);
    const datetime tEnd   = TodayAt(m_endHour, m_endMin);

    if(now < tStart) {
      if(m_cur.state != RECORD_STATE_NOT_STARTED
         && (m_cur.prevRecord == 0 || (int)(m_cur.prevRecord / 86400) != (int)(now / 86400))) {
        m_cur.Reset();
        m_cur.state = RECORD_STATE_NOT_STARTED;
      }
      return;
    }

    if(now >= tStart && now <= tEnd) {
      if(m_cur.state != RECORD_STATE_RECORDING) {
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
      return;
    }

    if(now > tEnd && m_cur.state == RECORD_STATE_RECORDING) {
      m_cur.state      = RECORD_STATE_FINISHED;
      m_cur.prevRecord = m_cur.timeStart;
      return;
    }
    if(now > tEnd && m_cur.state == RECORD_STATE_FINISHED) { m_cur.state = RECORD_STATE_WAITING; }
  }

  bool RangeFilterOK(const string sym) const {
    if(m_cur.priceHigh <= 0 || m_cur.priceLow <= 0) return false;
    if(m_minRangePts > 0 && m_cur.sizePoints < m_minRangePts) return false;
    if(m_maxRangePts > 0 && m_cur.sizePoints > m_maxRangePts) return false;
    return true;
  }

public:
  RangeBreakout(IMarketData *md, int startHour, int startMin, int endHour, int endMin,
                             int minRangePts = 0, int maxRangePts = 0, int breakBufferPts = 0)
      : m_md(md), m_startHour(startHour), m_startMin(startMin), m_endHour(endHour),
        m_endMin(endMin), m_minRangePts(minRangePts), m_maxRangePts(maxRangePts),
        m_breakBufferPts(breakBufferPts), m_lastDay(0), m_breakUsed(false) {
    m_cur.Reset();
  }

  bool ShouldEnter(string sym, ENUM_TIMEFRAMES tf, TradeSignal &out) override {
    out.valid = false;

    UpdateRecordState(sym, tf);
    if(!(m_cur.state == RECORD_STATE_FINISHED || m_cur.state == RECORD_STATE_WAITING)) return false;
    if(m_breakUsed) return false;
    if(!RangeFilterOK(sym)) return false;

    double bid, ask;
    if(!m_md.LastBidAsk(sym, bid, ask)) return false;
    const double mid = 0.5 * (bid + ask);
    const double p   = m_md.Point(sym);
    const double buf = (m_breakBufferPts > 0 && p > 0) ? (m_breakBufferPts * p) : 0.0;

    const double hi = m_cur.priceHigh, lo = m_cur.priceLow;

    if(mid > hi + buf) {
      out.orderType  = ORDER_TYPE_BUY;
      out.sl         = lo;
      out.tp         = 0.0;
      out.stopPoints = m_cur.sizePoints;
      out.valid      = true;
      m_breakUsed    = true;
      return true;
    }
    if(mid < lo - buf) {
      out.orderType  = ORDER_TYPE_SELL;
      out.sl         = hi;
      out.tp         = 0.0;
      out.stopPoints = m_cur.sizePoints;
      out.valid      = true;
      m_breakUsed    = true;
      return true;
    }
    return false;
  }

  void GetRange(double &high, double &low, int &size, int &state) {
    high  = m_cur.priceHigh;
    low   = m_cur.priceLow;
    size  = m_cur.sizePoints;
    state = (int)m_cur.state;
  }
};
