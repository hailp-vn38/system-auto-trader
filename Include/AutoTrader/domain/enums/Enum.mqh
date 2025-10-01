enum ENUM_TRADE_TYPE {
  TRADE_TYPE_INVALID    = 0,
  TRADE_TYPE_BUY        = 1,
  TRADE_TYPE_SELL       = 2,
  TRADE_TYPE_BUY_LIMIT  = 3,
  TRADE_TYPE_SELL_LIMIT = 4,
  TRADE_TYPE_BUY_STOP   = 5,
  TRADE_TYPE_SELL_STOP  = 6
};

enum ENUM_TARGET_CALC_MODE {
  CALC_MODE_OFF = 0,
  CALC_MODE_DEFAULT,
  CALC_MODE_FACTOR,
  CALC_MODE_PERCENT,
  CALC_MODE_POINTS
};

enum ENUM_TRAILING_STOP_MODE {
  TRAILING_STOP_OFF        = 0,
  TRAILING_STOP_BREAK_EVEN = 1,
  TRAILING_STOP_DISTANCE   = 2
};

// --- Original modes mapped 1:1 ---
enum ENUM_LOT_CALC_MODE {
  CALC_MODE_FIXED        = 0, // Lot cố định (value = lot)
  CALC_MODE_FIXED_MONEY  = 1, // Lot theo số tiền rủi ro cố định (value = tiền)
  CALC_MODE_RISK_PERCENT = 2  // Lot theo % rủi ro trên Balance (value = %)
};

enum ENUM_CLOSE_TIME_MODE {
  CLOSE_TIME_OFF      = 0, // OFF
  CLOSE_TIME_DAILY    = 1, // DAILY
  CLOSE_TIME_NEXT_DAY = 2  // NEXT_DAY
};