# Swing Structure Strategy

## Tổng quan

Chiến lược **Swing Structure** phân tích cấu trúc thị trường qua nhiều levels (cấp độ) bằng cách xác định các swing points (điểm đảo chiều) sử dụng ATR (Average True Range).

## Kiến trúc

### Core Components

```
Include/AutoTrader/strategies/swing/
├── SwingTypes.mqh              # Structures: LocalExtreme, LevelExtremes
└── Strat_SwingStructure.mqh    # Core strategy logic (implements ISignal)

Include/AutoTrader/adapters/visualization/
└── SwingChartVisualizer.mqh    # Chart visualization (optional)

Experts/Examples/
└── SwingStructureExample.mq5   # Example EA
```

### Dependencies

- `IMarketData` - Lấy dữ liệu OHLC
- `ISignal` - Interface cho chiến lược
- `ITelemetry` - Logging (optional)
- ATR Indicator - Xác định ngưỡng swing

## Cách hoạt động

### 1. Phát hiện Swing Points (Level 0)

```
- Theo dõi high/low max/min hiện tại
- Khi giá phá ngưỡng ATR:
  * High đảo chiều → Swing High được xác nhận
  * Low đảo chiều → Swing Low được xác nhận
```

### 2. Multi-Level Structure Analysis

```
Level 0 (Base):     ↗↘↗↘↗↘↗↘    (tất cả swing points)
Level 1 (Higher):     ↗  ↘  ↗      (swing points quan trọng hơn)
Level 2 (Major):        ↗    ↘        (major structure)
```

**Logic nâng cấp:**
- Extreme point được "nâng cấp" lên level cao hơn khi:
  1. Là điểm extreme hơn so với extreme trước đó cùng loại
  2. Không bị phá vỡ bởi extreme gần đây hơn
  3. Thỏa mãn điều kiện so sánh với level cao hơn hiện tại

### 3. Signal Generation

Signal được sinh khi có **extreme mới tại signal level** (level cấu hình):

```
Swing High tại Signal Level → Signal BUY (break of structure)
Swing Low tại Signal Level  → Signal SELL (break of structure)
```

**Lý do:** Khi cấu trúc bị phá vỡ, thị trường có xu hướng tiếp tục theo hướng phá vỡ.

## Cấu hình Parameters

### Swing Structure Settings

| Parameter | Mô tả | Khuyến nghị |
|-----------|-------|-------------|
| `InpATRPeriod` | Số nến tính ATR | 14 |
| `InpATRMultiplier` | Hệ số nhân ATR để tính ngưỡng | 1.0-2.0 |
| `InpLevels` | Số levels cấu trúc | 3-5 |
| `InpSignalLevel` | Level sinh signal (0=base, 1+=higher) | 1-2 |

### Cách chọn Signal Level

- **Level 0**: Signal nhiều, noise cao → Scalping
- **Level 1**: Cân bằng signal và chất lượng → Intraday
- **Level 2+**: Signal ít, chất lượng cao → Swing trading

## Sử dụng trong code

### Basic Usage

```cpp
// Khởi tạo strategy
Strat_SwingStructure *strategy = new Strat_SwingStructure(
  marketData,          // IMarketData
  _Symbol,            // Symbol
  PERIOD_H1,          // Timeframe
  14,                 // ATR period
  3,                  // Number of levels
  1,                  // Signal level
  1.0,                // ATR multiplier
  telemetry           // ITelemetry (optional)
);

// Kiểm tra signal
TradeSignal signal;
if(strategy.ShouldEnter(_Symbol, PERIOD_H1, magic, signal)) {
  // Process signal...
}
```

### Với Visualization

```cpp
// Tạo visualizer
SwingChartVisualizer *viz = new SwingChartVisualizer(strategy, true);

// Customize colors
viz.SetLevelColor(0, clrRed);
viz.SetLevelColor(1, clrBlue);

// Update trong OnTick()
viz.Update();
```

### Truy xuất Structure Data

```cpp
// Lấy số lượng extremes tại level
int count = strategy.GetLevelSize(level);

// Lấy extreme cuối cùng
LocalExtreme last = strategy.GetLastExtreme(level);
if(last.IsValid()) {
  Print("Last extreme: ", last.IsHigh() ? "High" : "Low", 
        " @ ", last.price);
}

// Lấy extreme tại index
LocalExtreme ext = strategy.GetExtreme(level, index);
```

## Ví dụ thực tế

### Example EA

Xem: `Experts/Examples/SwingStructureExample.mq5`

**Chạy backtest:**
```bash
# Compile
./compile_mql5.sh "Experts/Examples/SwingStructureExample.mq5"

# Chạy trong MT5 Strategy Tester
# Symbol: EURUSD, XAUUSD, BTCUSD
# Timeframe: H1, H4
# Period: 1 năm
```

### Kết hợp với Orchestrator

```cpp
// Trong OnInit()
g_app = new Orchestrator(_Symbol, timeframe, 5, magic, 
                         strategy, exec, marketData);
g_app.SetSizer(sizer);
g_app.SetRisk(risk);
g_app.SetTargets(targets);

// Trong OnTick()
if(barTimer.IsNewBar()) {
  g_app.OnTick();
  if(visualizer) visualizer.Update();
}
```

## Testing & Validation

### Unit Testing

```cpp
// Test swing detection
LocalExtreme ext = strategy.FindBaseExtreme(high, low, close, time, atr);
assert(ext.IsValid());

// Test level upgrade
int sizeBefore = strategy.GetLevelSize(1);
strategy.UpgradeExtremes(0, time, close, extType);
int sizeAfter = strategy.GetLevelSize(1);
assert(sizeAfter > sizeBefore);
```

### Visual Validation

1. Bật `InpShowSwingLines = true`
2. Kiểm tra swing lines vẽ đúng
3. Xác nhận signal level (đường dày hơn)
4. So sánh với manual analysis

## Performance Tips

### Optimization

- **ATR Period**: Test 10-20 để tìm sweet spot
- **ATR Multiplier**: 
  - < 1.0: Nhiều swing, nhiều noise
  - 1.0-1.5: Cân bằng
  - > 2.0: Ít swing, bỏ lỡ moves
- **Signal Level**:
  - Level cao hơn → ít signal hơn, chất lượng tốt hơn
  - Test trên historical data

### Risk Management

```cpp
// Sử dụng swing structure làm stop loss
LocalExtreme lastSwing = strategy.GetLastExtreme(signalLevel);
double stopLoss = (isBuy) ? lastSwing.price : lastSwing.price;

// RR dựa trên structure
double nextTarget = strategy.GetExtreme(signalLevel, index - 2).price;
double takeProfit = nextTarget;
```

## Troubleshooting

### Không có signal

- Kiểm tra `IsReady()` return true
- Verify ATR indicator handle valid
- Đảm bảo có đủ bars history
- Kiểm tra signal level < total levels

### Swing lines không hiển thị

- Bật `InpShowSwingLines = true`
- Gọi `visualizer.Update()` trong OnTick()
- Check chart object permissions

### Signal quá nhiều/ít

- Điều chỉnh `InpATRMultiplier`
- Thay đổi `InpSignalLevel`
- Test timeframe khác

## Roadmap

- [ ] Thêm filters (volume, trend confirmation)
- [ ] Support cho pending orders tại swing levels
- [ ] Auto-calculate optimal ATR multiplier
- [ ] Real-time structure alerts
- [ ] Export structure data ra file

## License

MIT License - AutoTrader Framework
