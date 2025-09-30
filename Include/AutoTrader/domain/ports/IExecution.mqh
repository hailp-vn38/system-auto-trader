// Include/AutoTrader/domain/ports/IExecution.mqh

class IExecution {
public:
  // Market
  virtual bool PlaceMarket(const string sym, const ENUM_ORDER_TYPE type,
                           double volume, double sl, double tp,
                           ulong &ticket_out, int deviation_points, long magic) = 0;
  virtual bool ModifySLTPBySymbolMagic(const string sym, long magic, double sl, double tp) = 0;
  virtual int  CloseAllBySymbolMagic(const string sym, long magic) = 0;

  // Pending (BuyStop/SellStop/BuyLimit/SellLimit)
  virtual bool PlaceStop (const string sym, bool isSell, double volume, double price,
                          double sl, double tp, long magic, ulong &ticket_out) = 0;
  virtual bool PlaceLimit(const string sym, bool isSell, double volume, double price,
                          double sl, double tp, long magic, ulong &ticket_out) = 0;

  // Modify/Delete pending
  virtual bool ModifyPending(ulong order_ticket, double price, double sl, double tp) = 0;
  virtual bool DeletePending(ulong order_ticket) = 0;
  virtual int  DeleteAllPendingsBySymbolMagic(const string sym, long magic) = 0;
};
