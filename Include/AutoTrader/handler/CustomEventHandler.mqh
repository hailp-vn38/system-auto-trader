// CustomEventHandler.mqh
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>

class CustomEventHandler : public ITradeEventHandler {
private:
  int m_tradeCount;
  double m_totalProfit;

public:
  CustomEventHandler() : m_tradeCount(0), m_totalProfit(0.0) {}

  void OnTradeEvent(const TradeEventContext &ctx) override {
    switch(ctx.eventType) {
    case TRADE_EVENT_ORDER_FILLED: {
      m_tradeCount++;
      PrintFormat("Trade #%d opened at %.5f", m_tradeCount, ctx.price);
      break;
    }

    case TRADE_EVENT_CLOSE: {
      // Extract profit from comment (format: "Comment P/L:123.45")
      int pos = StringFind(ctx.comment, "P/L:");
      if(pos >= 0) {
        double profit = StringToDouble(StringSubstr(ctx.comment, pos + 4));
        m_totalProfit += profit;
        PrintFormat("Total P/L: %.2f", m_totalProfit);
      }
      break;
    }

    case TRADE_EVENT_TRAILING: {
      PrintFormat("Trailing activated for #%I64u - New SL: %.5f", ctx.ticket, ctx.sl);
      break;
    }
    }
  }

  bool ShouldHandle(TRADE_EVENT_TYPE eventType) override {
    // Handle all events except SYSTEM
    return eventType != TRADE_EVENT_SYSTEM;
  }

  // Getters for statistics
  int GetTradeCount() const { return m_tradeCount; }
  double GetTotalProfit() const { return m_totalProfit; }
};