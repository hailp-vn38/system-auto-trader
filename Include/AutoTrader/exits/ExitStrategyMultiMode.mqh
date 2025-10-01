//+------------------------------------------------------------------+
//| ExitTargets_MultiMode.mqh - Adapter for ExitStrategy . ITargets |
//| Updated to use IMarketData (no SymbolInfoDouble direct calls)    |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/domain/ports/ITargets.mqh>
#include <AutoTrader/domain/enums/Enum.mqh>

// --- Keep your original enums for full compatibility ---

// Base strategy interface (inline for portability)
class ExitStrategy {
public:
  virtual void Calculate(const string symbol, const bool isSell, const double entry,
                         const double sl_price, double &sl_out, double &tp_out) const
                                          = 0;
};

// Implementation backed by runtime market metadata (Point/TickSize via IMarketData)
class ExitStrategyMultiMode : public ExitStrategy {
private:
  IMarketData *m_md; // <-- injected adapter
  const double _stopValue;
  const ENUM_TARGET_CALC_MODE _stopCalcMode;
  const double _targetValue;
  const ENUM_TARGET_CALC_MODE _targetCalcMode;

  inline double _PointOf(const string sym) const { return (m_md ? m_md.Point(sym) : 0.0); }

  double CalculateTargetByMode(const string sym, const double entry, const double sl_price,
                               const bool isSell) const {
    switch(_targetCalcMode) {
    case CALC_MODE_OFF:
    case CALC_MODE_DEFAULT: return 0.0;

    case CALC_MODE_FACTOR: {
      const double diff = MathAbs(entry - sl_price) * _targetValue;
      return isSell ? (entry - diff) : (entry + diff);
    }
    case CALC_MODE_PERCENT: {
      const double diff = entry * (_targetValue / 100.0);
      return isSell ? (entry - diff) : (entry + diff);
    }
    case CALC_MODE_POINTS: {
      const double p = _PointOf(sym);
      if(p <= 0) return 0.0;
      const double diff = _targetValue * p;
      return isSell ? (entry - diff) : (entry + diff);
    }
    default: return 0.0;
    }
  }

  double CalculateStopByMode(const string sym, const double entry, const double sl_price,
                             const bool isSell) const {
    switch(_stopCalcMode) {
    case CALC_MODE_OFF: return 0.0;          // không đặt SL
    case CALC_MODE_DEFAULT: return sl_price; // dùng SL sẵn có

    case CALC_MODE_FACTOR: {
      const double diff = MathAbs(entry - sl_price) * _stopValue;
      return isSell ? (entry + diff) : (entry - diff);
    }
    case CALC_MODE_PERCENT: {
      const double diff = entry * (_stopValue / 100.0);
      return isSell ? (entry + diff) : (entry - diff);
    }
    case CALC_MODE_POINTS: { // <-- BUGFIX: dùng _stopValue (không phải _targetValue)
      const double p = _PointOf(sym);
      if(p <= 0) return sl_price;
      const double diff = _stopValue * p;
      return isSell ? (entry + diff) : (entry - diff);
    }
    default: return sl_price;
    }
  }

public:
  // Inject IMarketData*
  ExitStrategyMultiMode(IMarketData *md, const double targetValue,
                        const ENUM_TARGET_CALC_MODE targetCalcMode, const double stopValue,
                        const ENUM_TARGET_CALC_MODE stopCalcMode)
      : m_md(md), _stopValue(stopValue), _stopCalcMode(stopCalcMode), _targetValue(targetValue),
        _targetCalcMode(targetCalcMode) {}

  void Calculate(const string symbol, const bool isSell, const double entry, const double sl_price,
                 double &sl_out, double &tp_out) const override {
    // SL
    if(_stopCalcMode == CALC_MODE_DEFAULT) {
      if(sl_out <= 0) sl_out = sl_price; // giữ nguyên đầu vào nếu có, fallback sl_price
    } else {
      sl_out = CalculateStopByMode(symbol, entry, sl_price, isSell);
    }

    // TP
    if(_targetCalcMode == CALC_MODE_DEFAULT) {
      // giữ nguyên tp_out do caller truyền vào (có thể 0 để không đặt TP)
    } else {
      tp_out = CalculateTargetByMode(symbol, entry, sl_price, isSell);
    }
  }
};