# Targets - Stop Loss & Take Profit Implementations

Thư mục này chứa các implementation của interface `ITargets` để tính toán Stop Loss (SL) và Take Profit (TP).

## Cấu trúc

```
/Include/AutoTrader/targets/
├── Target_Fixed.mqh         # SL/TP cố định theo points
├── Target_Factor.mqh        # SL/TP theo Risk:Reward ratio
├── Target_Percent.mqh       # SL/TP theo % của entry price
├── Target_MultiMode.mqh     # Wrapper hỗ trợ nhiều mode
```

## Các loại Target

### 1. Target_Fixed
**Mục đích:** SL/TP cố định theo số points.

**Sử dụng:**
```cpp
#include <AutoTrader/targets/Target_Fixed.mqh>

ITargets *target = new Target_Fixed(md, 100, 200); // SL=100pts, TP=200pts
```

**Ưu điểm:**
- Đơn giản, dễ kiểm soát
- Phù hợp với chiến lược có SL/TP cố định

**Nhược điểm:**
- Không linh hoạt với volatility thay đổi
- Không tự động điều chỉnh theo market conditions

---

### 2. Target_Factor
**Mục đích:** TP dựa trên Risk:Reward ratio (ví dụ: 2R = TP gấp đôi SL).

**Công thức:**
```
Risk Distance = |Entry - SL|
TP Distance = Risk Distance × Factor
```

**Sử dụng:**
```cpp
#include <AutoTrader/targets/Target_Factor.mqh>

ITargets *target = new Target_Factor(md, 2.0); // TP = 2R (2× risk)
ITargets *target2 = new Target_Factor(md, 3.0, 1.0); // TP = 3R, SL unchanged
```

**Ưu điểm:**
- Professional money management (R:R ratio)
- TP tự động scale với SL distance
- Phù hợp với các chiến lược có SL động

**Nhược điểm:**
- Cần SL hợp lý để tính TP chính xác
- Không phù hợp nếu không có SL rõ ràng

---

### 3. Target_Percent
**Mục đích:** SL/TP là % của entry price (phù hợp với crypto/stocks).

**Công thức:**
```
SL = Entry ± (Entry × SL% / 100)
TP = Entry ± (Entry × TP% / 100)
```

**Sử dụng:**
```cpp
#include <AutoTrader/targets/Target_Percent.mqh>

ITargets *target = new Target_Percent(md, 2.0, 4.0); // SL=2%, TP=4%
```

**Ưu điểm:**
- Tự động scale với giá entry
- Phù hợp với assets có giá cao (Bitcoin, stocks)
- Easy to understand (% gain/loss)

**Nhược điểm:**
- Không phù hợp với Forex (pip-based thay vì %)
- Có thể tạo SL/TP không hợp lý với volatility thấp

---

### 4. Target_MultiMode (Khuyến nghị)
**Mục đích:** Wrapper linh hoạt, hỗ trợ tất cả các mode tính toán.

**Modes:**
- `CALC_MODE_DEFAULT`: Giữ nguyên giá trị đầu vào
- `CALC_MODE_OFF`: Không đặt SL/TP
- `CALC_MODE_POINTS`: Tính theo points
- `CALC_MODE_PERCENT`: Tính theo % entry
- `CALC_MODE_FACTOR`: Tính theo R:R ratio

**Sử dụng:**
```cpp
#include <AutoTrader/targets/Target_MultiMode.mqh>

// TP = 2R, SL = 1R (giữ nguyên)
ITargets *target1 = new Target_MultiMode(md, 2.0, CALC_MODE_FACTOR, 1.0, CALC_MODE_DEFAULT);

// TP = 200 points, SL = 100 points
ITargets *target2 = new Target_MultiMode(md, 200, CALC_MODE_POINTS, 100, CALC_MODE_POINTS);

// TP = 4%, SL = 2%
ITargets *target3 = new Target_MultiMode(md, 4.0, CALC_MODE_PERCENT, 2.0, CALC_MODE_PERCENT);

// Thay đổi mode runtime
target1.SetTargetMode(CALC_MODE_POINTS, 300);
target1.SetStopMode(CALC_MODE_PERCENT, 1.5);
```

**Ưu điểm:**
- Hỗ trợ tất cả modes trong một class
- Có thể thay đổi mode runtime
- Input parameter dễ cấu hình trong EA

**Nhược điểm:**
- Overhead nhỏ do wrapper logic
- Nếu chỉ dùng 1 mode, nên dùng target cụ thể

---

## So sánh

| Target | SL/TP Calculation | Auto Scale | Use Case |
|--------|-------------------|------------|----------|
| **Fixed** | Fixed points | ❌ Không | Fixed strategy |
| **Factor** | R:R ratio | ✅ Có (theo SL) | Professional RR management |
| **Percent** | % of entry | ✅ Có (theo entry) | Crypto/Stocks |
| **MultiMode** | Tùy mode | Tùy mode | Flexible configuration |

---

## Ví dụ thực tế

### Scenario: EURUSD, Entry = 1.1000, SL input = 1.0980 (20 pips)

| Target | Config | SL Result | TP Result |
|--------|--------|-----------|-----------|
| Fixed | SL=100pts, TP=200pts | 1.0900 | 1.1200 |
| Factor | TP=2R, SL=1R | 1.0980 | 1.1040 (2×20=40 pips) |
| Percent | SL=2%, TP=4% | 1.0780 | 1.1440 |
| MultiMode | 2R, FACTOR | 1.0980 | 1.1040 |

---

## Tích hợp với Orchestrator

```cpp
#include <AutoTrader/targets/Target_Factor.mqh>

ITargets *target = new Target_Factor(md, 2.0); // 2R

Orchestrator *orch = new Orchestrator(
    _Symbol, PERIOD_H1, deviation, magic,
    signal, exit, trailing, risk, sizer,
    target,  // ← ITargets instance
    exec, md, pos, log, store
);
```

---

## Best Practices

1. **Forex:** Dùng `Target_Fixed` hoặc `Target_Factor` (pip-based)
2. **Crypto/Stocks:** Dùng `Target_Percent` (%-based)
3. **Risk Management:** Dùng `Target_Factor` cho consistent R:R
4. **Flexible EA:** Dùng `Target_MultiMode` với input parameters

---

## Tick Size Normalization

Tất cả target implementations tự động normalize SL/TP về broker's tick size để tránh lỗi "Invalid stops".

```cpp
// Internal SnapToTick function
double SnapToTick(const string sym, const double price) const {
    const double tick = m_md.TickSize(sym);
    if(tick <= 0) return price;
    return MathRound(price / tick) * tick;
}
```
