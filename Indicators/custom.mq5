//+------------------------------------------------------------------+
//|                                                       custom.mq5 |
//|                                            Copyright 2025, haiLP |
//|                                         lamphuchai.dev@gmail.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, Lamphuchai.dev@gmail.com"
#property link "https://mql5.com"
#property version "1.10"
#property description "Donchian Channel with multi-timeframe and shift support"

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1

#property indicator_label1 "Main Line"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrGreen
#property indicator_width1 2

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+

input int InpPeriod                = 20;             // Period
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT; // Timeframe
input int InpShift                 = 0;              // Shift

ENUM_TIMEFRAMES Timeframe; // Timeframe of operation
double MainBuf[];
int _handle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
  IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

  //--- indicator buffers mapping
  SetIndexBuffer(0, MainBuf, INDICATOR_DATA);
  ArraySetAsSeries(MainBuf, false);

  _handle = iMA(_Symbol, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE);
  return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Donchian Channel calculation                                     |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[],
                const double &close[], const long &tick_volume[], const long &volume[],
                const int &spread[]) {
  return (rates_total);
}
