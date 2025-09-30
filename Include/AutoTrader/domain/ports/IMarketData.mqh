//+------------------------------------------------------------------+
//| Include/AutoTrader/domain/ports/IMarketData.mqh (updated)        |
//+------------------------------------------------------------------+

class IMarketData {
public:
  // Giá tức thời
  virtual bool LastBidAsk(const string sym, double &bid, double &ask) = 0;

  // Thuộc tính Symbol
  virtual double Point(const string sym) = 0;
  virtual double TickSize(const string sym) = 0;

  // Dữ liệu nến (OHLC)
  virtual bool OHLC(const string sym, ENUM_TIMEFRAMES tf, int shift,
                    double &o, double &h, double &l, double &c) = 0;

  // (tùy chọn) chỉ báo
  virtual double MA(const string sym, ENUM_TIMEFRAMES tf, int period, int shift) = 0;
  virtual double ATR(const string sym, ENUM_TIMEFRAMES tf, int period, int shift) = 0;
};
