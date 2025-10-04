//+------------------------------------------------------------------+
//|                                  Test_FullPipelineIntegration.mq5 |
//|                                  Copyright 2025, AutoTrader Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AutoTrader Team"
#property link "https://github.com/hailp-vn38/system-auto-trader"
#property version "1.00"
#property description "Integration test với real MT5 adapters"

#include <AutoTrader/adapters/mt5/Mt5ExecutionAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5MarketDataAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5PositionsAdapter.mqh>
#include <AutoTrader/app/Orchestrator.mqh>
#include <AutoTrader/exits/Exit_MAFlip.mqh>
#include <AutoTrader/handler/LoggingEventHandler.mqh>
#include <AutoTrader/risk/Risk_AllowOneOpen.mqh>
#include <AutoTrader/strategies/Strat_MA.mqh>
#include <AutoTrader/trailing/Trailing_BreakEven.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                            |
//+------------------------------------------------------------------+
input int InpMagic           = 99999; // Magic Number (use unique for testing)
input bool InpEnableTrailing = true;  // Enable trailing stop
input bool InpEnableExit     = true;  // Enable exit signal
input bool InpEnableRisk     = true;  // Enable risk management

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
Orchestrator *g_orch          = NULL;
IMarketData *g_md             = NULL;
IExecution *g_exec            = NULL;
IPositions *g_pos             = NULL;
ISignal *g_signal             = NULL;
IExitSignal *g_exit           = NULL;
ITrailing *g_trailing         = NULL;
IRisk *g_risk                 = NULL;
ITradeEventHandler *g_handler = NULL;

int g_totalTrades             = 0;
datetime g_startTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit() {
    Print("=====================================");
    Print("  INTEGRATION TEST - FULL PIPELINE");
    Print("=====================================");

    // Safety check - only run in tester or demo
    if(!MQLInfoInteger(MQL_TESTER)
       && AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
        Alert("Integration tests chỉ chạy trên TESTER hoặc DEMO account!");
        return INIT_FAILED;
    }

    g_startTime = TimeCurrent();

    // === 1. Setup Real Adapters ===
    g_md   = new Mt5MarketDataAdapter();
    g_exec = new Mt5ExecutionAdapter();
    g_pos  = new Mt5PositionsAdapter();

    // === 2. Setup Strategy ===
    g_signal = new Strat_MA(_Symbol, PERIOD_CURRENT);

    // === 3. Create Orchestrator ===
    g_orch = new Orchestrator(_Symbol, PERIOD_CURRENT, 5, InpMagic, g_signal, g_exec, g_md);

    // === 4. Setup Optional Components ===

    // Exit signal
    if(InpEnableExit) {
        g_exit = new Exit_MAFlip(_Symbol, PERIOD_CURRENT);
        g_exit.SetPositions(g_pos);
        g_orch.SetExitSignal(g_exit);
        Print("[✓] Exit signal enabled");
    }

    // Trailing stop
    if(InpEnableTrailing) {
        g_trailing = new Trailing_BreakEven(g_md, g_exec, g_pos, 50.0, 10.0);
        g_orch.SetTrailing(g_trailing);
        Print("[✓] Trailing stop enabled");
    }

    // Risk management
    if(InpEnableRisk) {
        g_risk = new Risk_AllowOneOpen(g_pos, 1);
        g_orch.SetRisk(g_risk);
        Print("[✓] Risk management enabled (max 1 position)");
    }

    // === 5. Setup Event Handler ===
    g_handler = new LoggingEventHandler();
    g_orch.SetEventHandler(g_handler);

    Print("Symbol: ", _Symbol);
    Print("Timeframe: ", EnumToString(PERIOD_CURRENT));
    Print("Magic: ", InpMagic);
    Print("Orchestrator ready: ", g_orch.IsReady());
    Print("=====================================");

    if(!g_orch.IsReady()) {
        Print("ERROR: Orchestrator not ready!");
        return INIT_FAILED;
    }

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("=====================================");
    Print("  INTEGRATION TEST SUMMARY");
    Print("=====================================");

    datetime endTime = TimeCurrent();
    int duration     = (int)(endTime - g_startTime);

    PrintFormat("Duration: %d seconds (%.1f minutes)", duration, duration / 60.0);
    PrintFormat("Total events processed: Check logs above");

    // Check final positions
    if(g_pos != NULL) {
        int posCount = g_pos.CountByMagic(_Symbol, InpMagic);
        PrintFormat("Final open positions: %d", posCount);
    }

    Print("Deinit reason: ", GetDeinitReasonText(reason));
    Print("=====================================");

    // Cleanup
    if(g_orch != NULL) {
        g_orch.OnDeinit();
        delete g_orch;
        g_orch = NULL;
    }

    if(g_signal != NULL) {
        delete g_signal;
        g_signal = NULL;
    }
    if(g_exit != NULL) {
        delete g_exit;
        g_exit = NULL;
    }
    if(g_trailing != NULL) {
        delete g_trailing;
        g_trailing = NULL;
    }
    if(g_risk != NULL) {
        delete g_risk;
        g_risk = NULL;
    }
    if(g_handler != NULL) {
        delete g_handler;
        g_handler = NULL;
    }
    if(g_md != NULL) {
        delete g_md;
        g_md = NULL;
    }
    if(g_exec != NULL) {
        delete g_exec;
        g_exec = NULL;
    }
    if(g_pos != NULL) {
        delete g_pos;
        g_pos = NULL;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    if(g_orch == NULL || !g_orch.IsReady()) return;

    // Main orchestrator logic
    g_orch.OnTick();
}

//+------------------------------------------------------------------+
//| Trade transaction event handler                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request,
                        const MqlTradeResult &result) {
    if(g_orch != NULL) { g_orch.OnTradeTransaction(trans, request, result); }
}

//+------------------------------------------------------------------+
//| Get deinit reason text                                            |
//+------------------------------------------------------------------+
string GetDeinitReasonText(int reason) {
    switch(reason) {
    case REASON_PROGRAM: return "Program stopped manually";
    case REASON_REMOVE: return "Expert removed from chart";
    case REASON_RECOMPILE: return "Program recompiled";
    case REASON_CHARTCHANGE: return "Chart changed";
    case REASON_CHARTCLOSE: return "Chart closed";
    case REASON_PARAMETERS: return "Input parameters changed";
    case REASON_ACCOUNT: return "Account changed";
    case REASON_TEMPLATE: return "Template changed";
    case REASON_INITFAILED: return "Initialization failed";
    case REASON_CLOSE: return "Terminal closed";
    default: return "Unknown reason (" + IntegerToString(reason) + ")";
    }
}
