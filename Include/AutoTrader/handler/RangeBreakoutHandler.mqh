// RangeBreakoutHandler.mqh

#include <AutoTrader/domain/ports/IExecution.mqh>
#include <AutoTrader/domain/ports/IOrders.mqh>
#include <AutoTrader/domain/ports/IPositions.mqh>
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>

class RangeBreakoutHandler : public ITradeEventHandler {
  private:
    IExecution *m_exec;
    IOrders *m_orders;
    IPositions *m_pos;
    bool m_cancelRemainingOrdersOnFill;
    bool m_deleteRemainingOrderOnFill;

    const string m_sys;
    const ulong m_magic;

    void HandleCancelPendingOnFill() {
        if(!m_orders || !m_pos || !m_exec) return;
        if(m_pos.CountBySymbolMagic(m_sys, m_magic) <= 0) return; // Chỉ hủy nếu đã có position
        m_exec.DeleteAllPendings(m_sys, m_magic);
    }

  public:
    RangeBreakoutHandler(IExecution *exec, IOrders *orders, IPositions *positions, const string sym,
                         const ulong magic, const bool cancelRemainingOrdersOnFill)
        : m_exec(exec), m_orders(orders), m_pos(positions), m_sys(sym), m_magic(magic),
          m_cancelRemainingOrdersOnFill(cancelRemainingOrdersOnFill) {}

    void OnTradeEvent(const TradeEventContext &ctx) override {
        if(!m_cancelRemainingOrdersOnFill) return;
        if(ctx.eventType != TRADE_EVENT_ORDER_FILLED) return;
        HandleCancelPendingOnFill();
    }

    bool ShouldHandle(TRADE_EVENT_TYPE eventType) override {
        // Handle all events except SYSTEM
        return eventType != TRADE_EVENT_SYSTEM;
    }
};