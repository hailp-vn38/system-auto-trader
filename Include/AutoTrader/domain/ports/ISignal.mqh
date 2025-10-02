

#include <AutoTrader/domain/entities/TradeSignal.mqh>

//+------------------------------------------------------------------+
//| Interface for signal generation strategies                       |
//| - ShouldEnter: Single signal (backward compatible)               |
//| - ShouldEnterMulti: Multiple signals (default calls ShouldEnter) |
//+------------------------------------------------------------------+

/**
 * @brief Interface for signal generation strategies.
 * This interface defines methods for generating trade entry signals,
 * supporting both single and multiple signal generation.
 */
class ISignal {
public:
  /**
   * @brief Checks if the signal strategy is ready to generate signals.
   * @return true if ready, false otherwise.
   */
  virtual bool IsReady() const = 0;

  //+------------------------------------------------------------------+
  //| Single signal entry (original method)                            |
  //+------------------------------------------------------------------+
  /**
   * @brief Generates a single trade entry signal.
   * @param sym The trading symbol.
   * @param tf The timeframe.
   * @param out Output parameter for the trade signal.
   * @return true if a signal was generated, false otherwise.
   */
  virtual bool ShouldEnter(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &out) = 0;

  //+------------------------------------------------------------------+
  //| Multiple signals entry (new method)                              |
  //| Default implementation: calls ShouldEnter once                   |
  //| Override this for strategies that return multiple signals        |
  //+------------------------------------------------------------------+
  /**
   * @brief Generates multiple trade entry signals.
   * Default implementation calls ShouldEnter once for backward compatibility.
   * Override for strategies that can generate multiple signals.
   * @param sym The trading symbol.
   * @param tf The timeframe.
   * @param signals Output array for the trade signals.
   * @return true if signals were generated, false otherwise.
   */
  virtual bool
  ShouldEnterMulti(const string sym, const ENUM_TIMEFRAMES tf, TradeSignal &signals[]) {
    // Default implementation: single signal behavior
    ArrayResize(signals, 1);
    return ShouldEnter(sym, tf, signals[0]);
  }
};
