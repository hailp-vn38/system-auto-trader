// Include/AutoTrader/services/PendingOrderManager.mqh

#include <AutoTrader/domain/ports/IExecution.mqh>
#include <AutoTrader/domain/ports/IOrders.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>

struct PendingConfig {
  double  orderBufferPoints;
  bool    deleteRemainingOrderOnFill;   // (chưa dùng ở đây – có thể nối OnTradeTransaction)
  bool    enableDailyOrderDeletion;
  string  dailyOrderDeletionTime;       // "HH:MM"
  bool    closePendingsOnNewSignal;
};

class PendingOrderManager {
  IExecution  *exec;
  IOrders     *ord;
  IMarketData *md;
  string       sym; long magic;
  PendingConfig cfg;

  double Buffer() const {
    const double p = md ? md.Point(sym) : SymbolInfoDouble(sym, SYMBOL_POINT);
    return (cfg.orderBufferPoints>0 && p>0) ? (cfg.orderBufferPoints*p) : 0.0;
  }

public:
  PendingOrderManager(IExecution *ex, IOrders *o, IMarketData *m,
                      const string s, long mg, const PendingConfig &c)
  : exec(ex), ord(o), md(m), sym(s), magic(mg) { cfg = c; }

  // Đặt BuyStop/SellStop theo price tín hiệu (tự cộng buffer)
  bool PlaceStopByBreakout(bool isBuy, double triggerPrice, double sl, double tp,
                           double volume, ulong &ticket_out)
  {
    double px = isBuy ? (triggerPrice + Buffer()) : (triggerPrice - Buffer());
    return exec.PlaceStop(sym, /*isSell=*/!isBuy, volume, px, sl, tp, magic, ticket_out);
  }

  // Đặt Limit theo pullback
  bool PlaceLimit(bool isBuy, double limitPrice, double sl, double tp,
                  double volume, ulong &ticket_out)
  {
    return exec.PlaceLimit(sym, /*isSell=*/!isBuy, volume, limitPrice, sl, tp, magic, ticket_out);
  }

  // Xoá theo thời gian HH:MM
  int DeleteByTime(){
    if(!cfg.enableDailyOrderDeletion || cfg.dailyOrderDeletionTime=="") return 0;
    datetime t = StringToTime(cfg.dailyOrderDeletionTime);
    if(TimeCurrent() < t) return 0;
    return exec.DeleteAllPendingsBySymbolMagic(sym, magic);
  }

  // Xoá khi có tín hiệu mới (ví dụ range đảo chiều)
  int DeleteBySignal(bool hasSignal){
    if(!cfg.closePendingsOnNewSignal || !hasSignal) return 0;
    return exec.DeleteAllPendingsBySymbolMagic(sym, magic);
  }

  // Tránh trùng lệnh: kiểm tra đã có order cùng side chưa
  bool HasAnyPending(){
    OrderInfo tmp[1];
    return ord && (ord.FirstBySymbolMagic(sym, magic, tmp[0]));
  }
};
