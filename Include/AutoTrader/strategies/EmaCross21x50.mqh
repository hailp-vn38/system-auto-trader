// ==== Strategy: EMA(21) cắt EMA(50) ================================
// - Tạo 2 handle iMA (EMA), thêm lên chart bằng ChartIndicatorAdd
// - Dò cắt tại giá đóng cửa: cross up => BUY, cross down => SELL
#include <AutoTrader/domain/ports/ISignal.mqh>

class EmaCross21x50 : public ISignal {
private:
  string m_sym;
  ENUM_TIMEFRAMES m_tf;
  int m_hFast; // handle EMA21
  int m_hSlow; // handle EMA50

public:
  EmaCross21x50(const string sym, const ENUM_TIMEFRAMES tf)
      : m_sym(sym), m_tf(tf), m_hFast(INVALID_HANDLE), m_hSlow(INVALID_HANDLE) {
    m_hFast = iMA(m_sym, m_tf, 21, 0, MODE_EMA, PRICE_CLOSE);
    m_hSlow = iMA(m_sym, m_tf, 50, 0, MODE_EMA, PRICE_CLOSE);

    // Thêm lên chart chính (sub_window=0) để quan sát
    if(m_hFast != INVALID_HANDLE) ChartIndicatorAdd(0, 0, m_hFast);
    if(m_hSlow != INVALID_HANDLE) ChartIndicatorAdd(0, 0, m_hSlow);
  }

  // Hàm tiện ích: đọc 2 giá trị gần nhất
  bool Read2(const int handle, double &prev, double &curr) {
    if(handle == INVALID_HANDLE) return false;
    double buf[2];
    // CopyBuffer(handle, buffer_index(0 cho iMA), start=0, count=2, array)
    // buffer[0] = giá trị thanh hiện tại; buffer[1] = nến trước đó.
    // :contentReference[oaicite:1]{index=1}
    if(CopyBuffer(handle, 0, 0, 2, buf) != 2) return false;
    curr = buf[0];
    prev = buf[1];
    return (curr != EMPTY_VALUE && prev != EMPTY_VALUE);
  }

  bool ShouldEnter(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &out) override {
    if(sym != m_sym || tf != m_tf) return false;

    double f_prev, f_curr, s_prev, s_curr;
    if(!Read2(m_hFast, f_prev, f_curr)) return false;
    if(!Read2(m_hSlow, s_prev, s_curr)) return false;

    // Cross detection:
    bool crossUp   = (f_prev <= s_prev) && (f_curr > s_curr);
    bool crossDown = (f_prev >= s_prev) && (f_curr < s_curr);

    if(!(crossUp || crossDown)) return (out.valid = false);

    out.valid          = true;
    out.type           = crossUp ? TRADE_TYPE_BUY : TRADE_TYPE_SELL;
    out.stopPoints     = 0; // demo; nếu bạn có IRisk/ITargets sẽ tính SL/TP
    out.sl             = 0.0;
    out.tp             = 0.0;
    out.isSell         = crossDown;
    out.isOrderPending = false; // lệnh thị trường
    return true;
  }
};