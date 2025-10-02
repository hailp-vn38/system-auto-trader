
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
#include <AutoTrader/domain/policies/Risk_AllowAll.mqh>
#include <AutoTrader/domain/ports/ITargets.mqh>
#include <AutoTrader/exits/ExitTargets_MultiMode.mqh>
#include <AutoTrader/exits/Exit_MAFlip.mqh>
#include <AutoTrader/sizers/Sizer_FixedLot.mqh>
#include <AutoTrader/strategies/Strat_MA.mqh>
#include <AutoTrader/trailing/Trailing_BreakEven.mqh>

Mt5MarketDataAdapter *g_md;
Mt5ExecutionAdapter *g_exec;
Mt5PositionsAdapter *g_pos;
Risk_AllowAll *g_risk;
Sizer_FixedLot *g_sizer;
Strat_MA *g_sig;
Exit_MAFlip *g_exit;
PrintLogger *g_log;
IStorage *g_store;
ITargets *g_targets;
ITrailing *g_trail;
Orchestrator *g_app;

int OnInit() {
    g_md    = new Mt5MarketDataAdapter();
    g_exec  = new Mt5ExecutionAdapter();
    g_pos   = new Mt5PositionsAdapter();
    g_risk  = new Risk_AllowAll();
    g_sizer = new Sizer_FixedLot(InpLot);
    g_sig   = new Strat_MA(g_md, InpFastMA, InpSlowMA, InpSLPoints, InpTPPoints);
    g_exit  = InpUseExitFlipMA ? new Exit_MAFlip(g_md, InpFastMA, InpSlowMA) : NULL;
    // g_trail = InpUseTrailingATR ? new Trailing_ATR(g_md, g_exec, InpATRPeriod, InpATRMult) : NULL;
    g_log     = new PrintLogger();
    g_targets = new ExitTargets_MultiMode(g_md, 2.0, CALC_MODE_FACTOR, 0.0, CALC_MODE_DEFAULT);
    g_trail   = new Trailing_BreakEven(g_md, g_exec, g_pos, 0.7, 0.1, TSL_CALC_PERCENT);

    g_app = new Orchestrator(_Symbol, PERIOD_M15, InpDeviation, InpMagic, g_sig, g_exit, g_trail,
                             g_risk, g_sizer, g_targets, g_exec, g_md, g_pos, g_log, g_store);
    if(g_log) g_log.Info("EA Init OK");
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
