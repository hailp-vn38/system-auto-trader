// Include/AutoTrader/domain/ports/IStorage.mqh


class IStorage {
public:
  // ==== Trades (đã có từ trước) ====================================
  virtual void SaveTradeOpen(const string sym, long magic, ulong ticket,
                             ENUM_ORDER_TYPE order_type, double volume, double price,
                             double sl, double tp, datetime ts) = 0;

  virtual void SaveTradeClose(const string sym, long magic, ulong ticket,
                              double close_price, double profit, datetime ts,
                              const string reason) = 0;

  virtual void SaveTrailing(const string sym, long magic, ulong ticket,
                            double new_sl, datetime ts) = 0;

  // (tuỳ chọn) partial close nếu bạn dùng:
  virtual void SavePartialClose(const string sym, long magic, ulong ticket,
                                double closed_volume, double price, double profit,
                                datetime ts) { /* default no-op */ }

  // ==== Orders (MỚI) ===============================================
  // Ghi nhận khi đặt lệnh chờ (Stop/Limit)
  virtual void SaveOrderOpen(const string sym, long magic, ulong order_ticket,
                             ENUM_ORDER_TYPE order_type, double volume, double price,
                             double sl, double tp, datetime ts) { /* default no-op */ }

  // Ghi nhận khi sửa lệnh chờ
  virtual void SaveOrderModify(const string sym, long magic, ulong order_ticket,
                               double new_price, double new_sl, double new_tp,
                               datetime ts) { /* default no-op */ }

  // Ghi nhận khi huỷ lệnh chờ
  virtual void SaveOrderCancel(const string sym, long magic, ulong order_ticket,
                               const string reason, datetime ts) { /* default no-op */ }

  // Ghi nhận khi lệnh chờ khớp (fill) -> có thể kèm ticket vị thế mới
  virtual void SaveOrderFilled(const string sym, long magic, ulong order_ticket,
                               ulong position_ticket, double fill_price, double volume,
                               datetime ts) { /* default no-op */ }

  // ==== Flush =======================================================
  virtual void Flush() = 0;
};
