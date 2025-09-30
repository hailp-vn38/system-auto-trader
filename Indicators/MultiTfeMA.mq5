//+------------------------------------------------------------------+
//|                                                   MultiTfeMA.mq5 |
//|                         Copyright 2025, Lamphuchai.dev@gmail.com |
//|                                                 https://mql5.com |
//| 09.07.2025 - Initial release                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Lamphuchai.dev@gmail.com"
#property link "https://mql5.com"
#property version "1.00"

#include <HaiLP/Signals/MASignal.mqh>

#property tester_indicator "MultiTfeMA.ex5"

//
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1
//--- plot Label1
// #property indicator_label1 "Label1"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrRed
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1

//--- indicator buffers
double Label1Buffer[];

MASignal *_ma;

input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input int MaPeriod = 21;
input int MaShift = 0;
input ENUM_MA_METHOD MaMethod = MODE_EMA;
input ENUM_APPLIED_PRICE MaAppliedPrice = PRICE_CLOSE;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit() {
  //--- indicator buffers mapping
  SetIndexBuffer(0, Label1Buffer, INDICATOR_DATA);
  PlotIndexSetInteger(0, PLOT_SHIFT, 0);
  PlotIndexSetString(0, PLOT_LABEL,
                     "Multi MA(" + IntegerToString(MaPeriod) + ")");
  ArraySetAsSeries(Label1Buffer, true);

  //---

  _ma = new MASignal(_Symbol, Timeframe, MaPeriod, MaShift, MaMethod,
                     MaAppliedPrice);
  if (!_ma.IsValid()) return (INIT_FAILED);
  return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[],
                const double &high[], const double &low[],
                const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[]) {
  datetime time_tf = iTime(_Symbol, Timeframe, 0);
  int limit = iBarShift(_Symbol, PERIOD_CURRENT, time_tf);
  if (prev_calculated == 0) limit = rates_total - 1;

  for (int i = limit; i >= 0; i--) {
    double ma_tf[];
    datetime time_i = iTime(_Symbol, PERIOD_CURRENT, i);
    int index = iBarShift(_Symbol, Timeframe, time_i);
    if (_ma.CopyMA(index, 1, ma_tf) == -1) return (0);
    Label1Buffer[i] = ma_tf[0];
  }

  return (rates_total);
}

//+------------------------------------------------------------------+

void OnDeinit(const int reason) { delete _ma; }
