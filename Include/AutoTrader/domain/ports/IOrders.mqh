// Include/AutoTrader/domain/ports/IOrders.mqh

struct OrderInfo {
  ulong  ticket;
  string symbol;
  long   magic;
  long   type;     // ORDER_TYPE_*
  double volume;
  double price_open;
  double sl;
  double tp;
  datetime time_setup;
};

class IOrders {
public:
  virtual int  Total() = 0;
  virtual int  ListBySymbolMagic(const string sym, long magic, OrderInfo &buffer[], const int maxN) = 0;
  virtual bool FirstBySymbolMagic(const string sym, long magic, OrderInfo &out) = 0;
};
