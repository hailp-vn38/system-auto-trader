// Include/AutoTrader/adapters/storage/NullStorage.mqh

#include <AutoTrader/domain/ports/IStorage.mqh>

class NullStorage : public IStorage {
public:
  void SaveTradeOpen(const string, long, ulong, ENUM_ORDER_TYPE, double, double, double, double,
                     datetime) override {}
  void SaveTradeClose(const string, long, ulong, double, double, datetime, const string) override {}
  void SaveTrailing(const string, long, ulong, double, datetime) override {}
  void Flush() override {}
  // Các SaveOrder* dùng mặc định no-op ở base class, không cần override
};
