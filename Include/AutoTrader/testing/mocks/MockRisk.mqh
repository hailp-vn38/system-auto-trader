//+------------------------------------------------------------------+
//|                                                     MockRisk.mqh |
//|                                  Copyright 2025, AutoTrader Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AutoTrader Team"
#property version "1.00"
#property strict

#include <AutoTrader/domain/ports/IRisk.mqh>

//+------------------------------------------------------------------+
//| Mock Risk Management for Unit Testing                            |
//+------------------------------------------------------------------+
class MockRisk : public IRisk {
  private:
    bool m_allowTrade;
    int m_callCount;
    string m_lastSymbol;
    long m_lastMagic;

  public:
    MockRisk() : m_allowTrade(true), m_callCount(0), m_lastMagic(0) {}

    //+------------------------------------------------------------------+
    //| Setup Methods                                                     |
    //+------------------------------------------------------------------+
    void SetAllowTrade(bool allow) { m_allowTrade = allow; }
    void ResetCallCount() { m_callCount = 0; }

    //+------------------------------------------------------------------+
    //| IRisk Implementation                                              |
    //+------------------------------------------------------------------+
    bool AllowTrade(const string sym, const long magic) override {
        m_callCount++;
        m_lastSymbol = sym;
        m_lastMagic  = magic;
        return m_allowTrade;
    }

    //+------------------------------------------------------------------+
    //| Verification Methods                                              |
    //+------------------------------------------------------------------+
    int GetCallCount() const { return m_callCount; }
    string GetLastSymbol() const { return m_lastSymbol; }
    long GetLastMagic() const { return m_lastMagic; }
};
