# Hướng Dẫn Tạo Signal Strategy

## Tổng Quan

Signal Strategy là thành phần chịu trách nhiệm phát hiện điều kiện vào lệnh trong hệ thống AutoTrader. Mỗi strategy phải implement interface `ISignal` và đặt trong thư mục `Include/AutoTrader/strategies/`.

## Kiến Trúc Signal

### Interface ISignal

Signal phải implement interface `ISignal` với các phương thức:

- **`IsReady()`**: Kiểm tra strategy đã sẵn sàng hoạt động
- **`ShouldEnter()`**: Sinh **một** signal (single entry)
- **`ShouldEnterMulti()`**: Sinh **nhiều** signal (multiple entries - pyramid, grid, etc.)

### Cấu Trúc TradeSignal

```cpp
struct TradeSignal {
  bool valid;                // Signal có hợp lệ không
  ENUM_TRADE_TYPE type;      // Loại lệnh (BUY, SELL, BUY_STOP, SELL_LIMIT, etc.)
  bool isSell;               // true = SELL, false = BUY
  bool isOrderPending;       // true = pending order, false = market order
  
  double price;              // Giá vào lệnh
  double sl;                 // Stop Loss
  double tp;                 // Take Profit
  int stopPoints;            // Khoảng cách SL (points) - dùng cho Sizer
  string comment;            // Comment cho lệnh
}
```

### ENUM_TRADE_TYPE

```cpp
TRADE_TYPE_BUY          // Market Buy
TRADE_TYPE_SELL         // Market Sell
TRADE_TYPE_BUY_LIMIT    // Buy Limit
TRADE_TYPE_SELL_LIMIT   // Sell Limit
TRADE_TYPE_BUY_STOP     // Buy Stop
TRADE_TYPE_SELL_STOP    // Sell Stop
```

---

## Bước 1: Tạo File Signal

### Vị trí file
```
Include/AutoTrader/strategies/YourStrategyName.mqh
```

### Naming Convention
- File: `snake_case.mqh`
- Class: `PascalCase` hoặc `Strat_StrategyName`
- Ví dụ: `EmaCross21x50.mqh`, `Strat_SwingStructure.mqh`

---

## Bước 2: Template Cơ Bản

### Single Entry Strategy (Market Order)

```cpp
#property strict

#include <AutoTrader/domain/ports/ISignal.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>

//+------------------------------------------------------------------+
//| Your Strategy Name                                                |
//| Mô tả ngắn gọn về chiến lược                                      |
//+------------------------------------------------------------------+
class YourStrategyName : public ISignal {
private:
  // Dependencies
  IMarketData *m_md;
  
  // Parameters
  string m_sym;
  ENUM_TIMEFRAMES m_tf;
  
  // Indicator handles
  int m_hIndicator;
  
  // Strategy state
  datetime m_lastCheck;

public:
  //+------------------------------------------------------------------+
  //| Constructor                                                       |
  //+------------------------------------------------------------------+
  YourStrategyName(IMarketData *md, const string sym, const ENUM_TIMEFRAMES tf, 
                   const int param1 = 14)
      : m_md(md), m_sym(sym), m_tf(tf), m_hIndicator(INVALID_HANDLE), 
        m_lastCheck(0) {
    
    // Initialize indicators
    m_hIndicator = iYourIndicator(m_sym, m_tf, param1);
    
    // Add to chart for visualization (optional)
    if(m_hIndicator != INVALID_HANDLE) {
      ChartIndicatorAdd(0, 0, m_hIndicator);
    }
  }

  //+------------------------------------------------------------------+
  //| Destructor                                                        |
  //+------------------------------------------------------------------+
  ~YourStrategyName() {
    if(m_hIndicator != INVALID_HANDLE) {
      IndicatorRelease(m_hIndicator);
    }
  }

  //+------------------------------------------------------------------+
  //| Check if strategy is ready                                       |
  //+------------------------------------------------------------------+
  bool IsReady() const override {
    return (m_md != NULL && m_hIndicator != INVALID_HANDLE);
  }

  //+------------------------------------------------------------------+
  //| Single signal entry (Market Order)                               |
  //+------------------------------------------------------------------+
  bool ShouldEnter(const string sym, const ENUM_TIMEFRAMES tf, 
                   TradeSignal &out) override {
    // 1. Validate inputs
    if(sym != m_sym || tf != m_tf) return false;
    if(!IsReady()) return false;

    // 2. Check once per bar (optional)
    datetime barTime = iTime(m_sym, m_tf, 0);
    if(barTime <= m_lastCheck) return false;
    m_lastCheck = barTime;

    // 3. Read indicator values
    double buffer[2];
    if(CopyBuffer(m_hIndicator, 0, 0, 2, buffer) != 2) return false;
    
    double current = buffer[0];
    double previous = buffer[1];
    
    if(current == EMPTY_VALUE || previous == EMPTY_VALUE) return false;

    // 4. Detect entry condition
    bool buySignal = false;  // Your logic here
    bool sellSignal = false; // Your logic here
    
    if(!buySignal && !sellSignal) {
      out.valid = false;
      return false;
    }

    // 5. Build signal
    out.valid = true;
    out.type = buySignal ? TRADE_TYPE_BUY : TRADE_TYPE_SELL;
    out.isSell = sellSignal;
    out.isOrderPending = false; // Market order
    
    // Price (for market order, can be 0 or current price)
    out.price = 0.0;
    
    // SL/TP - set 0 if using ITargets
    out.sl = 0.0;
    out.tp = 0.0;
    out.stopPoints = 0; // Or calculate based on your logic
    
    out.comment = "YourStrategy";

    return true;
  }
};
```

---

## Bước 3: Template Nâng Cao

### Multiple Entry Strategy (Pending Orders)

```cpp
#property strict

#include <AutoTrader/domain/ports/ISignal.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>

//+------------------------------------------------------------------+
//| Multi-Entry Strategy (Pyramid/Grid)                              |
//+------------------------------------------------------------------+
class YourMultiEntryStrategy : public ISignal {
private:
  IMarketData *m_md;
  string m_sym;
  ENUM_TIMEFRAMES m_tf;
  
  int m_hIndicator;
  int m_numEntries;         // Số lượng lệnh
  double m_levelStepPips;   // Khoảng cách giữa các lệnh
  
  datetime m_lastCheck;

public:
  //+------------------------------------------------------------------+
  //| Constructor                                                       |
  //+------------------------------------------------------------------+
  YourMultiEntryStrategy(IMarketData *md, const string sym, 
                         const ENUM_TIMEFRAMES tf,
                         const int numEntries = 3, 
                         const double levelStepPips = 20.0)
      : m_md(md), m_sym(sym), m_tf(tf), m_numEntries(numEntries),
        m_levelStepPips(levelStepPips), m_hIndicator(INVALID_HANDLE),
        m_lastCheck(0) {
    
    m_hIndicator = iYourIndicator(m_sym, m_tf);
    if(m_hIndicator != INVALID_HANDLE) {
      ChartIndicatorAdd(0, 0, m_hIndicator);
    }
  }

  //+------------------------------------------------------------------+
  //| Destructor                                                        |
  //+------------------------------------------------------------------+
  ~YourMultiEntryStrategy() {
    if(m_hIndicator != INVALID_HANDLE) {
      IndicatorRelease(m_hIndicator);
    }
  }

  //+------------------------------------------------------------------+
  //| Check ready                                                       |
  //+------------------------------------------------------------------+
  bool IsReady() const override {
    return (m_md != NULL && m_hIndicator != INVALID_HANDLE);
  }

  //+------------------------------------------------------------------+
  //| Single entry (backward compatible)                               |
  //+------------------------------------------------------------------+
  bool ShouldEnter(const string sym, const ENUM_TIMEFRAMES tf, 
                   TradeSignal &out) override {
    TradeSignal signals[];
    if(!ShouldEnterMulti(sym, tf, signals)) return false;
    if(ArraySize(signals) == 0) return false;
    
    out = signals[0];
    return true;
  }

  //+------------------------------------------------------------------+
  //| Multiple entries logic                                            |
  //+------------------------------------------------------------------+
  bool ShouldEnterMulti(const string sym, const ENUM_TIMEFRAMES tf, 
                        TradeSignal &signals[]) override {
    // 1. Validate
    if(sym != m_sym || tf != m_tf) return false;
    if(!IsReady()) return false;

    // 2. Check once per bar
    datetime barTime = iTime(m_sym, m_tf, 0);
    if(barTime <= m_lastCheck) return false;
    m_lastCheck = barTime;

    // 3. Check entry condition
    bool shouldEnter = false; // Your logic here
    if(!shouldEnter) return false;

    // 4. Calculate pip size
    double point = SymbolInfoDouble(m_sym, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(m_sym, SYMBOL_DIGITS);
    double pipSize = (digits == 3 || digits == 5) ? point * 10 : point;

    // 5. Get current price
    double currentPrice = m_md.Ask(m_sym);
    if(currentPrice <= 0) return false;

    // 6. Build multiple signals
    ArrayResize(signals, m_numEntries);

    for(int i = 0; i < m_numEntries; i++) {
      signals[i].valid = true;
      signals[i].isSell = false; // BUY example
      signals[i].isOrderPending = true;
      signals[i].type = TRADE_TYPE_BUY_STOP;
      
      // Each level price
      double offset = (i + 1) * m_levelStepPips * pipSize;
      signals[i].price = NormalizeDouble(currentPrice + offset, digits);
      
      // SL/TP
      signals[i].sl = NormalizeDouble(currentPrice - 100 * pipSize, digits);
      signals[i].tp = NormalizeDouble(signals[i].price + 200 * pipSize, digits);
      
      signals[i].stopPoints = 1000; // 100 pips
      signals[i].comment = StringFormat("Level_%d", i + 1);
      
      Print("Entry[", i, "] BUY_STOP @ ", signals[i].price, 
            " SL=", signals[i].sl, " TP=", signals[i].tp);
    }

    return true;
  }
};
```

---

## Bước 4: Các Pattern Thường Dùng

### 4.1. Đọc Indicator Buffer

```cpp
// Đọc 1 giá trị
double buffer[1];
if(CopyBuffer(m_hIndicator, 0, 0, 1, buffer) != 1) return false;
double current = buffer[0];

// Đọc 2 giá trị (current + previous)
double buffer[2];
if(CopyBuffer(m_hIndicator, 0, 0, 2, buffer) != 2) return false;
double current = buffer[0];
double previous = buffer[1];

// Đọc nhiều buffer
double buffer1[2], buffer2[2];
if(CopyBuffer(m_hIndicator, 0, 0, 2, buffer1) != 2) return false;
if(CopyBuffer(m_hIndicator, 1, 0, 2, buffer2) != 2) return false;
```

### 4.2. Cross Detection

```cpp
// Bullish cross (fast crosses above slow)
bool crossUp = (fast_prev <= slow_prev) && (fast_curr > slow_curr);

// Bearish cross (fast crosses below slow)
bool crossDown = (fast_prev >= slow_prev) && (fast_curr < slow_curr);
```

### 4.3. Kiểm Tra Once Per Bar

```cpp
datetime m_lastCheck = 0;

bool ShouldEnter(...) {
  datetime barTime = iTime(m_sym, m_tf, 0);
  if(barTime <= m_lastCheck) return false;
  m_lastCheck = barTime;
  
  // Your logic here
}
```

### 4.4. Tính Pip Size

```cpp
double point = SymbolInfoDouble(m_sym, SYMBOL_POINT);
int digits = (int)SymbolInfoInteger(m_sym, SYMBOL_DIGITS);
double pipSize = (digits == 3 || digits == 5) ? point * 10 : point;

// Ví dụ: 50 pips
double distance = 50 * pipSize;
```

### 4.5. Normalize Price

```cpp
int digits = (int)SymbolInfoInteger(m_sym, SYMBOL_DIGITS);
double price = NormalizeDouble(rawPrice, digits);
```

---

## Bước 5: Tích Hợp Vào EA

### 5.1. Khai Báo Trong EA

```cpp
// In EA file (e.g., ExampleEa.mq5)
#include <AutoTrader/strategies/YourStrategyName.mqh>

// Global or class member
YourStrategyName *g_signal = NULL;
```

### 5.2. Khởi Tạo Trong OnInit

```cpp
int OnInit() {
  // Initialize dependencies
  IMarketData *md = new Mt5MarketDataAdapter();
  
  // Create signal
  g_signal = new YourStrategyName(md, _Symbol, _Period, 14);
  
  if(!g_signal.IsReady()) {
    Print("ERROR: Signal not ready!");
    return INIT_FAILED;
  }
  
  return INIT_SUCCEEDED;
}
```

### 5.3. Sử Dụng Trong OnTick

```cpp
void OnTick() {
  // Single entry
  TradeSignal signal;
  if(g_signal.ShouldEnter(_Symbol, _Period, signal)) {
    if(signal.valid) {
      Print("Signal detected: ", EnumToString(signal.type));
      // Execute trade...
    }
  }
  
  // Multiple entries
  TradeSignal signals[];
  if(g_signal.ShouldEnterMulti(_Symbol, _Period, signals)) {
    for(int i = 0; i < ArraySize(signals); i++) {
      if(signals[i].valid) {
        Print("Signal[", i, "] detected");
        // Execute each trade...
      }
    }
  }
}
```

### 5.4. Cleanup Trong OnDeinit

```cpp
void OnDeinit(const int reason) {
  if(g_signal != NULL) {
    delete g_signal;
    g_signal = NULL;
  }
}
```

---

## Bước 6: Best Practices

### ✅ Nên Làm

1. **Validate inputs** trong `ShouldEnter()`:
   ```cpp
   if(sym != m_sym || tf != m_tf) return false;
   if(!IsReady()) return false;
   ```

2. **Check EMPTY_VALUE** từ indicator:
   ```cpp
   if(buffer[0] == EMPTY_VALUE) return false;
   ```

3. **Kiểm tra once per bar** nếu cần:
   ```cpp
   datetime barTime = iTime(m_sym, m_tf, 0);
   if(barTime <= m_lastCheck) return false;
   ```

4. **Release indicator handles** trong destructor:
   ```cpp
   ~YourStrategy() {
     if(m_hIndicator != INVALID_HANDLE) {
       IndicatorRelease(m_hIndicator);
     }
   }
   ```

5. **Normalize prices** trước khi set:
   ```cpp
   int digits = (int)SymbolInfoInteger(m_sym, SYMBOL_DIGITS);
   out.price = NormalizeDouble(price, digits);
   ```

6. **Set `out.valid = false`** khi không có signal:
   ```cpp
   if(!condition) {
     out.valid = false;
     return false;
   }
   ```

7. **Comment rõ ràng** cho logic phức tạp

8. **Sử dụng IMarketData** thay vì gọi trực tiếp MT5 API

### ❌ Không Nên

1. ❌ Gọi OrderSend/PositionSelect trong Signal
2. ❌ Thay đổi chart hoặc global state
3. ❌ Return signal mà không set `valid = true`
4. ❌ Quên release indicator handles
5. ❌ Hard-code symbol/timeframe (dùng m_sym, m_tf)
6. ❌ Tạo nhiều handle cho cùng indicator
7. ❌ Quên check `IsReady()` trước khi xử lý

---

## Bước 7: Testing & Debugging

### 7.1. Unit Test Script

Tạo script test trong `Scripts/UnitTests/Test_YourStrategy.mq5`:

```cpp
#include <AutoTrader/strategies/YourStrategyName.mqh>
#include <AutoTrader/adapters/mt5/Mt5MarketDataAdapter.mqh>

void OnStart() {
  // Setup
  IMarketData *md = new Mt5MarketDataAdapter();
  YourStrategyName *signal = new YourStrategyName(md, _Symbol, _Period);
  
  if(!signal.IsReady()) {
    Print("ERROR: Strategy not ready");
    return;
  }
  
  // Test
  TradeSignal sig;
  bool result = signal.ShouldEnter(_Symbol, _Period, sig);
  
  Print("Signal result: ", result);
  Print("Signal valid: ", sig.valid);
  if(sig.valid) {
    Print("Type: ", EnumToString(sig.type));
    Print("Price: ", sig.price);
    Print("SL: ", sig.sl);
    Print("TP: ", sig.tp);
  }
  
  // Cleanup
  delete signal;
  delete md;
}
```

### 7.2. Compile & Check

```bash
# Check syntax
./check_mql5.sh "Include/AutoTrader/strategies/YourStrategyName.mqh"

# Compile test script
./check_mql5.sh "Scripts/UnitTests/Test_YourStrategy.mq5"
```

### 7.3. Strategy Tester

1. Tích hợp signal vào EA
2. Chạy Strategy Tester trong MT5
3. Kiểm tra signals trong logs
4. Verify visual backtest

---

## Ví Dụ Thực Tế

### Ví Dụ 1: MA Cross Strategy

**File**: `Include/AutoTrader/strategies/EmaCross21x50.mqh`

Xem source code đầy đủ trong attachment hoặc file có sẵn.

**Đặc điểm**:
- Single entry
- Market order
- Cross detection logic
- Đơn giản, phù hợp cho beginner

### Ví Dụ 2: Pyramid Entry Strategy

**File**: `Include/AutoTrader/strategies/PyramidEntry.mqh`

Xem source code đầy đủ trong attachment hoặc file có sẵn.

**Đặc điểm**:
- Multiple entries
- Pending orders (BUY_STOP)
- Scale-in strategy
- Phức tạp hơn, phù hợp cho advanced

### Ví Dụ 3: Range Breakout

**File**: `Include/AutoTrader/strategies/RangeBreakout.mqh`

**Logic**:
- Detect range (high/low trong N bars)
- Breakout = BUY_STOP trên high, SELL_STOP dưới low
- Single hoặc multi entry

---

## Checklist Hoàn Thành

Khi tạo signal mới, kiểm tra:

- [ ] File đặt trong `Include/AutoTrader/strategies/`
- [ ] Class kế thừa `ISignal`
- [ ] Implement `IsReady()`
- [ ] Implement `ShouldEnter()` (single entry)
- [ ] Implement `ShouldEnterMulti()` (nếu cần multiple entries)
- [ ] Constructor nhận dependencies qua injection
- [ ] Destructor release indicator handles
- [ ] Validate inputs trong mỗi method
- [ ] Check `EMPTY_VALUE` từ indicators
- [ ] Normalize prices trước khi set
- [ ] Set `out.valid = false` khi không có signal
- [ ] Comment rõ ràng logic
- [ ] Tạo unit test script
- [ ] Compile thành công không lỗi
- [ ] Test trong Strategy Tester
- [ ] Document usage trong EA example

---

## Tài Liệu Tham Khảo

- **ISignal Interface**: `Include/AutoTrader/domain/ports/ISignal.mqh`
- **TradeSignal Struct**: `Include/AutoTrader/domain/entities/TradeSignal.mqh`
- **Enums**: `Include/AutoTrader/domain/enums/Enum.mqh`
- **IMarketData**: `Include/AutoTrader/domain/ports/IMarketData.mqh`
- **Example Strategies**: `Include/AutoTrader/strategies/`
- **Orchestrator Pipeline**: `Include/AutoTrader/app/Orchestrator.mqh`

---

## Hỗ Trợ

Nếu gặp vấn đề:
1. Kiểm tra log trong Experts tab của MT5
2. Verify indicator handles không INVALID
3. Check symbol/timeframe matching
4. Sử dụng Print() để debug
5. Test với Strategy Tester visual mode
6. Tham khảo các strategy có sẵn làm ví dụ

---

**Version**: 1.0  
**Last Updated**: 2025-10-03
