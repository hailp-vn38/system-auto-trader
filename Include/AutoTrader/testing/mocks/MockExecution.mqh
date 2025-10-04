//+------------------------------------------------------------------+
//|                                                MockExecution.mqh |
//|                                  Copyright 2025, AutoTrader Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AutoTrader Team"
#property version "1.00"
#property strict

#include <AutoTrader/domain/ports/IExecution.mqh>

//+------------------------------------------------------------------+
//| Mock Execution Adapter for Unit Testing                          |
//+------------------------------------------------------------------+
class MockExecution : public IExecution {
  private:
    bool m_shouldSucceed;
    ulong m_mockTicket;
    int m_openTradeCallCount;
    int m_closePositionCallCount;
    int m_modifyPositionCallCount;
    int m_cancelOrderCallCount;

    // Last call parameters (for verification)
    string m_lastSymbol;
    ENUM_ORDER_TYPE m_lastOrderType;
    double m_lastLots;
    double m_lastPrice;
    double m_lastSL;
    double m_lastTP;
    string m_lastComment;

  public:
    MockExecution()
        : m_shouldSucceed(true), m_mockTicket(123456), m_openTradeCallCount(0),
          m_closePositionCallCount(0), m_modifyPositionCallCount(0), m_cancelOrderCallCount(0),
          m_lastLots(0.0), m_lastPrice(0.0), m_lastSL(0.0), m_lastTP(0.0) {}

    //+------------------------------------------------------------------+
    //| Setup Methods                                                     |
    //+------------------------------------------------------------------+
    void SetShouldSucceed(bool succeed) { m_shouldSucceed = succeed; }
    void SetMockTicket(ulong ticket) { m_mockTicket = ticket; }
    void ResetCallCounts() {
        m_openTradeCallCount      = 0;
        m_closePositionCallCount  = 0;
        m_modifyPositionCallCount = 0;
        m_cancelOrderCallCount    = 0;
    }

    //+------------------------------------------------------------------+
    //| IExecution Implementation                                         |
    //+------------------------------------------------------------------+
    bool OpenTrade(const string sym, long magic, const ENUM_TRADE_TYPE type, double volume,
                   double price, double sl, double tp, int deviation_points, ulong &ticket_out,
                   const string comment = "", ENUM_ORDER_TYPE_TIME type_time = ORDER_TIME_GTC,
                   datetime expiration = 0) override {
        m_openTradeCallCount++;
        m_lastSymbol    = sym;
        m_lastOrderType = ToOrderType(type);
        m_lastLots      = volume;
        m_lastPrice     = price;
        m_lastSL        = sl;
        m_lastTP        = tp;
        m_lastComment   = comment;

        if(m_shouldSucceed) {
            ticket_out = m_mockTicket;
            m_mockTicket++; // Auto-increment for next call
            return true;
        }
        return false;
    }

    bool ModifyPositionByTicket(const ulong ticket, const double sl, const double tp) override {
        m_modifyPositionCallCount++;
        m_lastSL = sl;
        m_lastTP = tp;
        return m_shouldSucceed;
    }

    int ClosePositionsByTickets(const ulong &tickets[]) override {
        m_closePositionCallCount += ArraySize(tickets);
        return m_shouldSucceed ? ArraySize(tickets) : 0;
    }

    int CloseAllBySymbolMagic(const string sym, long magic) override {
        m_closePositionCallCount++;
        return m_shouldSucceed ? 1 : 0;
    }

    bool ModifyPending(ulong order_ticket, double price, double sl, double tp) override {
        m_modifyPositionCallCount++;
        m_lastPrice = price;
        m_lastSL    = sl;
        m_lastTP    = tp;
        return m_shouldSucceed;
    }

    bool DeletePending(ulong order_ticket) override {
        m_cancelOrderCallCount++;
        return m_shouldSucceed;
    }

    int DeleteAllPendings(const string sym, long magic) override {
        m_cancelOrderCallCount++;
        return m_shouldSucceed ? 1 : 0;
    }

    //+------------------------------------------------------------------+
    //| Verification Methods                                              |
    //+------------------------------------------------------------------+
    int GetOpenTradeCallCount() const { return m_openTradeCallCount; }
    int GetClosePositionCallCount() const { return m_closePositionCallCount; }
    int GetModifyPositionCallCount() const { return m_modifyPositionCallCount; }
    int GetCancelOrderCallCount() const { return m_cancelOrderCallCount; }

    string GetLastSymbol() const { return m_lastSymbol; }
    ENUM_ORDER_TYPE GetLastOrderType() const { return m_lastOrderType; }
    double GetLastLots() const { return m_lastLots; }
    double GetLastPrice() const { return m_lastPrice; }
    double GetLastSL() const { return m_lastSL; }
    double GetLastTP() const { return m_lastTP; }
    string GetLastComment() const { return m_lastComment; }
};
