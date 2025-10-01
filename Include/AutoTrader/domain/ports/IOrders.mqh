// Include/AutoTrader/domain/ports/IOrders.mqh

struct OrderInfo {
  ulong ticket;
  string symbol;
  long magic;
  long type; // ORDER_TYPE_*
  double volume;
  double price_open;
  double sl;
  double tp;
  datetime time_setup;
};

class IOrders {
public:
  // Tổng số order mở
  virtual int Total() = 0;
  // Lấy order mới nhất theo symbol & magic
  virtual bool Current(const string sym, const long magic, OrderInfo &out) = 0;
  // Lấy order đầu tiên (oldest) theo symbol & magic
  virtual bool FirstBySymbolMagic(const string sym, const long magic, OrderInfo &out) = 0;
  // Đếm số lượng order theo symbol & magic
  virtual int CountBySymbolMagic(const string sym, const long magic) = 0;
  // Lấy danh sách các order theo symbol & magic
  virtual int ListBySymbolMagic(const string sym, const long magic, OrderInfo &buffer[]) = 0;
};
