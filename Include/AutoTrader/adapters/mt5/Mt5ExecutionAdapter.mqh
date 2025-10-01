// Include/AutoTrader/adapters/mt5/Mt5ExecutionAdapter.mqh

#include <AutoTrader/domain/enums/Enum.mqh>
#include <AutoTrader/domain/ports/IExecution.mqh>
#include <AutoTrader/utils/Convert.mqh>
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
  Mt5ExecutionAdapter(const ulong magic, const ulong defaultDeviationPoints = 20)
      : m_defaultDeviation(defaultDeviationPoints) {
    m_trade.SetExpertMagicNumber(magic);
    m_trade.SetDeviationInPoints(m_defaultDeviation);
  }

  bool OpenTrade(const string sym, long magic, const ENUM_TRADE_TYPE type, double volume,
                 double price, double sl, double tp, int deviation_points, ulong &ticket_out,
                 const string comment = "", ENUM_ORDER_TYPE_TIME type_time = ORDER_TIME_GTC,
                 datetime expiration = 0) override {
    ENUM_ORDER_TYPE ot;
    ENUM_TRADE_REQUEST_ACTIONS action;

    if(!TradeTypeToOrderType(type, ot, action)) return false;

    MqlTradeRequest req   = {};     // Khởi tạo struct
    req.action            = action; // Sử dụng action từ hàm helper
    req.symbol            = sym;
    req.volume            = volume;
    req.type              = ot;
    req.price             = price;
    req.sl                = sl;
    req.tp                = tp;
    req.deviation         = (deviation_points > 0) ? (ulong)deviation_points : m_defaultDeviation;
    req.magic             = (ulong)magic;
    req.type_filling      = ORDER_FILLING_FOK;
    req.type_time         = type_time;
    req.expiration        = expiration;
    req.comment           = comment;
    req.stoplimit         = 0.0;

    MqlTradeResult result = {0}; // Khởi tạo struct

    if(!m_trade.OrderSend(req, result)) return false;

    // Kiểm tra kết quả
    if(result.retcode != TRADE_RETCODE_DONE && result.retcode != TRADE_RETCODE_PLACED) {
      return false;
    }

    // Lấy ticket từ kết quả phù hợp
    if(action == TRADE_ACTION_DEAL) {
      ticket_out = result.deal;
    } else {
      ticket_out = result.order;
    }

    return true;
  }

  int ClosePositionsByTickets(const ulong &tickets[]) override {
    int closed = 0;
    for(int i = 0; i < ArraySize(tickets); i++) {
      if(m_trade.PositionClose(tickets[i])) closed++;
    }
    return closed;
  }

  int CloseAllBySymbolMagic(const string sym, long magic) override {
    int closed = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == sym && PositionGetInteger(POSITION_MAGIC) == magic) {
        ulong pticket = (ulong)PositionGetInteger(POSITION_TICKET);
        if(m_trade.PositionClose(pticket)) closed++;
      }
    }
    return closed;
  }

  bool ModifyPositionByTicket(const ulong ticket, const double sl, const double tp) override {
    return m_trade.PositionModify(ticket, sl, tp);
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

  int DeleteAllPendings(const string sym, long magic) override {
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