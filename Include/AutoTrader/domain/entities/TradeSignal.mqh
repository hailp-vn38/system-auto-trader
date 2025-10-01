// Include/AutoTrader/domain/entities/TradeSignal.mqh
#include <AutoTrader/domain/enums/Enum.mqh>

struct TradeSignal {
  bool valid;
  int stopPoints;       // dữ liệu phụ cho sizer/risk
  double price;         // giá vào lệnh đề xuất
  double sl;            // đề xuất SL
  double tp;            // đề xuất TP
  string comment;       // chú thích lệnh
  ENUM_TRADE_TYPE type; // loại lệnh (buy/sell/limit/stop)
  bool isOrderPending;  // lệnh thị trường hay pending order
  bool isSell;          // Chỉ báo lệnh bán (true=SELL, false=BUY)

  // ctor mặc định
  void TradeSignal() {
    valid          = false;
    type           = TRADE_TYPE_INVALID;
    stopPoints     = 0;
    price          = 0.0;
    sl             = 0.0;
    tp             = 0.0;
    comment        = "";
    isOrderPending = false;
    isSell         = false;
  }
};

ENUM_ORDER_TYPE ToOrderType(const ENUM_TRADE_TYPE tt) {
  switch(tt) {
  case TRADE_TYPE_BUY: return ORDER_TYPE_BUY;
  case TRADE_TYPE_SELL: return ORDER_TYPE_SELL;
  case TRADE_TYPE_BUY_LIMIT: return ORDER_TYPE_BUY_LIMIT;
  case TRADE_TYPE_SELL_LIMIT: return ORDER_TYPE_SELL_LIMIT;
  case TRADE_TYPE_BUY_STOP: return ORDER_TYPE_BUY_STOP;
  case TRADE_TYPE_SELL_STOP: return ORDER_TYPE_SELL_STOP;
  default: return ORDER_TYPE_BUY; // mặc định
  }
}