// Include/AutoTrader/strategies/Strategy_RB_Facade.mqh

#include <AutoTrader/app/Orchestrator.mqh>
#include <AutoTrader/services/PendingOrderManager.mqh>
#include <AutoTrader/services/ClosePolicy.mqh>
#include <AutoTrader/utils/ChartObjects.mqh>  // để thay comment panel

struct RBFacadeConfig {
  int    minimumCandlesToTrade;
  bool   usePending;              // true: dùng lệnh chờ như bản cũ
  PendingConfig pend;
  CloseConfig   closeCfg;
  bool   drawRange;               // vẽ vùng range
};

class Strategy_RB_Facade {
  Orchestrator        *orc;
  IMarketData         *md;
  IPositions          *pos;
  IExecution          *exec;
  ISizer              *sizer;
  ITelemetry          *log;
  IStorage            *store;
  PendingOrderManager *pom;   // có thể NULL nếu usePending=false
  ClosePolicy         *cp;    // chính sách đóng theo thời gian
  RBFacadeConfig       cfg;

  string          sym;
  ENUM_TIMEFRAMES tf;
  long            magic;

public:
  Strategy_RB_Facade(Orchestrator *o, IMarketData *m, IPositions *p, IExecution *e,
                     ISizer *sz, ITelemetry *lg, IStorage *st,
                     const string s, ENUM_TIMEFRAMES t, long mg,
                     const RBFacadeConfig &c)
  : orc(o), md(m), pos(p), exec(e), sizer(sz), log(lg), store(st),
    pom(NULL), cp(NULL), cfg(c), sym(s), tf(t), magic(mg)
  {
    if(cfg.usePending)  pom = new PendingOrderManager(exec, md, sym, magic, cfg.pend);
    cp = new ClosePolicy(exec, pos, sym, magic, cfg.closeCfg);
  }

  ~Strategy_RB_Facade(){ if(pom) delete pom; if(cp) delete cp; }

  bool OnTick(){
    // 1) Orchestrator xử lý exit/trailing/entry (market)
    orc.OnTick();

    // 2) (tuỳ chọn) Pending order workflow giống bản cũ
    if(cfg.usePending){
      // a) Xóa pending theo thời gian
      int del_by_time = pom.DeleteAllByTime();
      if(log && del_by_time>0) log.Event("Pending.DeleteByTime", IntegerToString(del_by_time));

      // b) Nếu có tín hiệu mới → xóa pending cũ (tương tự ClosePositionBySignal cũ)
      //    Ở đây ta kiểm tra signal trực tiếp từ ISignal
      TradeSignal sig;
      bool hasSig = false;
      if(orc != NULL){ /* không lộ ISignal bên trong; bạn có thể truyền ISignal riêng vào Facade */
        // Phương án: bạn giữ 1 con trỏ ISignal riêng để đọc ShouldEnter mà không mở lệnh
      }
      // Tối giản: bỏ b) hoặc giữ cờ hasSig=false đến khi bạn truyền ISignal vào Facade
      pom.DeleteAllBySignal(hasSig);

      // c) Đặt pending buy/sell stop khi đủ điều kiện
      //    Lấy range từ signal (bạn đã expose GetRange ở RangeBreakoutSignal_System)
      //    Ở đây minh họa: nếu cần, bạn truyền vào Facade 1 pointer đến RangeBreakoutSignal_System
      //    rồi đọc priceHigh/priceLow -> gọi pom.PlaceStopByBreakout(...)
    }

    // 3) Đóng vị thế theo thời gian
    if(cp && cp.CloseByTime()){
      if(log) log.Event("CloseByTime", "Executed");
    }

    // 4) (tuỳ chọn) Vẽ chart
    if(cfg.drawRange){
      // giả định bạn có cách lấy hi/lo/size từ signal
      // ChartObject rect; rect.Rectangle("RBRange", tStart, hi, tEnd, lo);
    }

    return true;
  }
};
