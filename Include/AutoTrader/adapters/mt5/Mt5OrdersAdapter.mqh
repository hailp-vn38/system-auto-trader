// Include/AutoTrader/adapters/mt5/Mt5OrdersAdapter.mqh

#include <AutoTrader/domain/ports/IOrders.mqh>

//+------------------------------------------------------------------+
//| Mt5OrdersAdapter - Implementation của IOrders                    |
//+------------------------------------------------------------------+
class Mt5OrdersAdapter : public IOrders {
public:
  //+------------------------------------------------------------------+
  //| Constructor                                                      |
  //+------------------------------------------------------------------+
  Mt5OrdersAdapter() {}

  //+------------------------------------------------------------------+
  //| Tổng số orders đang mở                                           |
  //+------------------------------------------------------------------+
  int Total() override { return OrdersTotal(); }

  //+------------------------------------------------------------------+
  //| Lấy order mới nhất theo symbol + magic                           |
  //| BUG FIX: Duyệt ngược để lấy order mới nhất                       |
  //+------------------------------------------------------------------+
  bool Current(const string sym, const long magic, OrderInfo &out) override {
    const int total = OrdersTotal();

    // Duyệt từ cuối về đầu để lấy order mới nhất
    for(int i = total - 1; i >= 0; i--) {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;

      // OPTIMIZATION: Không cần OrderSelect nếu đã có ticket
      // Vì OrderGetTicket đã select order rồi
      string osym = OrderGetString(ORDER_SYMBOL);
      long omag   = OrderGetInteger(ORDER_MAGIC);

      if(osym == sym && omag == magic) { return FillOrderInfo(out, ticket); }
    }

    return false;
  }

  //+------------------------------------------------------------------+
  //| Lấy order đầu tiên theo symbol + magic                           |
  //+------------------------------------------------------------------+
  bool FirstBySymbolMagic(const string sym, const long magic, OrderInfo &out) override {
    const int total = OrdersTotal();

    for(int i = 0; i < total; i++) {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;

      string osym = OrderGetString(ORDER_SYMBOL);
      long omag   = OrderGetInteger(ORDER_MAGIC);

      if(osym == sym && omag == magic) { return FillOrderInfo(out, ticket); }
    }

    return false;
  }

  //+------------------------------------------------------------------+
  //| Lấy danh sách orders theo symbol + magic                         |
  //| BUG FIX: Dynamic array resize, validate buffer size             |
  //+------------------------------------------------------------------+
  int ListBySymbolMagic(const string sym, const long magic, OrderInfo &buffer[]) override {
    const int total = OrdersTotal();
    if(total <= 0) return 0;

    // Pre-allocate buffer với size tối đa
    ArrayResize(buffer, total);
    int written = 0;

    for(int i = 0; i < total; i++) {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;

      string osym = OrderGetString(ORDER_SYMBOL);
      long omag   = OrderGetInteger(ORDER_MAGIC);

      if(osym == sym && omag == magic) {
        if(FillOrderInfo(buffer[written], ticket)) { written++; }
      }
    }

    // Resize buffer về đúng size thực tế
    if(written < total) { ArrayResize(buffer, written); }

    return written;
  }

  //+------------------------------------------------------------------+
  //| Đếm số orders theo symbol + magic                                |
  //| OPTIMIZATION: Không cần fill full info, chỉ count               |
  //+------------------------------------------------------------------+
  int CountBySymbolMagic(const string sym, const long magic) override {
    const int total = OrdersTotal();
    int count       = 0;

    for(int i = 0; i < total; i++) {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;

      string osym = OrderGetString(ORDER_SYMBOL);
      long omag   = OrderGetInteger(ORDER_MAGIC);

      if(osym == sym && omag == magic) { count++; }
    }

    return count;
  }

  //+------------------------------------------------------------------+
  //| Đọc thông tin order từ ticket                                    |
  //| PUBLIC: Để các class khác có thể sử dụng trực tiếp              |
  //+------------------------------------------------------------------+
  bool GetOrderInfo(OrderInfo &out, const ulong ticket) {
    if(!OrderSelect(ticket)) return false;
    return FillOrderInfo(out, ticket);
  }

  //+------------------------------------------------------------------+
  //| Đọc order theo index (support internal iteration)                |
  //+------------------------------------------------------------------+
  bool GetOrderInfoByIndex(OrderInfo &out, int index) {
    ulong ticket = OrderGetTicket(index);
    if(ticket == 0) return false;
    return FillOrderInfo(out, ticket);
  }

private:
  //+------------------------------------------------------------------+
  //| Fill OrderInfo struct từ MT5 order properties                    |
  //| IMPORTANT: Assume order đã được select trước đó                  |
  //+------------------------------------------------------------------+
  bool FillOrderInfo(OrderInfo &out, const ulong ticket) {
    // Validate order exists
    if(ticket == 0) return false;

    // Fill basic info
    out.ticket = ticket;
    out.symbol = OrderGetString(ORDER_SYMBOL);

    // Fill integer fields
    out.magic      = OrderGetInteger(ORDER_MAGIC);
    out.type       = OrderGetInteger(ORDER_TYPE);
    out.time_setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);

    // Fill double fields
    out.volume     = OrderGetDouble(ORDER_VOLUME_INITIAL);
    out.price_open = OrderGetDouble(ORDER_PRICE_OPEN);
    out.sl         = OrderGetDouble(ORDER_SL);
    out.tp         = OrderGetDouble(ORDER_TP);

    // Validation: Symbol must not be empty
    if(out.symbol == "") return false;

    return true;
  }
};
