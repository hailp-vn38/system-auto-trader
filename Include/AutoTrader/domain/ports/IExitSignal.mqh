// Include/AutoTrader/domain/ports/IExitSignal.mqh
class IExitSignal {
public:
  // Đóng vị thế đang mở
  virtual bool ShouldExit(const string sym, ENUM_TIMEFRAMES tf, long magic) = 0;

  // MỚI: Đóng/cancel pending orders hiện hữu
  // return true => hủy toàn bộ; hoặc bạn có thể mở rộng để trả về danh sách chọn lọc
  virtual bool ShouldCancelOrders(const string sym, ENUM_TIMEFRAMES tf, long magic) {
    return false;
  }
};