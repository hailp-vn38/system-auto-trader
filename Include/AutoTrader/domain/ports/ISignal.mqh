

#include <AutoTrader/domain/entities/TradeSignal.mqh>

//+------------------------------------------------------------------+
//| Interface for signal generation strategies                       |
//| - ShouldEnter: Single signal (backward compatible)               |
//| - ShouldEnterMulti: Multiple signals (default calls ShouldEnter) |
//+------------------------------------------------------------------+
class ISignal {
public:
  virtual bool IsReady() const = 0;

  //+------------------------------------------------------------------+
  //| Single signal entry (original method)                            |
  //+------------------------------------------------------------------+
  virtual bool ShouldEnter(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &out) = 0;

  //+------------------------------------------------------------------+
  //| Multiple signals entry (new method)                              |
  //| Default implementation: calls ShouldEnter once                   |
  //| Override this for strategies that return multiple signals        |
  //+------------------------------------------------------------------+
  virtual bool
  ShouldEnterMulti(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &signals[]) {
    // Default implementation: single signal behavior
    ArrayResize(signals, 1);
    return ShouldEnter(sym, tf, signals[0]);
  }
};
