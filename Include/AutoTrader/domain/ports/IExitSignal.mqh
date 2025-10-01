// Include/AutoTrader/domain/ports/IExitSignal.mqh

#include <AutoTrader/domain/ports/IPositions.mqh>

class IExitSignal {
protected:
  IPositions *m_positions; // gắn từ bên ngoài
public:
  void SetPositions(IPositions *p) { m_positions = p; }
  IExitSignal() : m_positions(NULL) {}

  // Đóng vị thế đang mở theo symbol+magic nếu thoả điều kiện
  virtual bool
  ShouldExit(const string sym, const ENUM_TIMEFRAMES tf, const long magic, ulong &tickets[])
                                          = 0;

  // Tuỳ chọn: có nên huỷ toàn bộ lệnh chờ hiện có?
  virtual bool ShouldCancelOrders(const string sym, const ENUM_TIMEFRAMES tf, const long magic) {
    return false;
  }

  virtual ~IExitSignal() {}
};
