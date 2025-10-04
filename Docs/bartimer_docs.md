# BarTimer - New Bar Detection Utility

> **Purpose:** Detect new bar formation to run strategy logic only on bar close, not every tick  
> **Location:** `Include/AutoTrader/utils/BarTimer.mqh`

---

## Table of Contents

1. [Why BarTimer?](#why-bartimer)
2. [Class Overview](#class-overview)
3. [API Reference](#api-reference)
4. [Usage Examples](#usage-examples)
5. [Flow Diagrams](#flow-diagrams)
6. [Performance Tips](#performance-tips)

---

## Why BarTimer?

### The Problem

By default, MT5 EA's `OnTick()` is called on **every price tick** (can be thousands per minute):

```cpp
void OnTick() {
    g_orch.OnTick();  // ❌ Runs too frequently!
}
```

**Issues:**
- ❌ Excessive CPU usage
- ❌ Redundant calculations
- ❌ Multiple signals on same bar
- ❌ Unnecessary API calls

### The Solution

**BarTimer** detects when a new bar opens and only executes strategy logic once per bar:

```cpp
void OnTick() {
    if(g_barTimer.IsNewBar()) {
        g_orch.OnTick();  // ✅ Runs only on new bar!
    }
}
```

**Benefits:**
- ✅ Reduced CPU usage (99%+ reduction for M15+)
- ✅ Consistent signal generation
- ✅ Predictable behavior
- ✅ Better backtesting accuracy

---

## Class Overview

### BarTimer (Single Timeframe)

```cpp
class BarTimer {
    BarTimer(string symbol, ENUM_TIMEFRAMES timeframe);
    
    bool IsNewBar();                      // Main method
    void Reset();                         
    datetime GetCurrentBarTime() const;   
    int GetSecondsToNextBar() const;      
    string GetTimeToNextBarString() const;
};
```

### MultiBarTimer (Multiple Timeframes)

```cpp
class MultiBarTimer {
    MultiBarTimer(string symbol);
    
    void AddTimeframe(ENUM_TIMEFRAMES timeframe);
    bool IsNewBar(ENUM_TIMEFRAMES timeframe);
    void CheckAllTimeframes(bool &results[]);
    void ResetAll();
};
```

---

## API Reference

### BarTimer Methods

#### Constructor

```cpp
BarTimer(string symbol, ENUM_TIMEFRAMES timeframe)
```

**Parameters:**
- `symbol` - Trading symbol (e.g., "EURUSD")
- `timeframe` - Timeframe to monitor (e.g., `PERIOD_H1`)

**Example:**
```cpp
BarTimer *timer = new BarTimer(_Symbol, PERIOD_H1);
```

---

#### IsNewBar()

```cpp
bool IsNewBar()
```

**Returns:** `true` if a new bar has formed since last check

**Behavior:**
- First call after creation: returns `false` (initialization)
- Subsequent calls: returns `true` only when bar time changes

**Example:**
```cpp
void OnTick() {
    if(g_barTimer.IsNewBar()) {
        Print("New bar detected!");
        // Execute strategy logic
    }
}
```

---

#### Reset()

```cpp
void Reset()
```

**Purpose:** Reset the timer state (useful when changing symbols/timeframes)

**Example:**
```cpp
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    if(id == CHARTEVENT_CHART_CHANGE) {
        g_barTimer.Reset();
    }
}
```

---

#### GetCurrentBarTime()

```cpp
datetime GetCurrentBarTime() const
```

**Returns:** Opening time of current bar

**Example:**
```cpp
datetime barTime = g_barTimer.GetCurrentBarTime();
Print("Current bar opened at: ", TimeToString(barTime));
```

---

#### GetSecondsToNextBar()

```cpp
int GetSecondsToNextBar() const
```

**Returns:** Seconds remaining until next bar opens

**Example:**
```cpp
int seconds = g_barTimer.GetSecondsToNextBar();
if(seconds < 60) {
    Print("New bar in less than 1 minute!");
}
```

---

#### GetTimeToNextBarString()

```cpp
string GetTimeToNextBarString() const
```

**Returns:** Formatted string "MM:SS" for countdown display

**Example:**
```cpp
void OnTick() {
    Comment("Next bar in: ", g_barTimer.GetTimeToNextBarString());
}
```

---

### MultiBarTimer Methods

#### AddTimeframe()

```cpp
void AddTimeframe(ENUM_TIMEFRAMES timeframe)
```

**Purpose:** Register a timeframe for monitoring

**Example:**
```cpp
MultiBarTimer *multi = new MultiBarTimer(_Symbol);
multi.AddTimeframe(PERIOD_M15);
multi.AddTimeframe(PERIOD_H1);
multi.AddTimeframe(PERIOD_H4);
```

---

#### IsNewBar(timeframe)

```cpp
bool IsNewBar(ENUM_TIMEFRAMES timeframe)
```

**Returns:** `true` if specified timeframe has new bar

**Example:**
```cpp
void OnTick() {
    if(g_multiTimer.IsNewBar(PERIOD_H1)) {
        Print("H1 new bar");
    }
    
    if(g_multiTimer.IsNewBar(PERIOD_H4)) {
        Print("H4 new bar");
    }
}
```

---

## Usage Examples

### Example 1: Basic Usage

```cpp
#include <AutoTrader/utils/BarTimer.mqh>

BarTimer *g_barTimer = NULL;

int OnInit() {
    g_barTimer = new BarTimer(_Symbol, PERIOD_H1);
    return INIT_SUCCEEDED;
}

void OnTick() {
    if(g_barTimer.IsNewBar()) {
        Print("New H1 bar - Execute strategy");
        // Your strategy logic here
    }
}

void OnDeinit(const int reason) {
    delete g_barTimer;
}
```

---

### Example 2: With Orchestrator

```cpp
#include <AutoTrader/app/Orchestrator.mqh>
#include <AutoTrader/utils/BarTimer.mqh>

BarTimer *g_barTimer = NULL;
Orchestrator *g_orch = NULL;

int OnInit() {
    // Setup BarTimer
    g_barTimer = new BarTimer(_Symbol, PERIOD_H1);
    
    // Setup Orchestrator
    ISignal *sig = new EmaCross21x50(_Symbol, PERIOD_H1);
    IExecution *exec = new Mt5ExecutionAdapter();
    IMarketData *md = new Mt5MarketDataAdapter();
    
    g_orch = new Orchestrator(_Symbol, PERIOD_H1, 5, 12345, sig, exec, md);
    
    return INIT_SUCCEEDED;
}

void OnT