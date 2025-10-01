#include <AutoTrader/domain/enums/Enum.mqh>

// Chuyển ENUM_TRADE_TYPE to ENUM_ORDER_TYPE
bool TradeTypeToOrderType(const ENUM_TRADE_TYPE tt, ENUM_ORDER_TYPE &ot,
                          ENUM_TRADE_REQUEST_ACTIONS &action) {
  switch(tt) {
  case TRADE_TYPE_BUY: {
    ot     = ORDER_TYPE_BUY;
    action = TRADE_ACTION_DEAL;
    return true;
  }
  case TRADE_TYPE_SELL: {
    ot     = ORDER_TYPE_SELL;
    action = TRADE_ACTION_DEAL;
    return true;
  }
  case TRADE_TYPE_BUY_LIMIT: {
    ot     = ORDER_TYPE_BUY_LIMIT;
    action = TRADE_ACTION_PENDING;
    return true;
  }
  case TRADE_TYPE_SELL_LIMIT: {
    ot     = ORDER_TYPE_SELL_LIMIT;
    action = TRADE_ACTION_PENDING;
    return true;
  }
  case TRADE_TYPE_BUY_STOP: {
    ot     = ORDER_TYPE_BUY_STOP;
    action = TRADE_ACTION_PENDING;
    return true;
  }
  case TRADE_TYPE_SELL_STOP: {
    ot     = ORDER_TYPE_SELL_STOP;
    action = TRADE_ACTION_PENDING;
    return true;
  }
  default: return false;
  }
}

