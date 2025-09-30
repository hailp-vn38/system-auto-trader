// Include/AutoTrader/domain/entities/TradeSignal.mqh
// Loại kích hoạt vào lệnh
enum ENUM_SIGNAL_EXEC_TYPE { SIG_EXEC_MARKET=0, SIG_EXEC_ORDER=1 };
// Phân loại lệnh chờ (tối thiểu STOP/LIMIT)
enum ENUM_ORDER_KIND { ORDER_KIND_STOP=0, ORDER_KIND_LIMIT=1 };

struct TradeSignal {
  bool            valid;
  ENUM_ORDER_TYPE orderType;     // ORDER_TYPE_BUY/SELL (định hướng BUY/SELL)
  int             stopPoints;    // dữ liệu phụ cho sizer/risk
  double          sl;            // đề xuất SL
  double          tp;            // đề xuất TP

  // --- MỚI cho order ---
  ENUM_SIGNAL_EXEC_TYPE execType;     // market | order
  ENUM_ORDER_KIND       orderKind;    // stop | limit
  double                triggerPrice; // giá kích hoạt; 0 => để core tự lấy

  // ctor mặc định
  void TradeSignal() {
    valid=false; orderType=ORDER_TYPE_BUY; stopPoints=0;
    sl=0.0; tp=0.0; execType=SIG_EXEC_MARKET; orderKind=ORDER_KIND_STOP; triggerPrice=0.0;
  }
};
