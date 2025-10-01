//+------------------------------------------------------------------+
//| MultiEntryExample.mq5 - Demo Multi-Entry Strategies              |
//| Ví dụ sử dụng Grid và Pyramid strategies với Orchestrator        |
//+------------------------------------------------------------------+
#property copyright "AutoTrader System"
#property link "https://github.com/hailp-vn38/system-auto-trader"
#property version "1.00"
#property strict

// Core dependencies
#include <AutoTrader/adapters/mt5/Mt5ExecutionAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5MarketDataAdapter.mqh>
#include <AutoTrader/app/Orchestrator.mqh>

// Strategies
#include <AutoTrader/strategies/GridEntry.mqh>
#include <AutoTrader/strategies/PyramidEntry.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                  |
//+------------------------------------------------------------------+
input group "=== Trading Settings ===" input string InpSymbol
                                        = "";   // Symbol (empty = current chart)
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1; // Timeframe
input long InpMagic                = 20241001;  // Magic Number
input int InpDeviation             = 10;        // Deviation Points

input group "=== Strategy Selection ===" enum STRATEGY_TYPE {
  STRAT_GRID,    // Grid Entry
  STRAT_PYRAMID, // Pyramid Entry
  STRAT_SINGLE   // Single Entry (EMA Cross)
};
input STRATEGY_TYPE InpStrategyType = STRAT_GRID; // Strategy Type

input group "=== Grid Settings (for GRID strategy) ===" input int InpGridOrders
                                        = 3; // Number of grid orders
input double InpGridStepPips = 10.0;         // Grid step (pips)
input int InpGridSL          = 50;           // Grid SL (pips)
input int InpGridTP          = 100;          // Grid TP (pips)
input bool InpGridBuy        = true;         // Buy grid (false=Sell)

input group "=== Pyramid Settings (for PYRAMID strategy) ===" input int InpPyramidLevels
                                        = 3; // Pyramid levels
input double InpPyramidStepPips = 20.0;      // Level step (pips)
input int InpPyramidSL          = 100;       // Pyramid SL (pips)
input int InpPyramidMA          = 50;        // MA Period

//+------------------------------------------------------------------+
//| Global variables                                                  |
//+------------------------------------------------------------------+
Orchestrator *g_orch        = NULL;
Mt5ExecutionAdapter *g_exec = NULL;
Mt5MarketDataAdapter *g_md  = NULL;
ISignal *g_strategy         = NULL;

string g_symbol;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit() {
  // Set symbol
  g_symbol = (InpSymbol == "" || InpSymbol == "0") ? _Symbol : InpSymbol;

  Print("=================================================");
  Print("MultiEntryExample EA - Initializing");
  Print("Symbol: ", g_symbol);
  Print("Timeframe: ", EnumToString(InpTimeframe));
  Print("Magic: ", InpMagic);
  Print("Strategy: ", EnumToString(InpStrategyType));
  Print("=================================================");

  // Create adapters
  g_md   = new Mt5MarketDataAdapter();
  g_exec = new Mt5ExecutionAdapter();

  if(g_md == NULL || g_exec == NULL) {
    Print("ERROR: Failed to create adapters");
    return INIT_FAILED;
  }

  // Create strategy based on selection
  switch(InpStrategyType) {
  case STRAT_GRID:
    Print("Creating GridEntry strategy...");
    Print("  Orders: ", InpGridOrders, ", Step: ", InpGridStepPips, " pips");
    Print("  SL: ", InpGridSL, " pips, TP: ", InpGridTP, " pips");
    Print("  Direction: ", (InpGridBuy ? "BUY" : "SELL"));

    g_strategy = new GridEntry(g_md, g_symbol, InpTimeframe, InpGridOrders, InpGridStepPips,
                               InpGridSL, InpGridTP, InpGridBuy);
    break;

  case STRAT_PYRAMID:
    Print("Creating PyramidEntry strategy...");
    Print("  Levels: ", InpPyramidLevels, ", Step: ", InpPyramidStepPips, " pips");
    Print("  SL: ", InpPyramidSL, " pips, MA Period: ", InpPyramidMA);

    g_strategy = new PyramidEntry(g_md, g_symbol, InpTimeframe, InpPyramidMA, InpPyramidLevels,
                                  InpPyramidStepPips, InpPyramidSL);
    break;

  case STRAT_SINGLE: Print("Creating EmaCross21x50 strategy (single entry)...");
#include <AutoTrader/strategies/EmaCross21x50.mqh>
    g_strategy = new EmaCross21x50(g_symbol, InpTimeframe);
    break;

  default: Print("ERROR: Unknown strategy type"); return INIT_FAILED;
  }

  if(g_strategy == NULL) {
    Print("ERROR: Failed to create strategy");
    return INIT_FAILED;
  }

  // Create orchestrator
  g_orch = new Orchestrator(g_symbol, InpTimeframe, InpDeviation, InpMagic, g_strategy, g_exec,
                            g_md);

  if(g_orch == NULL) {
    Print("ERROR: Failed to create Orchestrator");
    return INIT_FAILED;
  }

  if(!g_orch.IsReady()) {
    Print("ERROR: Orchestrator not ready");
    return INIT_FAILED;
  }

  Print("=================================================");
  Print("MultiEntryExample EA - Initialization SUCCESSFUL");
  Print("Waiting for signals...");
  Print("=================================================");

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  Print("=================================================");
  Print("MultiEntryExample EA - Shutting down");
  Print("Reason: ", getUninitReasonText(reason));
  Print("=================================================");

  if(g_orch != NULL) {
    g_orch.OnDeinit();
    delete g_orch;
    g_orch = NULL;
  }

  if(g_strategy != NULL) {
    delete g_strategy;
    g_strategy = NULL;
  }

  if(g_exec != NULL) {
    delete g_exec;
    g_exec = NULL;
  }

  if(g_md != NULL) {
    delete g_md;
    g_md = NULL;
  }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
  if(g_orch == NULL) return;
  g_orch.OnTick();
}

//+------------------------------------------------------------------+
//| Trade transaction handler                                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request,
                        const MqlTradeResult &result) {
  if(g_orch == NULL) return;
  g_orch.OnTradeTransaction(trans, request, result);
}

//+------------------------------------------------------------------+
//| Get uninit reason text                                            |
//+------------------------------------------------------------------+
string getUninitReasonText(int reasonCode) {
  switch(reasonCode) {
  case REASON_PROGRAM: return "Expert stopped by user";
  case REASON_REMOVE: return "Expert removed from chart";
  case REASON_RECOMPILE: return "Expert recompiled";
  case REASON_CHARTCHANGE: return "Symbol/timeframe changed";
  case REASON_CHARTCLOSE: return "Chart closed";
  case REASON_PARAMETERS: return "Input parameters changed";
  case REASON_ACCOUNT: return "Account changed";
  case REASON_TEMPLATE: return "Template applied";
  case REASON_INITFAILED: return "Initialization failed";
  case REASON_CLOSE: return "Terminal closed";
  default: return "Unknown reason";
  }
}
