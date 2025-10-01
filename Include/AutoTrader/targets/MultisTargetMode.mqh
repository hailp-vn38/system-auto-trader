#include <AutoTrader/exits/ExitStrategyMultiMode.mqh>

//==================== Adapter to ITargets ====================//
class MultisTargetMode : public ITargets {
private:
  IMarketData *m_md; // for TickSize/Point snaps
  ExitStrategyMultiMode m_impl;

  // Snap price to tick size to avoid "Invalid stops"
  inline double SnapToTick(const string sym, const double price) const {
    if(!m_md) return price;
    const double tick = m_md.TickSize(sym);
    if(tick <= 0) return price;
    const double steps = MathRound(price / tick);
    return steps * tick;
  }

public:
  // Pass IMarketData* through to strategy and for snapping
  MultisTargetMode(IMarketData *md, const double targetValue,
                    const ENUM_TARGET_CALC_MODE targetMode, const double stopValue,
                    const ENUM_TARGET_CALC_MODE stopMode)
      : m_md(md), m_impl(md, targetValue, targetMode, stopValue, stopMode) {}

  // ITargets::Compute
  bool Compute(const string sym, const bool isSell, const double entry, const double sl_in,
               double &sl_out, double &tp_out) override {
    double sl = sl_out, tp = tp_out;
    m_impl.Calculate(sym, isSell, entry, sl_in, sl, tp);

    // Chuẩn hóa theo tick_size
    if(sl > 0) sl = SnapToTick(sym, sl);
    if(tp > 0) tp = SnapToTick(sym, tp);

    sl_out = sl;
    tp_out = tp;
    return (sl_out > 0 || tp_out > 0);
  }
};
