// Include/AutoTrader/domain/ports/IPositions.mqh

struct PositionInfo {
  ulong ticket;
  string symbol;
  long magic;
  long type; // POSITION_TYPE_*
  double volume;
  double price_open;
  double price_current;
  double sl;
  double tp;
};

class IPositions {
public:
  virtual int Total()                                                                    = 0;
  virtual bool Current(PositionInfo &out)                                                = 0;
  virtual bool FirstBySymbolMagic(const string sym, const long magic, PositionInfo &out) = 0;
  virtual int CountBySymbolMagic(const string sym, const long magic)                     = 0;
  // virtual bool   ForEach(function bool(const PositionInfo &p) fn) = 0; // optional (nếu bạn thích)
};
