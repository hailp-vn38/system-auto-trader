//+------------------------------------------------------------------+
//|                                               MockMarketData.mqh |
//|                                  Copyright 2025, AutoTrader Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AutoTrader Team"
#property version "1.00"
#property strict

#include <AutoTrader/domain/ports/IMarketData.mqh>

//+------------------------------------------------------------------+
//| Mock Market Data Adapter for Unit Testing                        |
//+------------------------------------------------------------------+
class MockMarketData : public IMarketData {
  private:
    double m_mockBid;
    double m_mockAsk;
    double m_mockPoint;
    int m_mockDigits;
    bool m_shouldFail;

  public:
    MockMarketData()
        : m_mockBid(1.10000), m_mockAsk(1.10010), m_mockPoint(0.00001), m_mockDigits(5),
          m_shouldFail(false) {}

    //+------------------------------------------------------------------+
    //| Setup Methods for Test Configuration                             |
    //+------------------------------------------------------------------+
    void SetBid(double bid) { m_mockBid = bid; }
    void SetAsk(double ask) { m_mockAsk = ask; }
    void SetSpread(double spread) { m_mockAsk = m_mockBid + spread; }
    void SetPoint(double point) { m_mockPoint = point; }
    void SetDigits(int digits) { m_mockDigits = digits; }
    void SetShouldFail(bool fail) { m_shouldFail = fail; }

    void SetPrice(double price) {
        m_mockBid = price;
        m_mockAsk = price + (10 * m_mockPoint); // 10 points spread
    }

    //+------------------------------------------------------------------+
    //| IMarketData Implementation                                        |
    //+------------------------------------------------------------------+
    bool LastBidAsk(const string sym, double &bid, double &ask) override {
        if(m_shouldFail) return false;
        bid = m_mockBid;
        ask = m_mockAsk;
        return true;
    }

    double Point(const string sym) override { return m_mockPoint; }

    double TickSize(const string sym) override {
        return m_mockPoint; // Same as point for simplicity
    }

    bool OHLC(const string sym, ENUM_TIMEFRAMES tf, int shift, double &o, double &h, double &l,
              double &c) override {
        if(m_shouldFail) return false;
        // Mock OHLC data around current price
        c = m_mockBid;
        o = c - (10 * m_mockPoint);
        h = c + (5 * m_mockPoint);
        l = c - (15 * m_mockPoint);
        return true;
    }

    //+------------------------------------------------------------------+
    //| Verification Methods                                              |
    //+------------------------------------------------------------------+
    double GetLastBid() const { return m_mockBid; }
    double GetLastAsk() const { return m_mockAsk; }
};
