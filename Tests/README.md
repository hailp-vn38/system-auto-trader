# AutoTrader Testing Suite

## Quick Start

### Chạy Unit Tests

```bash
# Compile unit test
./check_mql5.sh "Scripts/UnitTests/Test_Orchestrator.mq5"

# Run trong MT5:
# Tools → Options → Scripts → Chọn Test_Orchestrator
# Hoặc kéo vào chart
```

### Chạy Integration Tests

```bash
# Compile
./check_mql5.sh "Experts/IntegrationTests/Test_FullPipelineIntegration.mq5"

# Run trong Strategy Tester:
# View → Strategy Tester
# Chọn EA: Test_FullPipelineIntegration
# Symbol: EURUSD, Period: H1
# Start
```

---

## Test Structure

```
Unit Tests (Fast, Isolated)
└── Mock all dependencies
└── Test domain logic only
└── Run time: < 1 second each

Integration Tests (Confidence)
└── Real MT5 adapters
└── Test full pipeline
└── Run time: 10-30 minutes
```

---

## Available Tests

### Unit Tests (/Scripts/UnitTests/)

| Test File | Target | Status |
|-----------|--------|--------|
| `Test_Orchestrator.mq5` | Orchestrator core logic | ✅ Complete |
| `Test_Strat_MA.mq5` | MA strategy | 🚧 TODO |
| `Test_Exit_MAFlip.mq5` | Exit signal | 🚧 TODO |
| `Test_Risk_AllowOneOpen.mq5` | Risk management | 🚧 TODO |

### Integration Tests (/Experts/IntegrationTests/)

| Test File | Scenario | Status |
|-----------|----------|--------|
| `Test_FullPipelineIntegration.mq5` | Entry → Trailing → Exit | ✅ Complete |
| `Test_MultiEntryScenario.mq5` | Multi-entry support | 🚧 TODO |
| `Test_EventSystemIntegration.mq5` | Event handlers | 🚧 TODO |

---

## Test Results Example

### Unit Test Output

```
=====================================
  ORCHESTRATOR UNIT TESTS
=====================================
[✓] Constructor creates valid object: PASS
[✓] IsReady returns true with required deps: PASS
[✓] OpenTrade called once: PASS
[✓] Correct order type: PASS
[✓] No trade executed: PASS
[✓] Risk check called: PASS
[✓] Trade blocked by risk: PASS
[✓] Multiple entries executed: PASS
=====================================
         TEST REPORT
=====================================
Total Tests:  8
Passed:       8 (100.0%)
Failed:       0 (0.0%)
Duration:     0 seconds
=====================================
```

### Integration Test Output

```
=====================================
  INTEGRATION TEST - FULL PIPELINE
=====================================
[✓] Exit signal enabled
[✓] Trailing stop enabled
[✓] Risk management enabled (max 1 position)
Symbol: EURUSD
Timeframe: PERIOD_H1
Magic: 99999
Orchestrator ready: 1
=====================================

[Trade Events logged via LoggingEventHandler]

=====================================
  INTEGRATION TEST SUMMARY
=====================================
Duration: 1800 seconds (30.0 minutes)
Final open positions: 0
Deinit reason: Program stopped manually
=====================================
```

---

## Writing New Tests

### Unit Test Template

```cpp
#include <AutoTrader/testing/TestFramework.mqh>
#include <AutoTrader/testing/mocks/Mock*.mqh>

void OnStart() {
    TestFramework *test = new TestFramework();
    
    // Test Suite
    TestFeature1();
    TestFeature2();
    TestEdgeCase();
    
    delete test;
}

void TestFeature1() {
    // Arrange
    MockSignal *sig = new MockSignal();
    sig.SetupBuySignal(1.10000, 1.09900, 1.10200);
    
    // Act
    TradeSignal signal;
    bool result = sig.ShouldEnter("EURUSD", PERIOD_H1, signal);
    
    // Assert
    g_test.AssertTrue("Feature works", result, "Should return true");
    
    // Cleanup
    delete sig;
}
```

### Integration Test Template

```cpp
#include <AutoTrader/app/Orchestrator.mqh>
// ... include real adapters

Orchestrator *g_orch = NULL;

int OnInit() {
    // Setup với real adapters
    // ...
    return INIT_SUCCEEDED;
}

void OnTick() {
    if(g_orch != NULL) g_orch.OnTick();
}

void OnTradeTransaction(...) {
    if(g_orch != NULL) g_orch.OnTradeTransaction(trans, request, result);
}

void OnDeinit(const int reason) {
    // Cleanup
}
```

---

## CI/CD Integration (Future)

```yaml
# .github/workflows/test.yml
name: MQL5 Tests

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Wine + MT5
        run: ./scripts/setup_mt5_ci.sh
      - name: Run Unit Tests
        run: ./scripts/run_unit_tests.sh
      
  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Integration Tests
        run: ./scripts/run_integration_tests.sh
```

---

## Documentation

- [Testing Framework Guide](testing_framework.md) - Chi tiết API và patterns
- [Orchestrator Docs](orchestrator_docs.md) - System architecture
- [Core Architecture](core.md) - Clean Architecture overview

---

## Test Files Summary

| File | Type | Test Count | Status |
|------|------|------------|--------|
| `Test_Orchestrator.mq5` | Unit | 8 | ✅ Complete |
| `Test_MockAdapters.mq5` | Unit | 12 | ✅ Complete |
| `Test_SimplePipelineIntegration.mq5` | Integration | End-to-end | ✅ Complete |

**Total:** 20+ unit tests, 1 integration test

---

## Contributing

Khi thêm feature mới:

1. ✅ Viết unit test trước (TDD)
2. ✅ Implement feature
3. ✅ Thêm integration test cho happy path
4. ✅ Update documentation
5. ✅ Verify all tests pass

---

## Verification

**Kiểm tra test compilation:**

```bash
# Unit tests
./check_mql5.sh "Scripts/UnitTests/Test_Orchestrator.mq5"
./check_mql5.sh "Scripts/UnitTests/Test_MockAdapters.mq5"

# Integration test
./check_mql5.sh "Experts/IntegrationTests/Test_SimplePipelineIntegration.mq5"

# Expected: 0 errors, 0 warnings ✅
```

---

## Support

Issues: [GitHub Issues](https://github.com/hailp-vn38/system-auto-trader/issues)  
Docs: `/Docs` folder  
Examples: `/Experts/Examples` folder  
**Complete Report:** `/Tests/COMPLETION_REPORT.md` ✅
