// Include/AutoTrader/adapters/mt5/Mt5OrdersAdapter.mqh

#include <AutoTrader/domain/ports/IOrders.mqh>

class Mt5OrdersAdapter : public IOrders {
public:
  int Total() override { return OrdersTotal(); }

  int ListBySymbolMagic(const string sym, long magic, OrderInfo &buffer[], const int maxN) override {
    int found=0;
    for(int i=OrdersTotal()-1;i>=0 && found<maxN;i--){
      ulong ot = OrderGetTicket(i); if(ot==0) continue;
      if(OrderGetString(ORDER_SYMBOL)==sym && OrderGetInteger(ORDER_MAGIC)==magic){
        OrderInfo oi;
        oi.ticket      = ot;
        oi.symbol      = sym;
        oi.magic       = (long)OrderGetInteger(ORDER_MAGIC);
        oi.type        = (long)OrderGetInteger(ORDER_TYPE);
        oi.volume      = OrderGetDouble(ORDER_VOLUME_CURRENT);
        oi.price_open  = OrderGetDouble(ORDER_PRICE_OPEN);
        oi.sl          = OrderGetDouble(ORDER_SL);
        oi.tp          = OrderGetDouble(ORDER_TP);
        oi.time_setup  = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
        buffer[found++] = oi;
      }
    }
    return found;
  }

  bool FirstBySymbolMagic(const string sym, long magic, OrderInfo &out) override {
    OrderInfo tmp[1];
    int n = ListBySymbolMagic(sym, magic, tmp, 1);
    if(n>0){ out = tmp[0]; return true; }
    return false;
  }
};
