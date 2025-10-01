//+------------------------------------------------------------------+
//| MultiModeSizer.mqh - ISizer adapter for flexible lot sizing      |
//| Adapts your MultiModeLotSizer logic to the ISizer interface       |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/enums/Enum.mqh>
#include <AutoTrader/domain/ports/ISizer.mqh>


//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
namespace _LotSizerEx
{
  // Giá trị (tiền) trên 1 point cho 1.00 lot.
  // MT5 cung cấp tick_value cho tick_size. Quy đổi về point:
  // money_per_point = tick_value * (point / tick_size)
  inline double MoneyPerPoint1Lot(const string symbol)
  {
    const double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    const double tick_size  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    const double point      = SymbolInfoDouble(symbol, SYMBOL_POINT);
    if(tick_value<=0.0 || tick_size<=0.0 || point<=0.0) return 0.0;
    return tick_value * (point / tick_size);
  }

  inline double NormalizeLot(const string symbol, double lot)
  {
    const double vol_min   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    const double vol_max   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    const double vol_step  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    if(vol_step<=0.0) return 0.0;

    // Snap to step (floor)
    lot = MathFloor(lot / vol_step) * vol_step;

    // Clamp to broker limits
    if(lot < vol_min) lot = vol_min;
    if(lot > vol_max) lot = vol_max;
    return lot;
  }
}

//+------------------------------------------------------------------+
//| ISizer implementation                                            |
//+------------------------------------------------------------------+
class MultiModeSizer : public ISizer
{
private:
  double              m_value;  // ý nghĩa tùy theo mode (lot | money | percent)
  ENUM_LOT_CALC_MODE  m_mode;

public:
  // value: fixed lot | fixed money | risk %
  MultiModeSizer(const double value = 0.01, const ENUM_LOT_CALC_MODE mode = CALC_MODE_FIXED)
  : m_value(value), m_mode(mode) {}

  // ISizer API:
  //  - sym:       symbol
  //  - stopPoints: khoảng SL tính theo "points" (NOT price); ví dụ 300 => 30 pips nếu _Point=0.0001
  //  - suggested:  không dùng ở đây (để tương thích chữ ký), có thể tận dụng để gợi ý lot
  //  - magic:      không dùng trong sizing, giữ để tương thích hệ thống
  virtual double Lots(const string sym, const int stopPoints, const double suggested, const long magic)
  {
    // Guard
    if(stopPoints <= 0)
    {
      // Nếu stopPoints không cung cấp, có thể fallback sang giá trị gợi ý
      if(m_mode == CALC_MODE_FIXED) return _LotSizerEx::NormalizeLot(sym, m_value);
      return 0.0;
    }

    double lot = 0.0;

    switch(m_mode)
    {
      case CALC_MODE_FIXED:
      {
        lot = m_value; // m_value là lot cố định
        break;
      }

      case CALC_MODE_FIXED_MONEY:
      {
        // m_value là số tiền rủi ro cố định
        const double money_per_point_1lot = _LotSizerEx::MoneyPerPoint1Lot(sym);
        if(money_per_point_1lot <= 0.0) return 0.0;

        // risk_money = m_value
        // risk_money = stopPoints * money_per_point_1lot * lot  => lot = risk_money / (stopPoints * money_per_point_1lot)
        lot = m_value / (stopPoints * money_per_point_1lot);
        break;
      }

      case CALC_MODE_RISK_PERCENT:
      {
        // m_value là % risk trên Balance
        const double bal = AccountInfoDouble(ACCOUNT_BALANCE);
        const double money_per_point_1lot = _LotSizerEx::MoneyPerPoint1Lot(sym);
        if(bal<=0.0 || money_per_point_1lot<=0.0) return 0.0;

        const double risk_money = bal * (m_value / 100.0);
        lot = risk_money / (stopPoints * money_per_point_1lot);
        break;
      }

      default:
      {
        lot = m_value; // fallback fixed
        break;
      }
    }

    return _LotSizerEx::NormalizeLot(sym, lot);
  }

  // Optional: setter/getter nếu cần đổi tham số lúc chạy
  void SetMode(const ENUM_LOT_CALC_MODE mode) { m_mode = mode; }
  void SetValue(const double value)           { m_value = value; }
  ENUM_LOT_CALC_MODE Mode() const             { return m_mode; }
  double Value() const                        { return m_value; }
};
