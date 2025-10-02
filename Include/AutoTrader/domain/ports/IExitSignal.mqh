// Include/AutoTrader/domain/ports/IExitSignal.mqh

#include <AutoTrader/domain/ports/IOrders.mqh>
#include <AutoTrader/domain/ports/IPositions.mqh>

/**
 * @brief Interface for exit signal logic.
 * This interface defines methods for determining when to exit open positions
 * and optionally cancel pending orders based on market conditions.
 * Now includes IOrders for self-contained order cancellation logic.
 */
class IExitSignal {
  protected:
    IPositions *m_positions; ///< Position adapter
    IOrders *m_orders;       ///< Orders adapter for pending orders

  public:
    /**
     * @brief Sets the positions interface for accessing position data.
     * @param p Pointer to the IPositions interface.
     */
    void SetPositions(IPositions *p) { m_positions = p; }

    /**
     * @brief Sets the orders interface for accessing pending orders.
     * @param o Pointer to the IOrders interface.
     */
    void SetOrders(IOrders *o) { m_orders = o; }

    IExitSignal() : m_positions(NULL), m_orders(NULL) {}

    /**
     * @brief Determines if open positions should be closed based on exit conditions.
     * @param sym The trading symbol.
     * @param tf The timeframe.
     * @param magic The magic number.
     * @param tickets Output array of position tickets to close.
     * @return true if positions should be exited, false otherwise.
     */
    virtual bool
    ShouldExit(const string sym, const ENUM_TIMEFRAMES tf, const long magic, ulong &tickets[])
        = 0;

    /**
     * @brief Determines if pending orders should be canceled.
     * Exit strategy can now use m_orders internally for decision making.
     * @param sym The trading symbol.
     * @param tf The timeframe.
     * @param magic The magic number.
     * @return true if orders should be canceled, false otherwise.
     */
    virtual bool ShouldCancelOrders(const string sym, const ENUM_TIMEFRAMES tf, const long magic) {
        return false;
    }

    /**
     * @brief Gets list of order tickets to cancel (optional selective cancellation).
     * Override this for strategies that need selective order cancellation.
     * Default implementation: returns all orders if ShouldCancelOrders is true.
     * @param sym The trading symbol.
     * @param tf The timeframe.
     * @param magic The magic number.
     * @param tickets Output array of order tickets to cancel.
     * @return true if there are orders to cancel, false otherwise.
     */
    virtual bool GetOrdersToCancel(const string sym, const ENUM_TIMEFRAMES tf, const long magic,
                                   ulong &tickets[]) {
        // Default: return all orders if ShouldCancelOrders is true
        if(!ShouldCancelOrders(sym, tf, magic)) return false;
        if(m_orders == NULL) return false;

        OrderInfo orders[];
        int count = m_orders.ListBySymbolMagic(sym, magic, orders);
        if(count <= 0) return false;

        ArrayResize(tickets, count);
        for(int i = 0; i < count; i++) { tickets[i] = orders[i].ticket; }

        return true;
    }

    virtual ~IExitSignal() {}
};
