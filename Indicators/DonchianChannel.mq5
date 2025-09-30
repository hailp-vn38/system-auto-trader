//+------------------------------------------------------------------+
//|                                              DonchianChannel.mq5 |
//|                                            Copyright 2025, haiLP |
//|                                         lamphuchai.dev@gmail.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, Lamphuchai.dev@gmail.com"
#property link "https://mql5.com"
#property version "1.10"
#property description "Donchian Channel with multi-timeframe and shift support"

#property tester_indicator "DonchianChannel.ex5"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots 3

#property indicator_label1 "Upper Line"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrGreen
#property indicator_width1 2

#property indicator_label2 "Lower Line"
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrRed
#property indicator_width2 2

#property indicator_label3 "Mid Line"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrBlue
#property indicator_width3 1

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+

input int InpPeriod = 20;                             // Period
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;  // Timeframe
input int InpShift = 0;                               // Shift

ENUM_TIMEFRAMES Timeframe;  // Timeframe of operation
double UpBuffer[];
double MidBuffer[];
double DownBuffer[];

//--- MTF data
double MtfHigh[], MtfLow[];

int deltaHighTF;  // Difference in candles count from the higher timeframe

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
  IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

  //--- indicator buffers mapping
  SetIndexBuffer(0, UpBuffer, INDICATOR_DATA);
  SetIndexBuffer(1, DownBuffer, INDICATOR_DATA);
  SetIndexBuffer(2, MidBuffer, INDICATOR_DATA);

  //--- set plotting parameters
  for (int i = 0; i < 3; i++) {
    PlotIndexSetInteger(i, PLOT_DRAW_BEGIN, InpPeriod - 1 + InpShift);
    PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, EMPTY_VALUE);
  }

  //--- Set indicator name
  string short_name = "DCH(" + IntegerToString(InpPeriod) + ")";
  if (InpTimeframe != PERIOD_CURRENT)
    short_name += " " + EnumToString(InpTimeframe);
  IndicatorSetString(INDICATOR_SHORTNAME, short_name);

  ArraySetAsSeries(UpBuffer, false);
  ArraySetAsSeries(DownBuffer, false);
  ArraySetAsSeries(MidBuffer, false);

  // Setting values for high timeframe:
  Timeframe = InpTimeframe;
  if (InpTimeframe < Period()) {
    Timeframe = Period();
  }

  deltaHighTF = 0;
  if (PeriodSeconds(Timeframe) > PeriodSeconds()) {
    deltaHighTF = PeriodSeconds(Timeframe) / PeriodSeconds();
  }

  return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Donchian Channel calculation                                     |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[],
                const double &high[], const double &low[],
                const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[]) {
  //--- Check for enough data
  if (rates_total < InpPeriod + InpShift) return (0);

  bool is_current_tf = (Timeframe == PERIOD_CURRENT || Timeframe == Period());
  //--- Calculation loop
  int first_bar =
      (prev_calculated > 0) ? prev_calculated - 1 - deltaHighTF : InpPeriod - 1;
  for (int bar = first_bar; bar < rates_total && !IsStopped(); bar++) {
    double upper, lower;
    if (is_current_tf) {
      int high_idx =
          ArrayMaximum(high, bar - InpPeriod + 1, InpPeriod + InpShift);
      int low_idx =
          ArrayMinimum(low, bar - InpPeriod + 1, InpPeriod + InpShift);
      upper = high[high_idx];
      lower = low[low_idx];
    } else {
      int index = rates_total - 1 - bar + InpShift;

      int shift =
          iBarShift(_Symbol, Timeframe, iTime(_Symbol, PERIOD_CURRENT, index));
      upper = iHigh(_Symbol, Timeframe,
                    iHighest(_Symbol, Timeframe, MODE_HIGH, InpPeriod, shift));
      lower = iLow(_Symbol, Timeframe,
                   iLowest(_Symbol, Timeframe, MODE_LOW, InpPeriod, shift));
    }

    UpBuffer[bar] = upper;
    DownBuffer[bar] = lower;
    MidBuffer[bar] = (upper + lower) * 0.5;
  }

  return (rates_total);
}