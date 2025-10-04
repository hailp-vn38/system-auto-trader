# Testing Framework Documentation

## Tổng quan

Hệ thống test theo **Phương án 3 - Hybrid Testing**, kết hợp:

1. **Unit Tests** - Test domain logic với mock dependencies (nhanh, isolate)
2. **Integration Tests** - Test end-to-end với real MT5 adapters (confidence)

---

## Cấu trúc thư mục

```
MQL5/
├── Include/AutoTrader/testing/
│   ├── TestFramework.mqh           # Core test framework
│   └── mocks/
│       ├── MockSignal.mqh          # Mock ISignal
│       ├── MockExecution.mqh       # Mock IExecution
│       ├── MockMarketData.mqh      # Mock IMarketData
│       └── MockRisk.mqh            # Mock IRisk
│
├── Scripts/UnitTests/
│   ├── Test_Orchestrator.mq5       # Unit test Orchestrator
│   ├── Test_Strat_MA.mq5           # Unit test MA strategy
│   ├── Test_Exit_MAFlip.mq5        # Unit test exit signal
│   └── Test_Risk_AllowOneOpen.mq5  # Unit test risk management
│
└── Experts/IntegrationTests/
    ├── Test_FullPipelineIntegration.mq5  # Full pipeline test
    └── Test_MultiEntryScenario.mq5       # Multi-entry test
```

---

## TestFramework API

### Assert Methods

```cpp
TestFramework *test = new TestFramework();

// Boolean assertions
test.AssertTrue("Test name", condition, "Error message");
test.AssertFalse("Test name", condition, "Error message");

// Equality assertions
test.AssertEquals("Test name", expected, actual, tolerance, "message");
test.AssertEquals("Test name", expectedInt, actualInt, "message");
test.AssertEquals("Test name", "expectedStr", "actualStr", "message");

// Null checks
test.AssertNotNull("Test name", pointer, "message");
test.AssertNull("Test name", pointer, "message");

// Get statistics
int total = test.GetTotalTests();
int passed = test.GetPassedTests();
int failed = test.GetFailedTests();
bool allPassed = test.AllTestsPassed();
```

### Output Example

```
[✓] Constructor creates valid object: PASS
[✓] IsReady returns true with required deps: PASS
[✗] Trade blocked by risk: FAIL: Expected 0, got 1
=====================================
         TEST REPORT
=====================================
Total Tests:  10
Passed:       9 (90.0%)
Failed:       1 (10.0%)
Duration:     2 seconds
=====================================
Failed Tests:
  - Trade blocked by risk: FAIL: Expected 0, got 1
=====================================
```

---

## Mock Adapters Usage

### MockSignal

```cpp
#include <AutoTrader/testing/mocks/MockSignal.mqh>

MockSignal *sig = new MockSignal();

// Setup BUY signal
sig.SetupBuySignal(1.10000, 1.09900, 1.10200);

// Setup SELL signal
sig.SetupSellSignal(1.10000, 1.10100, 1.09800);

// Setup pending order
sig.SetupPendingOrderSignal(ORDER_TYPE_BUY_STOP, 1.10500, 
                            1.10500, 1.10000, 1.11000);

// Setup multiple signals (for multi-entry)
sig.SetupMultipleSignals(3);

// No signal
sig.SetNoSignal();

// Verify calls
int callCount = sig.GetCallCount();
```

### MockExecution

```cpp
#include <AutoTrader/testing/mocks/MockExecution.mqh>

MockExecution *exec = new MockExecution();

// Configure behavior
exec.SetShouldSucceed(true);  // or false to simulate failures
exec.SetMockTicket(123456);

// Execute test
// ... orchestrator.OnTick() ...

// Verify calls
int openCalls = exec.GetOpenTradeCallCount();
int closeCalls = exec.GetClosePositionCallCount();
int modifyCalls = exec.GetModifyPositionCallCount();

// Verify parameters
string symbol = exec.GetLastSymbol();
ENUM_ORDER_TYPE type = exec.GetLastOrderType();
double lots = exec.GetLastLots();
double price = exec.GetLastPrice();
double sl = exec.GetLastSL();
double tp = exec.GetLastTP();

// Reset for next test
exec.ResetCallCounts();
```

### MockMarketData

```cpp
#include <AutoTrader/testing/mocks/MockMarketData.mqh>

MockMarketData *md = new MockMarketData();

// Setup prices
md.SetBid(1.10000);
md.SetAsk(1.10010);
md.SetSpread(0.00010);

// Shortcut
md.SetPrice(1.10000);  // Sets bid, ask = bid + 10 points

// Configure behavior
md.SetPoint(0.00001);
md.SetDigits(5);
md.SetShouldFail(false);  // or true to simulate errors

// Use in tests
double bid = md.GetBid("EURUSD");
double ask = md.GetAsk("EURUSD");
```

### MockRisk

```cpp
#include <AutoTrader/testing/mocks/MockRisk.mqh>

MockRisk *risk = new MockRisk();

// Configure
risk.SetAllowTrade(true);  // or false to block

// Execute test
// ... orchestrator.OnTick() ...

// Verify
int callCount = risk.GetCallCount();
string symbol = risk.GetLastSymbol();
long magic = risk.GetLastMagic();
```

---

## Unit Test Example

### Test Strategy (Strat_MA)

```cpp
// Scripts/UnitTests/Test_Strat_MA.mq5
#include <AutoTrader/testing/TestFramework.mqh>
#include <AutoTrader/testing/mocks/MockMarketData.mqh>
#include <AutoTrader/strategies/Strat_MA.mqh>

void OnStart() {
    TestFramework *test = new TestFramework();
    
    // Setup
    MockMarketData *md = new MockMarketData();
    md.SetPrice(1.10000);
    
    Strat_MA *strategy = new Strat_MA("EURUSD", PERIOD_H1);
    
    // Test
    TradeSignal signal;
    bool result = strategy.ShouldEnter("EURUSD", PERIOD_H1, signal);
    
    // Assert
    test.AssertTrue("Generates signal", result, 
                   "Should return true when MAs cross");
    test.AssertEquals("Signal type", (int)ORDER_TYPE_BUY, 
                     (int)signal.type, "Should be BUY signal");
    test.AssertTrue("Signal valid", signal.valid, 
                   "Signal should be valid");
    
    // Cleanup
    delete strategy;
    delete md;
    delete test;
}
```

---

## Integration Test Guide

### Chạy trong Strategy Tester

1. **Compile EA test:**
   ```bash
   ./check_mql5.sh "Experts/IntegrationTests/Test_FullPipelineIntegration.mq5"
   ```

2. **Mở MT5 Strategy Tester:**
   - Expert: `Test_FullPipelineIntegration`
   - Symbol: EURUSD (hoặc symbol bạn muốn test)
   - Period: H1
   - Date range: Chọn historical data có đủ tín hiệu

3. **Cấu hình:**
   - **Visual Mode**: Bật để debug từng bước
   - **Every Tick**: Test chính xác nhất
   - **Optimization**: Tắt (chỉ single run)

4. **Parameters:**
   - `InpMagic`: 99999 (unique magic)
   - `InpEnableTrailing`: true/false
   - `InpEnableExit`: true/false
   - `InpEnableRisk`: true/false

5. **Run & Analyze:**
   - Check Journal tab cho logs
   - Verify trades trong Results
   - Check metrics: Win rate, P/L, Drawdown

### Safety Checks

Integration tests có built-in safety:

```cpp
// Chỉ chạy trên Tester hoặc Demo
if(!MQLInfoInteger(MQL_TESTER) && 
   AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
    Alert("Integration tests chỉ chạy trên TESTER hoặc DEMO account!");
    return INIT_FAILED;
}
```

---

## Test Workflow

### Development Cycle

```
1. Write unit test → Red (fail)
   ├─ Mock dependencies
   └─ Define expected behavior

2. Implement feature → Green (pass)
   ├─ Minimal code to pass
   └─ Run unit test

3. Refactor → Still Green
   ├─ Clean up code
   └─ Re-run unit test

4. Integration test → Confidence
   ├─ Run in Strategy Tester
   └─ Verify end-to-end flow
```

### Test Execution Order

**Fast Feedback (daily):**
1. Unit tests trong Scripts/UnitTests/ (< 1 second each)
2. Quick integration smoke test (1-2 minutes)

**Full Validation (before deploy):**
1. All unit tests
2. Full integration tests (10-30 minutes)
3. Forward test trên DEMO (1-2 weeks)

---

## Best Practices

### Unit Tests

✅ **DO:**
- Mock tất cả external dependencies
- Test 1 concept per test case
- Use descriptive test names
- Verify both success và failure paths
- Test edge cases (NULL, 0, negative values)

❌ **DON'T:**
- Don't use real MT5 API trong unit tests
- Don't test multiple features in 1 test
- Don't skip error cases
- Don't use hard-coded magic numbers

### Integration Tests

✅ **DO:**
- Use unique magic numbers
- Test trên DEMO first
- Enable logging để debug
- Test với realistic data
- Document test scenarios

❌ **DON'T:**
- Don't test trên LIVE account
- Don't use production magic numbers
- Don't skip safety checks
- Don't ignore failed tests

---

## Troubleshooting

### Unit Test Issues

**Problem:** Mock không hoạt động đúng

**Solution:**
```cpp
// Verify mock setup
MockSignal *sig = new MockSignal();
sig.SetupBuySignal(1.10000, 1.09900, 1.10200);

TradeSignal test;
bool result = sig.ShouldEnter("EURUSD", PERIOD_H1, test);
PrintFormat("Mock returns: %d, Valid: %d", result, test.valid);
```

**Problem:** Test pass nhưng logic sai

**Solution:** 
- Thêm nhiều assert statements
- Test edge cases
- Verify mock call counts

### Integration Test Issues

**Problem:** No trades in Strategy Tester

**Solution:**
- Check Journal logs cho errors
- Verify strategy generates signals
- Check risk management không block
- Enable Visual Mode để debug

**Problem:** Unexpected trades

**Solution:**
- Verify magic number unique
- Check symbol filter
- Review event logs
- Validate signal logic

---

## Extending Tests

### Add New Mock

```cpp
// Include/AutoTrader/testing/mocks/MockSizer.mqh
#include <AutoTrader/domain/ports/ISizer.mqh>

class MockSizer : public ISizer {
private:
    double m_mockLots;
public:
    MockSizer() : m_mockLots(0.10) {}
    
    void SetLots(double lots) { m_mockLots = lots; }
    
    double CalculateLots(string symbol, long magic, 
                        double stopPoints) override {
        return m_mockLots;
    }
};
```

### Add New Unit Test

```cpp
// Scripts/UnitTests/Test_NewFeature.mq5
#include <AutoTrader/testing/TestFramework.mqh>
#include <AutoTrader/testing/mocks/Mock*.mqh>

void OnStart() {
    TestFramework *test = new TestFramework();
    
    // Setup
    // ...
    
    // Test cases
    TestCase1();
    TestCase2();
    TestCase3();
    
    // Cleanup
    delete test;
}

void TestCase1() {
    // Arrange
    // Act
    // Assert
}
```

### Add New Integration Test

```cpp
// Experts/IntegrationTests/Test_NewScenario.mq5
// Follow structure of Test_FullPipelineIntegration.mq5
// Add specific scenario logic
```

---

## Metrics & Coverage

### Target Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Unit Test Coverage | > 80% | - |
| Integration Scenarios | > 5 | 2 |
| Test Execution Time | < 10s (unit) | - |
| Test Success Rate | 100% | - |

### Coverage Checklist

Core Components:
- [x] Orchestrator
- [ ] Strategies (ISignal)
- [ ] Exit Signals
- [ ] Trailing Stops
- [ ] Risk Management
- [ ] Position Sizing
- [ ] Event Handlers

Scenarios:
- [x] Full pipeline (entry → exit)
- [ ] Multi-entry
- [ ] Trailing stop activation
- [ ] Risk blocking
- [ ] Order cancellation

---

## References

- [Testing Best Practices](https://martinfowler.com/articles/practical-test-pyramid.html)
- [Unit Testing Patterns](https://github.com/testdouble/contributing-tests/wiki/Test-Driven-Development)
- [MQL5 Testing](https://www.mql5.com/en/articles/1620)

---

**Maintained by:** AutoTrader Development Team  
**Last Updated:** October 2025  
**Version:** 1.0
