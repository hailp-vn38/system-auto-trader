//+------------------------------------------------------------------+
//| Include/AutoTrader/risk/Risk_AllowOneOpen.mqh                    |
//| Chỉ cho phép 1 position open theo symbol + magic                 |
//+------------------------------------------------------------------+

#include <AutoTrader/domain/ports/IPositions.mqh>
#include <AutoTrader/domain/ports/IRisk.mqh>

class Risk_AllowOneOpen : public IRisk {
private:
  IPositions *m_positions; // adapter vị thế (Mt5PositionsAdapter)
  int m_cap;               // số vị thế tối đa cho phép (mặc định = 1)

public:
  Risk_AllowOneOpen(IPositions *positions, const int cap = 1)
      : m_positions(positions), m_cap(cap) {}

  // Chặn mở thêm nếu đã đủ m_cap vị thế cho symbol+magic
  bool AllowTrade(const string sym, const long magic) override {
    if(m_cap <= 0) return false;         // không cho phép giao dịch
    if(m_positions == NULL) return true; // nếu chưa gắn adapter -> không chặn

    // Đếm nhanh bằng cách lấy 1 phần tử (early exit)
    const int found = m_positions.CountBySymbolMagic(sym, magic);
    return (found < m_cap);
  }
};
