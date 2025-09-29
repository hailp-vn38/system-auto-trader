# AutoTrader System Core

Dự án EA (Expert Advisor) theo kiến trúc **Clean/Ports & Adapters + FSM** cho MetaTrader 5 (MQL5).  
Mục tiêu: tách biệt domain (logic trading) với adapters (MQL5 API), dễ mở rộng, dễ test và bảo trì.

---

## 📂 Cấu trúc thư mục

```


MQL5/  
├─ Experts/  
│ └─ AutoTrader/  
│ ├─ AutoTraderEA.mq5 # Composition Root, entry EA  
│ ├─ App_Config.mqh # Inputs, config  
│ ├─ App_Composition.mqh # Wiring modules (tùy chọn)  
│ └─ App_Constants.mqh # Magic, deviation, constants  
│  
├─ Include/  
│ └─ AutoTrader/  
│ ├─ app/  
│ │ ├─ Orchestrator.mqh # Orchestrator pipeline  
│ │ └─ Validation.mqh # Guards, checks (spread, freeze…)  
│ │  
│ ├─ domain/  
│ │ ├─ ports/ # Interfaces  
│ │ │ ├─ IMarketData.mqh  
│ │ │ ├─ IExecution.mqh  
│ │ │ ├─ ISignal.mqh  
│ │ │ ├─ IExitSignal.mqh # NEW: ExitSignal (thoát lệnh)  
│ │ │ ├─ ITrailing.mqh # NEW: TrailingStops interface  
│ │ │ ├─ IRisk.mqh  
│ │ │ ├─ ISizer.mqh  
│ │ │ ├─ IStorage.mqh  
│ │ │ └─ ITelemetry.mqh  
│ │ ├─ entities/  
│ │ │ ├─ TradeSignal.mqh  
│ │ │ ├─ ExitSignal.mqh # NEW: dữ liệu tín hiệu thoát  
│ │ │ └─ PositionState.mqh  
│ │ ├─ fsm/  
│ │ │ └─ TradeFSM.mqh  
│ │ └─ policies/  
│ │ ├─ Risk_AllowAll.mqh  
│ │ └─ Sizer_FixedLot.mqh  
│ │  
│ ├─ strategies/  
│ │ └─ Strat_MA.mqh  
│ │  
│ ├─ exits/  
│ │ ├─ Exit_TimeBased.mqh # Ví dụ thoát theo thời gian  
│ │ └─ Exit_MAFlip.mqh # Thoát khi MA cắt ngược  
│ │  
│ ├─ trailing/  
│ │ ├─ Trailing_ATR.mqh # Trailing theo ATR  
│ │ └─ Trailing_Percent.mqh # Trailing theo %  
│ │  
│ ├─ adapters/  
│ │ └─ mt5/  
│ │ ├─ Mt5MarketDataAdapter.mqh  
│ │ ├─ Mt5ExecutionAdapter.mqh  
│ │ └─ Mt5TelemetryAdapter.mqh  
│ │  
│ └─ utils/  
│ ├─ PriceCalc.mqh  
│ └─ MathEx.mqh  
│  
├─ Files/  
│ ├─ configs/AutoTrader.config.json  
│ ├─ logs/  
│ └─ reports/  
│  
└─ Scripts/  
└─ Backtest_Batch.mq5

````

---

## 🔑 Thành phần chính

### 1. **Ports (Interfaces)**
- `ISignal`: Sinh tín hiệu entry.
- `IExitSignal`: (Mới) Sinh tín hiệu exit.
- `ITrailing`: (Mới) Quản lý trailing stop.
- `IRisk`: Kiểm tra điều kiện risk.
- `ISizer`: Tính khối lượng.
- `IMarketData`: Adapter lấy dữ liệu giá.
- `IExecution`: Adapter đặt lệnh.
- `IStorage`, `ITelemetry`: Lưu trạng thái, log/notify.

### 2. **Entities**
- `TradeSignal`: Thông tin vào lệnh (type, sl, tp).
- `ExitSignal`: Thông tin thoát lệnh (ticket, lý do, sl/tp mới).
- `PositionState`: Quản lý trạng thái FSM.

### 3. **Strategies**
- `Strat_MA`: Entry bằng MA cross.
- Có thể thêm: Breakout, RSI, Volume Profile…

### 4. **Exits**
- `Exit_TimeBased`: Thoát sau N bars.
- `Exit_MAFlip`: Thoát khi MA cắt ngược.

### 5. **Trailing**
- `Trailing_ATR`: SL bám theo ATR.
- `Trailing_Percent`: SL bám theo % lợi nhuận.

### 6. **Policies**
- `Risk_AllowAll`: Risk luôn cho phép (stub).
- `Sizer_FixedLot`: Cố định lot.

### 7. **Orchestrator**
Pipeline chính:
1. Signal → Entry?
2. Risk → Cho phép?
3. Sizer → Tính lot.
4. Execution → Place order.
5. FSM → Update position.
6. ExitSignal → Kiểm tra điều kiện thoát.
7. Trailing → Điều chỉnh SL.
8. Telemetry/Storage → Lưu trạng thái, log.

---

## 📊 Flow hoạt động

```mermaid
graph TB
oninit[OnInit]
loadconfig[Load Config]
compose[Compose Modules]

ontick[OnTick]
snapshot[Fetch Market Data]
orch[Orchestrator.OnTick]
signal[EntrySignal]
risk[RiskCheck]
sizer[Sizer]
exec[Execution.PlaceOrder]
fsm[Update FSM]
exitsig[ExitSignal.ShouldExit]
trailing[TrailingStops.Manage]
telemetry[Log/Notify]
storage[Save State]

ontimer[OnTimer]
manage[Manage Positions]

ondeinit[OnDeinit]
flush[Flush Logs]
dispose[Dispose Modules]

oninit --> loadconfig
loadconfig --> compose
compose --> ontick

ontick --> snapshot
snapshot --> orch
orch --> signal
signal --> risk
risk --> sizer
sizer --> exec
exec --> fsm
fsm --> exitsig
fsm --> trailing
fsm --> telemetry
fsm --> storage

exitsig --> exec
trailing --> exec

ontimer --> manage
manage --> trailing

ondeinit --> flush
flush --> dispose
````

---

## 🚀 Kế hoạch mở rộng

- Thêm nhiều `ExitSignal` (RSI đảo chiều, Equity Drawdown).
    
- Thêm nhiều `Trailing` (MA-based trailing, Parabolic SAR).
    
- Tích hợp `Risk_FixedR` (giới hạn % risk/trade).
    
- Adapter `SimExecution` để backtest ngoài MT5.
    
- Telemetry: gửi log sang Telegram/Discord.
    

