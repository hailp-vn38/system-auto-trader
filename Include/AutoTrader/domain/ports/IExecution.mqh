// Include/AutoTrader/domain/ports/IExecution.mqh

#include <AutoTrader/domain/enums/Enum.mqh>

class IExecution {
public:
  // Common
  virtual bool
  OpenTrade(const string sym, long magic, const ENUM_TRADE_TYPE type, double volume, double price,
            double sl, double tp, int deviation_points, ulong &ticket_out,
            const string comment = "", ENUM_ORDER_TYPE_TIME type_time = ORDER_TIME_GTC,
            datetime expiration = 0)                                                        = 0;
  virtual bool ModifyPositionByTicket(const ulong ticket, const double sl, const double tp) = 0;
  virtual int ClosePositionsByTickets(const ulong &tickets[])                               = 0;
  virtual int CloseAllBySymbolMagic(const string sym, long magic)                           = 0;

  // Modify/Delete pending
  virtual bool ModifyPending(ulong order_ticket, double price, double sl, double tp) = 0;
  virtual bool DeletePending(ulong order_ticket)                                     = 0;
  virtual int DeleteAllPendings(const string sym, long magic)                        = 0;
};
