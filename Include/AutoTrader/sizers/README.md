# Sizers - Position Sizing Implementations

Thư mục này chứa các implementation của interface `ISizer` để tính toán khối lượng lot cho giao dịch.

## Cấu trúc

```
/Include/AutoTrader/sizers/
├── Sizer_FixedLot.mqh       # Lot size cố định
├── Sizer_FixedMoney.mqh     # Lot dựa trên số tiền rủi ro cố định
├── Sizer_RiskPercent.mqh    # Lot dựa trên % rủi ro của account
└── Sizer_MultiMode.mqh      # Wrapper hỗ trợ nhiều mode (backward compatibility)
```

## Các loại Sizer

### 1. Sizer_FixedLot
**Mục đích:** Trả về lot size cố định bất kể stop loss hay account balance.

**Sử dụng:**
```cpp
#include <AutoTrader/sizers/Sizer_FixedLot.mqh>

ISizer *sizer = new Sizer_FixedLot(0.10); // Luôn trade 0.10 lot
```

**Ưu điểm:**
- Đơn giản, dễ kiểm soát
- Phù hợp backtest với lot size cố định

**Nhược điểm:**
- Không tự động điều chỉnh theo rủi ro
- Không scale với account size

---

### 2. Sizer_FixedMoney
**Mục đích:** Tính lot dựa trên số tiền rủi ro cố định (ví dụ: $100 mỗi lệnh).

**Công thức:**
```
Lot = Risk Money / (Stop Points × Money Per Point Per Lot)
```

**Sử dụng:**
```cpp
#include <AutoTrader/sizers/Sizer_FixedMoney.mqh>

ISizer *sizer = new Sizer_FixedMoney(100.0); // Rủi ro $100 mỗi lệnh
```

**Ưu điểm:**
- Rủi ro cố định mỗi lệnh (ví dụ: $100)
- Tự động điều chỉnh lot theo khoảng cách SL
- Stop loss xa → lot nhỏ, stop loss gần → lot lớn

**Nhược điểm:**
- Không tự động scale với account growth
- Cần cập nhật thủ công khi account tăng/giảm

---

### 3. Sizer_RiskPercent
**Mục đích:** Tính lot dựa trên % rủi ro của account balance (ví dụ: 2% mỗi lệnh).

**Công thức:**
```
Risk Money = Balance × (Risk % / 100)
Lot = Risk Money / (Stop Points × Money Per Point Per Lot)
```

**Sử dụng:**
```cpp
#include <AutoTrader/sizers/Sizer_RiskPercent.mqh>

ISizer *sizer = new Sizer_RiskPercent(2.0); // Rủi ro 2% balance mỗi lệnh
```

**Ưu điểm:**
- Tự động scale với account size
- Quản lý rủi ro chuyên nghiệp (% risk per trade)
- Phù hợp với chiến lược money management dài hạn

**Nhược điểm:**
- Có thể tạo lot size lớn khi account tăng nhanh
- Cần monitor để tránh over-leverage

---

### 4. Sizer_MultiMode (Wrapper)
**Mục đích:** Wrapper hỗ trợ backward compatibility với `MultiModeSizer` cũ.

**Sử dụng:**
```cpp
#include <AutoTrader/sizers/Sizer_MultiMode.mqh>

// Fixed lot mode
ISizer *sizer1 = new Sizer_MultiMode(0.10, CALC_MODE_FIXED);

// Fixed money mode
ISizer *sizer2 = new Sizer_MultiMode(100.0, CALC_MODE_FIXED_MONEY);

// Risk percent mode
ISizer *sizer3 = new Sizer_MultiMode(2.0, CALC_MODE_RISK_PERCENT);

// Thay đổi mode runtime
sizer1.UpdateMode(1.5, CALC_MODE_RISK_PERCENT);
```

**Ưu điểm:**
- Tương thích ngược với code cũ
- Có thể switch mode runtime
- Input parameter dễ cấu hình trong EA

**Nhược điểm:**
- Overhead nhỏ do wrapper layer
- Nếu không cần switch mode, nên dùng sizer cụ thể

---

## So sánh

| Sizer | Lot Size | Scale với Account | Use Case |
|-------|----------|-------------------|----------|
| **FixedLot** | Cố định | ❌ Không | Backtest, testing |
| **FixedMoney** | Thay đổi theo SL | ❌ Không | Rủi ro cố định ($) |
| **RiskPercent** | Thay đổi theo SL & Balance | ✅ Có | Professional risk management |
| **MultiMode** | Tùy mode | Tùy mode | Backward compatibility |

---

## Ví dụ thực tế

### Scenario: Account $10,000, SL = 100 points, EURUSD

| Sizer | Config | Calculation | Lot Size |
|-------|--------|-------------|----------|
| FixedLot | 0.10 lot | N/A | **0.10** |
| FixedMoney | $100 risk | $100 / (100 points × $1/point) | **1.00** |
| RiskPercent | 2% risk | ($10,000 × 2%) / (100 × $1) | **2.00** |

### Khi account tăng lên $20,000:

| Sizer | Lot Size | Thay đổi |
|-------|----------|----------|
| FixedLot | 0.10 | ✅ Không đổi |
| FixedMoney | 1.00 | ✅ Không đổi |
| RiskPercent | **4.00** | ⚠️ Tăng gấp đôi |

---

## Tích hợp với Orchestrator

```cpp
#include <AutoTrader/sizers/Sizer_RiskPercent.mqh>

ISizer *sizer = new Sizer_RiskPercent(2.0); // 2% risk per trade

Orchestrator *orch = new Orchestrator(
    _Symbol, PERIOD_H1, deviation, magic,
    signal, exit, trailing, risk,
    sizer,  // ← ISizer instance
    targets, exec, md, pos, log, store
);
```

---

## Best Practices

1. **Backtest:** Dùng `Sizer_FixedLot` để kiểm soát lot size
2. **Demo/Live:** Dùng `Sizer_RiskPercent` cho risk management tự động
3. **Conservative:** `Sizer_FixedMoney` khi không muốn scale với account
4. **Flexible:** `Sizer_MultiMode` khi cần input parameter động

---

## Migration từ MultiModeSizer cũ

**Trước đây:**
```cpp
#include <AutoTrader/domain/policies/MultiModeSizer.mqh>
MultiModeSizer *sizer = new MultiModeSizer(2.0, CALC_MODE_RISK_PERCENT);
```

**Bây giờ:**
```cpp
#include <AutoTrader/sizers/Sizer_MultiMode.mqh>
Sizer_MultiMode *sizer = new Sizer_MultiMode(2.0, CALC_MODE_RISK_PERCENT);
```

Hoặc dùng sizer cụ thể:
```cpp
#include <AutoTrader/sizers/Sizer_RiskPercent.mqh>
Sizer_RiskPercent *sizer = new Sizer_RiskPercent(2.0);
```

---

## Notes

- Tất cả sizer tự động normalize lot về broker constraints (min/max/step)
- `stopPoints` parameter là khoảng cách SL tính theo **points** (không phải pips)
- Nếu `stopPoints <= 0`, sizer sẽ trả về 0.0 hoặc fallback value
