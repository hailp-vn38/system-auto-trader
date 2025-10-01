// Include/AutoTrader/exits/Exit_EmaCross10x20.mqh


#include <AutoTrader/domain/ports/IExitSignal.mqh>

// Exit theo 2 EMA (10/20): đóng khi fast (10) cắt NGƯỢC chiều position
class Exit_EmaCross10x20 : public IExitSignal {
private:
  string          m_sym;
  ENUM_TIMEFRAMES m_tf;
  int             m_hFast;   // iMA(10, EMA, PRICE_CLOSE)
  int             m_hSlow;   // iMA(20, EMA, PRICE_CLOSE)

  // Đọc 2 giá trị gần nhất của 1 buffer (curr = [0], prev = [1])
  bool Read2(const int handle, double &prev, double &curr){
    if(handle==INVALID_HANDLE) return false;
    double buf[2];
    // Copy từ “hiện tại -> quá khứ”; start=0 là thanh hiện tại, count=2
    if(CopyBuffer(handle, 0, 0, 2, buf)!=2) return false; // Docs: CopyBuffer. :contentReference[oaicite:0]{index=0}
    curr = buf[0];
    prev = buf[1];
    return (curr!=EMPTY_VALUE && prev!=EMPTY_VALUE);
  }

public:
  Exit_EmaCross10x20(const string sym, const ENUM_TIMEFRAMES tf)
  : m_sym(sym), m_tf(tf), m_hFast(INVALID_HANDLE), m_hSlow(INVALID_HANDLE)
  {
    // iMA trả về HANDLE; đọc bằng CopyBuffer — không trả dữ liệu trực tiếp. :contentReference[oaicite:1]{index=1}
    m_hFast = iMA(m_sym, m_tf, 10, 0, MODE_EMA, PRICE_CLOSE);
    m_hSlow = iMA(m_sym, m_tf, 20, 0, MODE_EMA, PRICE_CLOSE);
  }

  ~Exit_EmaCross10x20(){
    if(m_hFast!=INVALID_HANDLE) IndicatorRelease(m_hFast);
    if(m_hSlow!=INVALID_HANDLE) IndicatorRelease(m_hSlow);
  }

  // Đúng khi fast cắt NGƯỢC chiều position mở hiện tại
  bool ShouldExit(const string sym, const ENUM_TIMEFRAMES tf, const long magic) override {
    if(sym!=m_sym || tf!=m_tf) return false;
    if(m_positions==NULL) return false;

    // Lấy position hiện tại theo symbol+magic
    PositionInfo pos;
    if(!m_positions.FirstBySymbolMagic(m_sym, magic, pos)) return false;

    // Đọc EMA(10) & EMA(20) hai điểm gần nhất
    double f_prev, f_curr, s_prev, s_curr;
    if(!Read2(m_hFast, f_prev, f_curr)) return false;
    if(!Read2(m_hSlow, s_prev, s_curr)) return false;

    // Cross logic:
    const bool crossUp   = (f_prev <= s_prev) && (f_curr >  s_curr);
    const bool crossDown = (f_prev >= s_prev) && (f_curr <  s_curr);

    // Nếu đang BUY -> thoát khi crossDown (EMA10 cắt xuống EMA20)
    // Nếu đang SELL -> thoát khi crossUp   (EMA10 cắt lên   EMA20)
    if(pos.type == POSITION_TYPE_BUY)  return crossDown;
    if(pos.type == POSITION_TYPE_SELL) return crossUp;
    return false;
  }

  // Ví dụ: nếu có cross ngược, cũng đề nghị huỷ pending (tuỳ chiến lược)
  bool ShouldCancelOrders(const string sym, const ENUM_TIMEFRAMES tf, const long magic) override {
    if(sym!=m_sym || tf!=m_tf) return false;

    // Tái sử dụng cùng điều kiện exit:
    PositionInfo pos;
    if(!m_positions || !m_positions.FirstBySymbolMagic(m_sym, magic, pos)) return false;

    double f_prev, f_curr, s_prev, s_curr;
    if(!Read2(m_hFast, f_prev, f_curr)) return false;
    if(!Read2(m_hSlow, s_prev, s_curr)) return false;

    const bool crossUp   = (f_prev <= s_prev) && (f_curr >  s_curr);
    const bool crossDown = (f_prev >= s_prev) && (f_curr <  s_curr);

    if(pos.type == POSITION_TYPE_BUY)  return crossDown;
    if(pos.type == POSITION_TYPE_SELL) return crossUp;
    return false;
  }
};
