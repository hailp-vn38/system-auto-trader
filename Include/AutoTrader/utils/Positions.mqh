
namespace PositionsEx {
  //+------------------------------------------------------------------+
  //| Kiểm tra xem có positions nào đang mở không                       |
  //| @param magic   Magic number để lọc positions                      |
  //| @param symbol  Symbol để lọc positions                            |
  //| @return       true nếu có ít nhất 1 position đang mở             |
  //+------------------------------------------------------------------+
  bool HasOpenPositions(const string symbol, const ulong magic) {
    for(int i = PositionsTotal() - 1; i >= 0 && !IsStopped(); i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
        if(PositionGetInteger(POSITION_MAGIC) == magic
           && PositionGetString(POSITION_SYMBOL) == symbol) {
          return true;
        }
      }
    }
    return false;
  }

  bool SelectFirstBySymbolMagic(string sym, long magic, ulong &ticketOut) {
    int n = PositionsTotal();
    for(int i = 0; i < n; i++) {
      if(PositionSelectByTicket(i)) {
        string s = PositionGetString(POSITION_SYMBOL);
        long mg  = PositionGetInteger(POSITION_MAGIC);
        if(s == sym && mg == magic) {
          ticketOut = (ulong)PositionGetInteger(POSITION_TICKET);
          return true;
        }
      }
    }
    return false;
  }

  //+------------------------------------------------------------------+
  //| Tìm tất cả các positions dựa trên magic number và symbol          |
  //| @param magic   Magic number để lọc positions                      |
  //| @param symbol  Symbol để lọc positions                            |
  //| @param tickets Mảng chứa các ticket của positions tìm được        |
  //| @return       Số lượng positions tìm thấy                        |
  //+------------------------------------------------------------------+
  int GetPositions(const string symbol, const ulong magic, ulong &tickets[]) {
    ArrayFree(tickets);
    for(int i = PositionsTotal() - 1; i >= 0 && !IsStopped(); i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
        if(PositionGetInteger(POSITION_MAGIC) == magic
           && PositionGetString(POSITION_SYMBOL) == symbol) {
          int size = ArraySize(tickets);
          ArrayResize(tickets, size + 1);
          tickets[size] = ticket;
        }
      }
    }
    return ArraySize(tickets);
  }

  //+------------------------------------------------------------------+
  //| Tìm tất cả các positions được mở trong ngày hôm qua                |
  //| @param magic   Magic number để lọc positions                      |
  //| @param symbol  Symbol để lọc positions                            |
  //| @param tickets Mảng chứa các ticket của positions tìm được        |
  //| @return       Số lượng positions tìm thấy                        |
  //+------------------------------------------------------------------+
  int GetPositionsYesterday(const string symbol, const ulong magic, ulong &tickets[]) {
    ArrayFree(tickets);

    // Lấy thời gian bắt đầu của ngày hôm qua
    MqlDateTime today;
    TimeToStruct(TimeCurrent(), today);
    today.hour                = 0;
    today.min                 = 0;
    today.sec                 = 0;
    datetime startOfToday     = StructToTime(today);
    datetime startOfYesterday = startOfToday - PeriodSeconds(PERIOD_D1);
    datetime endOfYesterday   = startOfToday;

    for(int i = PositionsTotal() - 1; i >= 0 && !IsStopped(); i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
        if(PositionGetInteger(POSITION_MAGIC) == magic
           && PositionGetString(POSITION_SYMBOL) == symbol
           && PositionGetInteger(POSITION_TIME) >= startOfYesterday
           && PositionGetInteger(POSITION_TIME) < endOfYesterday) {
          int size = ArraySize(tickets);
          ArrayResize(tickets, size + 1);
          tickets[size] = ticket;
        }
      }
    }
    return ArraySize(tickets);
  }

}
