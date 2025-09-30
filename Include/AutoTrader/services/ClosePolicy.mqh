//+------------------------------------------------------------------+
//| Include/AutoTrader/services/ClosePolicy.mqh                      |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/ports/IExecution.mqh>
#include <AutoTrader/domain/ports/IPositions.mqh>

enum ENUM_CLOSE_POSITION_TYPE { CLOSE_POSITION_NONE, CLOSE_POSITION_TODAY, CLOSE_POSITION_NEXT_DAY };

struct CloseConfig {
  ENUM_CLOSE_POSITION_TYPE type;
  string timeStr; // "HH:MM"

  // (tùy chọn) constructor mặc định để có giá trị an toàn
  void CloseConfig() { type = CLOSE_POSITION_NONE; timeStr = ""; }
};

class ClosePolicy {
  IExecution *exec;
  IPositions *pos;
  string      sym;
  long        magic;
  CloseConfig cfg;

public:
  // ❌ Tránh: member-initializer cfg(c) -> gây lỗi "1 passed, but 0 requires"
  // ✅ Đúng: gán trong thân ctor
  ClosePolicy(IExecution *e, IPositions *p, const string s, long mg, const CloseConfig &c)
  : exec(e), pos(p), sym(s), magic(mg)
  {
    cfg = c; // MQL5 hỗ trợ copy assignment cho struct
  }

  bool CloseByTime(){
    if(cfg.type==CLOSE_POSITION_NONE) return false;
    if(cfg.timeStr=="") return false;

    const datetime t = StringToTime(cfg.timeStr);
    if(TimeCurrent() < t) return false;

    // Bản tối giản: đóng tất cả vị thế theo symbol+magic
    if(cfg.type==CLOSE_POSITION_TODAY){
      return (exec.CloseAllBySymbolMagic(sym, magic) > 0);
    }
    if(cfg.type==CLOSE_POSITION_NEXT_DAY){
      // Nếu cần đúng "ngày hôm qua", hãy thêm IHistory để lọc; ở đây đóng tất cả cho gọn
      return (exec.CloseAllBySymbolMagic(sym, magic) > 0);
    }
    return false;
  }
};
