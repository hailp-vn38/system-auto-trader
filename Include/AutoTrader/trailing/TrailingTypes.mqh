//+------------------------------------------------------------------+
//| Include/AutoTrader/trailing/TrailingTypes.mqh                    |
//| Common types and enums for trailing stop implementations         |
//+------------------------------------------------------------------+
#ifndef TRAILING_TYPES_MQH
#define TRAILING_TYPES_MQH

enum ENUM_TSL_CALC_MODE {
    TSL_CALC_OFF     = 0,
    TSL_CALC_POINTS  = 1,
    TSL_CALC_PERCENT = 2,
    TSL_CALC_RR      = 3
};

#endif // TRAILING_TYPES_MQH
