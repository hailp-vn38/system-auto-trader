# Exit Signal và Orders Integration - Hướng dẫn

## Tổng quan thay đổi

**Trước đây:** `Orchestrator` phải quản lý 3 concerns:
- `IOrders` - query pending orders
- `IExitSignal` - điều kiện cancel  
- `IExecution` - thực thi delete

**Hiện tại:** `IExitSignal` tự chứa toàn bộ logic về orders:
- `m_orders` được inject vào exit strategy
- Exit strategy tự quyết định orders nào cần cancel
- `Orchestrator` chỉ thực thi cancellation

---

## Kiến trúc mới

### 1. IExitSignal Interface

```cpp
class IExitSignal {
protected:
  IPositions *m_positions;  // Adapter cho positions
  IOrders *m_orders;        // Adapter cho pending orders

public:
  void SetPositions(IPositions *p);
  void SetOrders(IOrders *o);  // ← MỚI
  
  // Quyết định đóng vị thế nào
  virtual bool ShouldExit(const string sym, const ENUM_TIMEFRAMES tf, 
                          const long magic, ulong &tickets[]) = 0;
  
  // Quyết định có nên cancel orders không
  virtual bool ShouldCancelOrders(const string sym, const ENUM_TIMEFRAMES tf, 
                                  const long magic);
  
  // ← MỚI: Lấy danh sách tickets cần cancel
  virtual bool GetOrdersToCancel(const string sym, const ENUM_TIMEFRAMES tf,
                                 const long magic, ulong &tickets[]);
};
```

### 2. Orchestrator đơn giản hóa

```cpp
bool HandleOrderCancellation() {
  if(m_exitSig == NULL) return false;
  
  // Exit strategy tự query và quyết định
  ulong cancelTickets[];
  if(!m_exitSig.GetOrdersToCancel(m_sym, m_tf, m_magic, cancelTickets)) 
    return false;
  
  // Orchestrator chỉ thực thi
  int deleted = 0;
  for(int i = 0; i < ArraySize(cancelTickets); i++) {
    if(m_exec.DeletePending(cancelTickets[i])) deleted++;
  }
  
  return deleted > 0;
}
```

**Loại bỏ:**
- `IOrders *m_orders` từ Orchestrator
- `SetOrders()` method
- Logic kiểm tra `m_orders.FirstBySymbolMagic()`

---

## Ưu điểm

### ✅ Single Responsibility
- Exit strategy chịu trách nhiệm TẤT CẢ exit logic (positions + orders)
- Orchestrator chỉ điều phối và thực thi

### ✅ Cohesion cao
- Orders và positions luôn được xem xét cùng nhau trong exit context
- Ví dụ: Range breakout cancel orders khi breakout ngược

### ✅ Giảm coupling
- Orchestrator không cần biết về IOrders
- Giảm dependencies từ 9 xuống 8

### ✅ Flexibility
- Mỗi exit strategy tự quyết định cancel logic
- Có thể selective cancel (chỉ một số orders)

### ✅ Testability
- Test exit strategy độc lập với orchestrator
- Mock IOrders dễ dàng

---

## Cách sử dụng

### Ví dụ 1: Cancel tất cả orders (default behavior)

```cpp
class Exit_TimeBasedSimple : public IExitSignal {
public:
  bool ShouldCancelOrders(const string sym, const ENUM_TIMEFRAMES tf, 
                          const long magic) override {
    // Logic đơn giản: cancel sau 1 giờ
    datetime now = TimeCurrent();
    datetime sessionStart = GetSessionStart();
    return (now - sessionStart > 3600); // 1 giờ
  }
  
  // Không cần override GetOrdersToCancel()
  // Default implementation sẽ cancel tất cả orders
};
```

**Setup:**
```cpp
Mt5OrdersAdapter ordersAdapter;
Exit_TimeBasedSimple exitStrat;

exitStrat.SetOrders(&ordersAdapter);  // ← Inject IOrders
exitStrat.SetPositions(&posAdapter);

orchestrator.SetExitSignal(&exitStrat);
```

---

### Ví dụ 2: Selective cancellation (override GetOrdersToCancel)

```cpp
class Exit_RangeBreakout : public IExitSignal {
private:
  double m_rangeHigh;
  double m_rangeLow;
  
public:
  bool GetOrdersToCancel(const string sym, const ENUM_TIMEFRAMES tf,
                         const long magic, ulong &tickets[]) override {
    if(m_orders == NULL) return false;
    
    double currentPrice = SymbolInfoDouble(sym, SYMBOL_BID);
    
    // Chỉ cancel orders nếu giá breakout ngược
    bool breakoutUp = (currentPrice > m_rangeHigh);
    bool breakoutDown = (currentPrice < m_rangeLow);
    
    if(!breakoutUp && !breakoutDown) return false;
    
    // Lấy tất cả orders
    OrderInfo orders[];
    int count = m_orders.ListBySymbolMagic(sym, magic, orders);
    if(count <= 0) return false;
    
    // Filter: chỉ cancel orders ngược chiều breakout
    int cancelCount = 0;
    ArrayResize(tickets, count);
    
    for(int i = 0; i < count; i++) {
      bool isBuyOrder = (orders[i].type == ORDER_TYPE_BUY_STOP || 
                         orders[i].type == ORDER_TYPE_BUY_LIMIT);
      
      // Cancel buy orders nếu breakout down
      if(breakoutDown && isBuyOrder) {
        tickets[cancelCount++] = orders[i].ticket;
      }
      // Cancel sell orders nếu breakout up
      else if(breakoutUp && !isBuyOrder) {
        tickets[cancelCount++] = orders[i].ticket;
      }
    }
    
    ArrayResize(tickets, cancelCount);
    return cancelCount > 0;
  }
};
```

---

### Ví dụ 3: Exit positions và cancel orders cùng lúc

```cpp
class Exit_EmaCrossReverse : public IExitSignal {
private:
  int m_hFast, m_hSlow;
  
public:
  bool ShouldExit(const string sym, const ENUM_TIMEFRAMES tf,
                  const long magic, ulong &tickets[]) override {
    // Đóng positions khi MA cross ngược
    if(m_positions == NULL) return false;
    
    double fast[2], slow[2];
    if(CopyBuffer(m_hFast, 0, 0, 2, fast) != 2) return false;
    if(CopyBuffer(m_hSlow, 0, 0, 2, slow) != 2) return false;
    
    bool crossHappened = (fast[1] > slow[1] && fast[0] < slow[0]) ||
                         (fast[1] < slow[1] && fast[0] > slow[0]);
    
    if(!crossHappened) return false;
    
    // Lấy tất cả positions
    return m_positions.ListBySymbolMagic(sym, magic, tickets);
  }
  
  bool ShouldCancelOrders(const string sym, const ENUM_TIMEFRAMES tf,
                          const long magic) override {
    // Cancel orders khi MA cross (cùng điều kiện với exit)
    double fast[2], slow[2];
    if(CopyBuffer(m_hFast, 0, 0, 2, fast) != 2) return false;
    if(CopyBuffer(m_hSlow, 0, 0, 2, slow) != 2) return false;
    
    return (fast[1] > slow[1] && fast[0] < slow[0]) ||
           (fast[1] < slow[1] && fast[0] > slow[0]);
  }
  
  // Default GetOrdersToCancel() sẽ cancel tất cả orders
};
```

---

## Migration Guide

### Bước 1: Cập nhật Exit Strategy

**Trước:**
```cpp
class MyExitStrategy : public IExitSignal {
public:
  bool ShouldCancelOrders(...) override {
    // Logic ở đây nhưng không access được orders
    return false;
  }
};
```

**Sau:**
```cpp
class MyExitStrategy : public IExitSignal {
public:
  bool ShouldCancelOrders(...) override {
    // Bây giờ có thể dùng m_orders
    if(m_orders == NULL) return false;
    
    int count = m_orders.CountBySymbolMagic(sym, magic);
    return count > 0; // Ví dụ logic
  }
  
  // Optional: override GetOrdersToCancel() cho selective cancel
};
```

### Bước 2: Cập nhật EA Setup

**Trước:**
```cpp
Mt5OrdersAdapter ordersAdapter;
orchestrator.SetOrders(&ordersAdapter);  // ← XÓA dòng này
```

**Sau:**
```cpp
Mt5OrdersAdapter ordersAdapter;

// Inject vào exit strategy thay vì orchestrator
exitStrategy.SetOrders(&ordersAdapter);  // ← MỚI
exitStrategy.SetPositions(&posAdapter);

orchestrator.SetExitSignal(&exitStrategy);
```

### Bước 3: Compile và test

```bash
./compile_mql5.sh Experts/AutoTrader/AutoTraderEA.mq5
```

---

## Testing

### Unit test Exit Strategy

```cpp
// Mock IOrders
class MockOrders : public IOrders {
  // Implement interface với test data
};

void TestExitStrategy() {
  MockOrders mockOrders;
  MyExitStrategy exitStrat;
  
  exitStrat.SetOrders(&mockOrders);
  
  ulong tickets[];
  bool result = exitStrat.GetOrdersToCancel("EURUSD", PERIOD_H1, 12345, tickets);
  
  // Assert expectations
}
```

---

## Best Practices

### ✅ DO:
- Inject `IOrders` vào exit strategy ngay sau khi tạo
- Override `GetOrdersToCancel()` cho selective cancellation
- Kiểm tra `m_orders != NULL` trước khi dùng
- Log orders bị cancel để debug

### ❌ DON'T:
- ~~Inject IOrders vào Orchestrator~~ (không còn cần)
- ~~Query orders từ bên ngoài exit strategy~~
- Quên check `m_orders` null pointer

---

## FAQ

**Q: Tại sao không giữ IOrders trong Orchestrator?**  
A: Violates Single Responsibility. Exit logic nên tự chứa tất cả exit decisions.

**Q: Có bắt buộc phải override GetOrdersToCancel() không?**  
A: Không. Default implementation cancel tất cả nếu `ShouldCancelOrders()` = true.

**Q: Làm sao để không cancel orders?**  
A: Không override `ShouldCancelOrders()` hoặc return false.

**Q: Performance có bị ảnh hưởng không?**  
A: Không. Logic tương đương, chỉ di chuyển vị trí code.

---

## Tài liệu liên quan

- `Docs/orchestrator_docs.md` - Orchestrator pipeline
- `Include/AutoTrader/domain/ports/IExitSignal.mqh` - Interface definition
- `Include/AutoTrader/domain/ports/IOrders.mqh` - Orders interface
