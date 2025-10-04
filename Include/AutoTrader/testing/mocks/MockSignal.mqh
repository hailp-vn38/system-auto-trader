//+------------------------------------------------------------------+
//|                                                  MockSignal.mqh |
//|                                  Copyright 2025, AutoTrader Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AutoTrader Team"
#property version "1.00"
#property strict

#include <AutoTrader/domain/ports/ISignal.mqh>

//+------------------------------------------------------------------+
//| Mock Signal for Unit Testing                                     |
//+------------------------------------------------------------------+
class MockSignal : public ISignal {
  private:
    TradeSignal m_mockSignal;
    TradeSignal m_mockSignals[];
    bool m_shouldReturnSignal;
    bool m_isReady;
    int m_callCount;

  public:
    MockSignal() : m_shouldReturnSignal(false), m_isReady(true), m_callCount(0) {
        InitDefaultSignal();
    }

    //+------------------------------------------------------------------+
    //| ISignal Implementation                                            |
    //+------------------------------------------------------------------+
    bool IsReady() const override { return m_isReady; }

    //+------------------------------------------------------------------+
    //| Setup Methods                                                     |
    //+------------------------------------------------------------------+
    void SetReady(bool ready) { m_isReady = ready; }

    void SetupBuySignal(double entryPrice, double sl, double tp) {
        m_mockSignal.valid          = true;
        m_mockSignal.type           = TRADE_TYPE_BUY;
        m_mockSignal.isSell         = false;
        m_mockSignal.isOrderPending = false;
        m_mockSignal.price          = entryPrice;
        m_mockSignal.sl             = sl;
        m_mockSignal.tp             = tp;
        m_mockSignal.stopPoints     = (int)((entryPrice - sl) / _Point);
        m_mockSignal.comment        = "Mock BUY Signal";
        m_shouldReturnSignal        = true;
    }

    void SetupSellSignal(double entryPrice, double sl, double tp) {
        m_mockSignal.valid          = true;
        m_mockSignal.type           = TRADE_TYPE_SELL;
        m_mockSignal.isSell         = true;
        m_mockSignal.isOrderPending = false;
        m_mockSignal.price          = entryPrice;
        m_mockSignal.sl             = sl;
        m_mockSignal.tp             = tp;
        m_mockSignal.stopPoints     = (int)((sl - entryPrice) / _Point);
        m_mockSignal.comment        = "Mock SELL Signal";
        m_shouldReturnSignal        = true;
    }

    void SetupPendingOrderSignal(ENUM_TRADE_TYPE type, double entryPrice, double sl, double tp) {
        m_mockSignal.valid  = true;
        m_mockSignal.type   = type;
        m_mockSignal.isSell = (type == TRADE_TYPE_SELL_STOP || type == TRADE_TYPE_SELL_LIMIT);
        m_mockSignal.isOrderPending = true;
        m_mockSignal.price          = entryPrice;
        m_mockSignal.sl             = sl;
        m_mockSignal.tp             = tp;
        m_mockSignal.comment        = "Mock Pending Order";
        m_shouldReturnSignal        = true;
    }

    void SetupMultipleSignals(int count) {
        ArrayResize(m_mockSignals, count);
        for(int i = 0; i < count; i++) {
            m_mockSignals[i].valid          = true;
            m_mockSignals[i].type           = TRADE_TYPE_BUY;
            m_mockSignals[i].isSell         = false;
            m_mockSignals[i].isOrderPending = false;
            m_mockSignals[i].price          = 1.1000 + (i * 0.0010);
            m_mockSignals[i].sl             = 1.0950;
            m_mockSignals[i].tp             = 1.1200;
            m_mockSignals[i].stopPoints     = 50;
            m_mockSignals[i].comment        = "Mock Signal #" + IntegerToString(i + 1);
        }
        m_shouldReturnSignal = true;
    }

    void SetNoSignal() {
        m_shouldReturnSignal = false;
        ArrayResize(m_mockSignals, 0);
    }

    void ResetCallCount() { m_callCount = 0; }

    //+------------------------------------------------------------------+
    //| ISignal Implementation - Entry Logic                             |
    //+------------------------------------------------------------------+
    bool ShouldEnter(const string symbol, const ENUM_TIMEFRAMES tf, TradeSignal &out) override {
        m_callCount++;
        if(m_shouldReturnSignal && m_mockSignal.valid) {
            out = m_mockSignal;
            return true;
        }
        return false;
    }

    bool ShouldEnterMulti(const string symbol, const ENUM_TIMEFRAMES tf,
                          TradeSignal &signals[]) override {
        m_callCount++;
        if(m_shouldReturnSignal && ArraySize(m_mockSignals) > 0) {
            ArrayResize(signals, ArraySize(m_mockSignals));
            for(int i = 0; i < ArraySize(m_mockSignals); i++) { signals[i] = m_mockSignals[i]; }
            return true;
        } else if(m_shouldReturnSignal && m_mockSignal.valid) {
            // Fallback to single signal
            ArrayResize(signals, 1);
            signals[0] = m_mockSignal;
            return true;
        }
        return false;
    }

    //+------------------------------------------------------------------+
    //| Verification Methods                                              |
    //+------------------------------------------------------------------+
    int GetCallCount() const { return m_callCount; }

  private:
    void InitDefaultSignal() {
        m_mockSignal.valid          = false;
        m_mockSignal.type           = TRADE_TYPE_INVALID;
        m_mockSignal.isSell         = false;
        m_mockSignal.isOrderPending = false;
        m_mockSignal.price          = 0.0;
        m_mockSignal.sl             = 0.0;
        m_mockSignal.tp             = 0.0;
        m_mockSignal.stopPoints     = 0;
        m_mockSignal.comment        = "";
    }
};
