
#property strict

#include "App_Config.mqh"
#include "App_Constants.mqh"

#include <AutoTrader/adapters/mt5/Mt5ExecutionAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5MarketDataAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5PositionsAdapter.mqh>
#include <AutoTrader/adapters/storage/HttpApiStorageBatch.mqh>
#include <AutoTrader/adapters/storage/SQLiteStorage.mqh>
#include <AutoTrader/adapters/telemetry/PrintLogger.mqh>
#include <AutoTrader/app/Orchestrator.mqh>
#include <AutoTrader/domain/policies/Risk_AllowOneOpen.mqh>
#include <AutoTrader/domain/policies/Sizer_FixedLot.mqh>
#include <AutoTrader/domain/ports/ITargets.mqh>
#include <AutoTrader/exits/ExitTargets_MultiMode.mqh>
#include <AutoTrader/exits/Exit_EmaCross10x20.mqh>
#include <AutoTrader/strategies/EmaCross21x50.mqh>
#include <AutoTrader/trailing/Trailing_BreakEven.mqh>

Mt5MarketDataAdapter *g_md;
Mt5ExecutionAdapter *g_exec;
Mt5PositionsAdapter *g_pos;
Risk_AllowOneOpen *g_risk;
Sizer_FixedLot *g_sizer;
EmaCross21x50 *g_sig;
Exit_EmaCross10x20 *g_exit;
PrintLogger *g_log;
IStorage *g_store;
ITargets *g_targets;
ITrailing *g_trail;
Orchestrator *g_app;

int OnInit() {
  // Khởi tạo Adapter
  g_md   = new Mt5MarketDataAdapter();
  g_exec = new Mt5ExecutionAdapter();
  g_pos  = new Mt5PositionsAdapter();

  // set size cố định 0.2
  g_sizer = new Sizer_FixedLot(0.2);

  // Cho phép trade
  g_risk = new Risk_AllowOneOpen(g_pos, 1);

  // Khởi tạo chiến lược open/close
  g_sig  = new EmaCross21x50(_Symbol, _Period);
  g_exit = new Exit_EmaCross10x20(_Symbol, (ENUM_TIMEFRAMES)_Period);
  g_exit.SetPositions(g_pos);

  // Khởi tạo tính stoplost/takeprofit

  g_targets = NULL;
  //   g_targets = new ExitTargets_MultiMode(g_md, 2.0, CALC_MODE_FACTOR, 0.0, CALC_MODE_DEFAULT);

  // Khởi tạo Trailing
  g_trail = NULL;
  //   g_trail = new Trailing_BreakEven(g_md, g_exec, g_pos, 0.7, 0.1, TSL_CALC_PERCENT);

  // Common print
  g_log = new PrintLogger();

  // Orchestrator: bắt buộc (signal, exec, marketdata)
  g_app = new Orchestrator(_Symbol, _Period, 5, 12345, g_sig, g_exec, g_md);

  g_app.SetSizer(g_sizer);
  g_app.SetRisk(g_risk);
  g_app.SetExitSignal(g_exit);

  if(g_log) g_log.Info("EA Init OK");
  Comment("EMA(21/50) demo running..."); // quick HUD
  return (INIT_SUCCEEDED);
}

void OnTick() {
  if(g_app) g_app.OnTick();
}

void OnDeinit(const int reason) {
  if(g_app) g_app.OnDeinit();
  delete g_app;
  delete g_store;
  delete g_log;
  delete g_trail;
  delete g_exit;
  delete g_sig;
  delete g_sizer;
  delete g_risk;
  delete g_exec;
  delete g_md;
}
