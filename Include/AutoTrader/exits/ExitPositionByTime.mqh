
#include <AutoTrader/domain/enums/Enum.mqh>
#include <AutoTrader/domain/ports/IExitSignal.mqh>
#include <AutoTrader/domain/ports/IMarketData.mqh>
#include <AutoTrader/utils/Positions.mqh>

class ExitPositionByTime : public IExitSignal {
  // Thời gian đóng vị thế trong ngày
  const string closePositionTime;
  ENUM_CLOSE_TIME_MODE timeMode;

public:
  ExitPositionByTime(ENUM_CLOSE_TIME_MODE mode, const string closeTime)
      : timeMode(mode), closePositionTime(closeTime) {}

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
};
