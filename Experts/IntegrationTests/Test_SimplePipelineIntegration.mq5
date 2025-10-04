//+------------------------------------------------------------------+
//|                                  Test_SimplePipelineIntegration.mq5 |
//|                                  Copyright 2025, AutoTrader Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AutoTrader Team"
#property link "https://github.com/hailp-vn38/system-auto-trader"
#property version "1.00"
#property description "Simple integration test with minimal dependencies"

#include <AutoTrader/adapters/mt5/Mt5ExecutionAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5MarketDataAdapter.mqh>
#include <AutoTrader/app/Orchestrator.mqh>
#include <AutoTrader/testing/SimpleLoggingHandler.mqh>
#include <AutoTrader/testing/mocks/MockSignal.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                            |
//+------------------------------------------------------------------+
input int InpMagic = 77777; // Magic Number (use unique for testing)

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
Orchestrator *g_orch          = NULL;
IMarketData *g_md             = NULL;
IExecution *g_exec            = NULL;
MockSignal *g_signal          = NULL;
ITradeEventHandler *g_handler = NULL;

int g_totalTicks              = 0;
datetime g_startTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit() {
    Print("=====================================");
    Print("  SIMPLE INTEGRATION TEST");
    Print("=====================================");

    // Safety check - only run in tester or demo
    if(!MQLInfoInteger(MQL_TESTER)
       && AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
        Alert("Integration tests chỉ chạy trên TESTER hoặc DEMO account!");
        return INIT_FAILED;
    }

    g_startTime = TimeCurrent();

    // === 1. Setup Adapters ===
    g_md   = new Mt5MarketDataAdapter();
    g_exec = new Mt5ExecutionAdapter(123, 456); // magic_display, magic_storage

    // === 2. Setup Mock Signal (generates BUY after 5 ticks) ===
    g_signal = new MockSignal();
    g_signal.SetNoSignal(); // Start with no signal

    // === 3. Create Orchestrator ===
    g_orch = new Orchestrator(_Symbol, PERIOD_CURRENT, 5, InpMagic, g_signal, g_exec, g_md);

    // === 4. Setup Event Handler ===
    g_handler = new SimpleLoggingHandler();
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
    Print("  TEST SUMMARY");
    Print("=====================================");

    datetime endTime = TimeCurrent();
    int duration     = (int)(endTime - g_startTime);

    PrintFormat("Duration: %d seconds (%.1f minutes)", duration, duration / 60.0);
    PrintFormat("Total ticks processed: %d", g_totalTicks);
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
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    if(g_orch == NULL || !g_orch.IsReady()) return;

    g_totalTicks++;

    // After 5 ticks, generate a BUY signal
    if(g_totalTicks == 5 && g_signal != NULL) {
        double bid = 0, ask = 0;
        if(g_md.LastBidAsk(_Symbol, bid, ask)) {
            g_signal.SetupBuySignal(bid, bid - 100 * _Point, bid + 200 * _Point);
            Print("Mock signal activated at tick #", g_totalTicks, " Price: ", bid);
        }
    }

    // After 10 ticks, generate a SELL signal
    if(g_totalTicks == 10 && g_signal != NULL) {
        double bid = 0, ask = 0;
        if(g_md.LastBidAsk(_Symbol, bid, ask)) {
            g_signal.SetupSellSignal(ask, ask + 100 * _Point, ask - 200 * _Point);
            Print("Mock SELL signal activated at tick #", g_totalTicks, " Price: ", ask);
        }
    }

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
