
#property strict

#include "App_Config.mqh"
#include "App_Constants.mqh"

#include <AutoTrader/adapters/mt5/Mt5MarketDataAdapter.mqh>
#include <AutoTrader/strategies/RangeBreakout.mqh>

Mt5MarketDataAdapter *g_md;

RangeBreakout *g_sig;

int OnInit() {
  // Khởi tạo Adapter
  g_md = new Mt5MarketDataAdapter();

  // Khởi tạo chiến lược open
  g_sig = new RangeBreakout(g_md, 1, 0, 12, 0, 0, 0, 0, false);

  Comment("EMA(21/50) demo running..."); // quick HUD
  return (INIT_SUCCEEDED);
}

void OnTick() {
  TradeSignal out;
  if(g_sig.ShouldEnter(_Symbol, _Period, out)) { Print("test"); }
}

void OnDeinit(const int reason) {
  delete g_md;
  delete g_sig;
}
