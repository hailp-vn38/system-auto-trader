//+------------------------------------------------------------------+
//| Include/AutoTrader/app/Orchestrator.mqh                          |
//+------------------------------------------------------------------+


#include <AutoTrader/domain/entities/TradeSignal.mqh>
#include <AutoTrader/domain/ports/IExecution.mqh>
#include <AutoTrader/domain/ports/IExitSignal.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/IOrders.mqh>
#include <AutoTrader/domain/ports/IPositions.mqh>
#include <AutoTrader/domain/ports/IRisk.mqh>
#include <AutoTrader/domain/ports/ISignal.mqh>
#include <AutoTrader/domain/ports/ISizer.mqh>
#include <AutoTrader/domain/ports/IStorage.mqh>
#include <AutoTrader/domain/ports/ITargets.mqh>
#include <AutoTrader/domain/ports/ITelemetry.mqh>
#include <AutoTrader/domain/ports/ITrailing.mqh>   // <-- BẮT BUỘC: thêm dòng này

class Orchestrator {
  ISignal     *signal;
  IExitSignal *exitSig;
  ITrailing   *trailer;   // dùng ITrailing sau khi đã include
  IRisk       *risk;
  ISizer      *sizer;
  IExecution  *exec;
  IMarketData *md;
  ITargets    *targets;
  ITelemetry  *log;
  IStorage    *store;
  IOrders     *orders;

  string          sym;
  ENUM_TIMEFRAMES tf;
  int             deviation;
  long            magic;

public:
  Orchestrator(string symbol, ENUM_TIMEFRAMES timeframe, int dev, long mg,
               ISignal *sg, IExitSignal *exs, ITrailing *tr, IRisk *rk, ISizer *sz,
               ITargets *tg, IExecution *ex, IMarketData *market, IOrders *ords,
               ITelemetry *logger=NULL, IStorage *storage=NULL)
  : sym(symbol), tf(timeframe), deviation(dev), magic(mg),
    signal(sg), exitSig(exs), trailer(tr), risk(rk), sizer(sz),
    exec(ex), md(market), targets(tg), log(logger), store(storage), orders(ords) {}

  void OnTick(){
    // Exit positions
    if(exitSig && exitSig.ShouldExit(sym, tf, magic)){
      int closed = exec.CloseAllBySymbolMagic(sym, magic);
      if(log) log.Event("CloseAll.Positions", StringFormat("sym=%s magic=%I64d closed=%d", sym, magic, closed));
      if(store && closed>0){ store.SaveTradeClose(sym, magic, 0, 0.0, 0.0, TimeCurrent(), "ExitSignal"); store.Flush(); }
      if(closed>0) return;
    }

    // Trailing
    if(trailer && trailer.Manage(sym, tf, magic)){
      if(log) log.Event("Trailing", StringFormat("sym=%s magic=%I64d", sym, magic));
    }

    // Pending orders -> ask ExitSignal if should cancel
    if(orders && exitSig){
      OrderInfo tmp[1];
      if(orders.FirstBySymbolMagic(sym, magic, tmp[0])){
        if(exitSig.ShouldCancelOrders(sym, tf, magic)){
          exec.DeleteAllPendingsBySymbolMagic(sym, magic);
          if(log) log.Event("CancelPendings", StringFormat("sym=%s magic=%I64d", sym, magic));
          return;
        }
      }
    }

    // Entry
    TradeSignal sig;
    if(!signal || !signal.ShouldEnter(sym, tf, sig)) return;
    if(!sig.valid) return;
    if(!risk || !risk.AllowTrade(sym, magic)) return;

    double bid=0.0, ask=0.0; if(md) md.LastBidAsk(sym, bid, ask);
    const bool   isSell    = (sig.orderType==ORDER_TYPE_SELL);
    const double entrySnap = isSell ? bid : ask;

    double sl_final = sig.sl, tp_final = sig.tp;
    if(targets) targets.Compute(sym, isSell, entrySnap, sig.sl, sl_final, tp_final);

    const double lots = sizer ? sizer.Lots(sym, sig.stopPoints, 0.10, magic) : 0.10;

    if(sig.execType==SIG_EXEC_MARKET){
      ulong tkt=0;
      if(exec.PlaceMarket(sym, sig.orderType, lots, sl_final, tp_final, tkt, deviation, magic)){
        if(log) log.Event("OrderSendOK(Market)", StringFormat("ticket=%I64u", tkt));
        if(store) store.SaveTradeOpen(sym, magic, tkt, sig.orderType, lots, entrySnap, sl_final, tp_final, TimeCurrent());
      } else {
        if(log) log.Error("OrderSend failed (Market)");
      }
    } else { // SIG_EXEC_ORDER
      ulong ot=0;
      const double trig = (sig.triggerPrice>0 ? sig.triggerPrice : entrySnap);
      if(sig.orderKind==ORDER_KIND_STOP){
        if(exec.PlaceStop(sym, isSell, lots, trig, sl_final, tp_final, magic, ot)){
          if(log) log.Event("OrderPlace(Stop)", StringFormat("ticket=%I64u", ot));
          if(store) store.SaveOrderOpen(sym, magic, ot, sig.orderType, lots, trig, sl_final, tp_final, TimeCurrent());
        } else if(log) log.Error("OrderPlace failed (Stop)");
      } else {
        if(exec.PlaceLimit(sym, isSell, lots, trig, sl_final, tp_final, magic, ot)){
          if(log) log.Event("OrderPlace(Limit)", StringFormat("ticket=%I64u", ot));
          if(store) store.SaveOrderOpen(sym, magic, ot, sig.orderType, lots, trig, sl_final, tp_final, TimeCurrent());
        } else if(log) log.Error("OrderPlace failed (Limit)");
      }
    }
  }

  void OnDeinit(){ if(store) store.Flush(); }
};
