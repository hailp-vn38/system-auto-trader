
#include "App_Config.mqh"
#include "App_Constants.mqh"

#include <AutoTrader/adapters/mt5/Mt5ExecutionAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5MarketDataAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5OrdersAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5PositionsAdapter.mqh>
#include <AutoTrader/adapters/storage/HttpApiStorageBatch.mqh>
#include <AutoTrader/adapters/storage/SQLiteStorage.mqh>
#include <AutoTrader/adapters/telemetry/PrintLogger.mqh>
#include <AutoTrader/app/Orchestrator.mqh>
#include <AutoTrader/domain/policies/MultiModeSizer.mqh>
#include <AutoTrader/domain/policies/Risk_AllowOneOpen.mqh>
#include <AutoTrader/domain/ports/ITargets.mqh>
#include <AutoTrader/exits/ExitPositionByTime.mqh>
#include <AutoTrader/handler/RangeBreakoutHandler.mqh>
#include <AutoTrader/strategies/RangeBreakout.mqh>
#include <AutoTrader/targets/MultisTargetMode.mqh>
#include <AutoTrader/trailing/Trailing_BreakEven.mqh>
#include <AutoTrader/utils/BarTimer.mqh>

Mt5MarketDataAdapter *g_md;
Mt5ExecutionAdapter *g_exec;
Mt5PositionsAdapter *g_pos;
Mt5OrdersAdapter *g_orders;

Risk_AllowOneOpen *g_risk;
MultiModeSizer *g_sizer;

RangeBreakout *g_sig;

MultisTargetMode *g_targets;
ExitPositionByTime *g_exit;
PrintLogger *g_log;

ITrailing *g_trail;

RangeBreakoutHandler *handler;
Orchestrator *g_app;
BarTimer *g_barTimer;

int OnInit() {
  // Khởi tạo Adapter
  g_md     = new Mt5MarketDataAdapter();
  g_exec   = new Mt5ExecutionAdapter(InpMagic, 0);
  g_pos    = new Mt5PositionsAdapter();
  g_orders = new Mt5OrdersAdapter();

  // set size cố định 0.2
  g_sizer = new MultiModeSizer(InpLotValue, InpLotMode);

  // Cho phép trade
  g_risk = new Risk_AllowOneOpen(g_pos, 1);

  // Khởi tạo chiến lược open/close
  g_sig = new RangeBreakout(g_md, InpTimeStartHour, InpTimeStartMin, InpTimeEndHour, InpTimeEndMin,
                            InpMinRangePoints, InpMaxRangePoints, InpOrderBufferPoints,
                            InpDeleteOldBox);
  if(!g_sig.IsReady()) {
    Print("Signal not ready");
    return (INIT_FAILED);
  }

  g_exit = new ExitPositionByTime(InpClosePositionType, InpDailyPositionCloseTime);

  // Khởi tạo tính stoplost/takeprofit
  g_targets = new MultisTargetMode(g_md, InpTargetValue, InpTargetMode, InpStopValue,
                                   InpStopLossMode);

  // Khởi tạo Trailing
  g_trail = new Trailing_BreakEven(g_md, g_exec, g_pos, 0.7, 0.1, TSL_CALC_PERCENT);

  // Khởi tạo handler sự kiện (tuỳ chọn)
  handler = new RangeBreakoutHandler(g_exec, g_orders, g_pos, _Symbol, InpMagic,
                                     InpClosePositionsOnNewSignal);

  // Common print
  g_log = new PrintLogger();

  // Orchestrator: bắt buộc (signal, exec, marketdata)
  g_app      = new Orchestrator(_Symbol, _Period, 5, InpMagic, g_sig, g_exec, g_md);

  g_barTimer = new BarTimer(_Symbol, _Period);

  g_app.SetSizer(g_sizer);
  g_app.SetTargets(g_targets);
  // g_app.SetRisk(g_risk);
  g_app.SetExitSignal(g_exit);
  g_app.SetTrailing(g_trail);
  g_app.SetEventHandler(handler);

  if(g_log) g_log.Info("EA Init OK");
  Comment("EMA(21/50) demo running..."); // quick HUD
  return (INIT_SUCCEEDED);
}

void OnTick() {
  // Chỉ chạy khi có nến mới
  if(g_barTimer.IsNewBar() && g_app != NULL) { g_app.OnTick(); }
}

//+------------------------------------------------------------------+
//| Trade transaction event handler                                   |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request,
                        const MqlTradeResult &result) {
  if(g_app != NULL) { g_app.OnTradeTransaction(trans, request, result); }
}

void OnDeinit(const int reason) {
  if(g_app) g_app.OnDeinit();
  delete g_app;
  delete handler;
  delete g_log;
  delete g_trail;
  delete g_exit;
  delete g_sig;
  delete g_sizer;
  delete g_risk;
  delete g_exec;
  delete g_md;
  delete g_pos;
  delete g_barTimer;
}
