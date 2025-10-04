
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>

//+------------------------------------------------------------------+
//| CompositeEventHandler.mqh - Multiple handlers                     |
//+------------------------------------------------------------------+
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>

class CompositeEventHandler : public ITradeEventHandler {
private:
  ITradeEventHandler *m_handlers[];
  int m_count;

public:
  CompositeEventHandler() : m_count(0) {
    ArrayResize(m_handlers, 0);
  }
  
  ~CompositeEventHandler() {
    // Cleanup handlers
    for(int i = 0; i < m_count; i++) {
      if(m_handlers[i] != NULL) {
        delete m_handlers[i];
      }
    }
  }
  
  void AddHandler(ITradeEventHandler *handler) {
    if(handler == NULL) return;
    
    ArrayResize(m_handlers, m_count + 1);
    m_handlers[m_count] = handler;
    m_count++;
  }
  
  void OnTradeEvent(const TradeEventContext &ctx) override {
    for(int i = 0; i < m_count; i++) {
      if(m_handlers[i] != NULL && m_handlers[i].ShouldHandle(ctx.eventType)) {
        m_handlers[i].OnTradeEvent(ctx);
      }
    }
  }
};
