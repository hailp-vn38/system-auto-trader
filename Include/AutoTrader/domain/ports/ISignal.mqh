

#include <AutoTrader/domain/entities/TradeSignal.mqh>
class ISignal {
public:
  virtual bool ShouldEnter(string sym, ENUM_TIMEFRAMES tf, TradeSignal &out) = 0;
};
