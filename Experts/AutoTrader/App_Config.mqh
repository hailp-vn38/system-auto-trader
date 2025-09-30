
input string InpSymbol        = "BTC";
input ENUM_TIMEFRAMES InpTF   = PERIOD_M15;
input long   InpMagic         = 555777999;

input int    InpFastMA        = 20;
input int    InpSlowMA        = 50;
input double InpLot           = 0.10;
input int    InpSLPoints      = 300;
input int    InpTPPoints      = 600;
input int    InpDeviation     = 10;

input bool   InpUseExitFlipMA = true;
input bool   InpUseTrailingATR= true;
input int    InpATRPeriod     = 14;
input double InpATRMult       = 2.0;

// Storage is optional. Wire manually in OnInit (see .mq5).
