
#include <AutoTrader/domain/enums/Enum.mqh>
#include <AutoTrader/domain/ports/IExitSignal.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/utils/Positions.mqh>

class RangeBreakoutExits : public IExitSignal {
    // Thời gian đóng vị thế trong ngày
    const string closePositionTime;
    ENUM_CLOSE_TIME_MODE timeMode;
    const bool deletePendingOrders;
    const string pendingOrderExpiryTime;

  public:
    RangeBreakoutExits(IOrders *orders, ENUM_CLOSE_TIME_MODE mode, const string closeTime,
                       const string pendingTime, bool deletePending)
        : timeMode(mode), closePositionTime(closeTime), pendingOrderExpiryTime(pendingTime),
          deletePendingOrders(deletePending) {
        SetOrders(orders);
    }

    virtual bool
    ShouldExit(const string sym, const ENUM_TIMEFRAMES tf, const long magic, ulong &tickets[]) {
        if(closePositionTime == "") return false;
        if(timeMode == CLOSE_TIME_OFF) return false;
        // Kiểm tra có vị thế nào không
        if(PositionsEx::HasOpenPositions(sym, magic) == false) return false;
        // Kiểm tra thời gian
        datetime timeClose   = StringToTime(closePositionTime);
        datetime currentTime = TimeCurrent();
        if(timeMode == CLOSE_TIME_DAILY) {
            if(currentTime >= timeClose) {
                int ticketsCount = PositionsEx::GetPositions(sym, magic, tickets);
                if(ticketsCount == 0) return (false);
                return (true);
            }
        } else if(timeMode == CLOSE_TIME_NEXT_DAY) {
            if(currentTime >= timeClose) {
                int ticketsCount = PositionsEx::GetPositionsYesterday(sym, magic, tickets);
                if(ticketsCount == 0) return (false);
                return (true);
            }
        }
        return (false);
    }

    bool ShouldCancelOrders(const string sym, const ENUM_TIMEFRAMES tf, const long magic) override {
        if(m_orders == NULL || !deletePendingOrders || pendingOrderExpiryTime == "") return false;
        // Kiểm tra có lệnh nào không
        OrderInfo ord;
        if(!m_orders.FirstBySymbolMagic(sym, magic, ord)) return false;
        // Kiểm tra thời gian
        datetime timeClose   = StringToTime(pendingOrderExpiryTime);
        datetime currentTime = TimeCurrent();
        if(currentTime >= timeClose) {
            // Hủy lệnh chờ
            return true;
        }
        return false;
    }
};
