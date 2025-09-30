// Include/AutoTrader/adapters/mt5/Mt5ExecutionAdapter.mqh

#include <AutoTrader/domain/ports/IExecution.mqh>
#include <Trade/Trade.mqh>

class Mt5ExecutionAdapter : public IExecution {
private:
  CTrade m_trade;
  ulong m_defaultDeviation;

  void Prep(const long magic, const int deviation_points) {
    m_trade.SetExpertMagicNumber((ulong)magic);
    const ulong dev = (deviation_points > 0) ? (ulong)deviation_points : m_defaultDeviation;
    m_trade.SetDeviationInPoints(dev);
  }

public:
  Mt5ExecutionAdapter(const ulong defaultDeviationPoints = 20)
      : m_defaultDeviation(defaultDeviationPoints) {}

  bool PlaceMarket(const string sym, const ENUM_ORDER_TYPE type, double volume, double sl,
                   double tp, ulong &ticket_out, int deviation_points, long magic) override {
    Prep(magic, deviation_points);
    bool ok    = (type == ORDER_TYPE_BUY) ? m_trade.Buy(volume, sym, 0.0, sl, tp)
                                          : (type == ORDER_TYPE_SELL ? m_trade.Sell(volume, sym, 0.0,
                                                                                    sl, tp)
                                                                     : false);
    ticket_out = ok ? m_trade.ResultDeal() : 0;
    return ok;
  }

  bool ModifySLTPBySymbolMagic(const string sym, long magic, double sl, double tp) override {
    const int n = PositionsTotal();
    for(int i = 0; i < n; i++) {
      if(PositionGetSymbol(i) == sym && PositionGetInteger(POSITION_MAGIC) == magic) {
        ulong pticket = (ulong)PositionGetInteger(POSITION_TICKET);
        Prep(magic, (int)m_defaultDeviation);
        return m_trade.PositionModify(pticket, sl, tp);
      }
    }
    return false;
  }

  int CloseAllBySymbolMagic(const string sym, long magic) override {
    int closed = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == sym && PositionGetInteger(POSITION_MAGIC) == magic) {
        ulong pticket = (ulong)PositionGetInteger(POSITION_TICKET);
        Prep(magic, (int)m_defaultDeviation);
        if(m_trade.PositionClose(pticket)) closed++;
      }
    }
    return closed;
  }

  // ---- Pending Stop/Limit ----
  bool PlaceStop(const string sym, bool isSell, double volume, double price, double sl, double tp,
                 long magic, ulong &ticket_out) override {
    Prep(magic, -1);
    bool ok    = isSell ? m_trade.SellStop(volume, price, sym, sl, tp)
                        : m_trade.BuyStop(volume, price, sym, sl, tp);
    ticket_out = ok ? m_trade.ResultOrder() : 0;
    return ok;
  }

  bool PlaceLimit(const string sym, bool isSell, double volume, double price, double sl, double tp,
                  long magic, ulong &ticket_out) override {
    Prep(magic, -1);
    bool ok    = isSell ? m_trade.SellLimit(volume, price, sym, sl, tp)
                        : m_trade.BuyLimit(volume, price, sym, sl, tp);
    ticket_out = ok ? m_trade.ResultOrder() : 0;
    return ok;
  }

  bool ModifyPending(ulong order_ticket, double price, double sl, double tp) override {
    // ORDER_TIME_GTC: Good-Till-Cancelled (tồn tại đến khi huỷ)
    // expiration=0: không đặt thời hạn; stoplimit=0: không dùng cho StopLimit
    const ENUM_ORDER_TYPE_TIME type_time = ORDER_TIME_GTC;
    const datetime expiration            = 0;
    const double stoplimit               = 0.0;

    return m_trade.OrderModify(order_ticket, price, sl, tp, type_time, expiration, stoplimit);
  }
  bool DeletePending(ulong order_ticket) override { return m_trade.OrderDelete(order_ticket); }

  int DeleteAllPendingsBySymbolMagic(const string sym, long magic) override {
    int deleted = 0;
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
      ulong ot = OrderGetTicket(i);
      if(ot == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) == sym && OrderGetInteger(ORDER_MAGIC) == magic) {
        if(m_trade.OrderDelete(ot)) deleted++;
      }
    }
    return deleted;
  }
};
