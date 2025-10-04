//+------------------------------------------------------------------+
//| Mt5PositionsAdapter.mqh                                           |
//| Adapter chuẩn hóa truy xuất positions từ MT5                      |
//+------------------------------------------------------------------+

#property strict

#include <AutoTrader/domain/ports/IPositions.mqh>

//+------------------------------------------------------------------+
//| Mt5PositionsAdapter - Implementation của IPositions               |
//+------------------------------------------------------------------+
class Mt5PositionsAdapter : public IPositions {
  public:
    //+------------------------------------------------------------------+
    //| Constructor                                                       |
    //+------------------------------------------------------------------+
    Mt5PositionsAdapter() {}

    //+------------------------------------------------------------------+
    //| Tổng số positions đang mở                                        |
    //+------------------------------------------------------------------+
    int Total() override { return PositionsTotal(); }

    //+------------------------------------------------------------------+
    //| Lấy position mới nhất theo symbol + magic                        |
    //| BUG FIX: Duyệt ngược để lấy position mới nhất                    |
    //+------------------------------------------------------------------+
    bool Current(const string sym, const long magic, PositionInfo &out) override {
        const int total = PositionsTotal();

        // Duyệt từ cuối về đầu để lấy position mới nhất
        for(int i = total - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0) continue;

            // OPTIMIZATION: Không cần PositionSelectByTicket nếu đã có ticket
            // Vì PositionGetTicket đã select position rồi
            string psym = PositionGetString(POSITION_SYMBOL);
            long pmag   = PositionGetInteger(POSITION_MAGIC);

            if(psym == sym && pmag == magic) { return FillPositionInfo(out, ticket); }
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Lấy position đầu tiên theo symbol + magic                        |
    //+------------------------------------------------------------------+
    bool FirstBySymbolMagic(const string sym, const long magic, PositionInfo &out) override {
        const int total = PositionsTotal();

        for(int i = 0; i < total; i++) {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0) continue;

            string psym = PositionGetString(POSITION_SYMBOL);
            long pmag   = PositionGetInteger(POSITION_MAGIC);

            if(psym == sym && pmag == magic) { return FillPositionInfo(out, ticket); }
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Lấy danh sách positions theo symbol + magic                      |
    //| BUG FIX: Dynamic array resize, validate buffer size              |
    //+------------------------------------------------------------------+
    int ListBySymbolMagic(const string sym, const long magic, PositionInfo &buffer[]) override {
        const int total = PositionsTotal();
        if(total <= 0) return 0;

        // Pre-allocate buffer với size tối đa
        ArrayResize(buffer, total);
        int written = 0;

        for(int i = 0; i < total; i++) {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0) continue;

            string psym = PositionGetString(POSITION_SYMBOL);
            long pmag   = PositionGetInteger(POSITION_MAGIC);

            if(psym == sym && pmag == magic) {
                if(FillPositionInfo(buffer[written], ticket)) { written++; }
            }
        }

        // Resize buffer về đúng size thực tế
        if(written < total) { ArrayResize(buffer, written); }

        return written;
    }

    //+------------------------------------------------------------------+
    //| Đếm số positions theo symbol + magic                             |
    //| OPTIMIZATION: Không cần fill full info, chỉ count                |
    //+------------------------------------------------------------------+
    int CountBySymbolMagic(const string sym, const long magic) override {
        const int total = PositionsTotal();
        int count       = 0;

        for(int i = 0; i < total; i++) {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0) continue;

            string psym = PositionGetString(POSITION_SYMBOL);
            long pmag   = PositionGetInteger(POSITION_MAGIC);

            if(psym == sym && pmag == magic) { count++; }
        }

        return count;
    }

    //+------------------------------------------------------------------+
    //| Đọc thông tin position từ ticket                                 |
    //| PUBLIC: Để các class khác có thể sử dụng trực tiếp               |
    //+------------------------------------------------------------------+
    bool GetPositionInfo(PositionInfo &out, const ulong ticket) {
        if(!PositionSelectByTicket(ticket)) return false;
        return FillPositionInfo(out, ticket);
    }

    //+------------------------------------------------------------------+
    //| Đọc position theo index (support internal iteration)             |
    //+------------------------------------------------------------------+
    bool GetPositionInfoByIndex(PositionInfo &out, int index) {
        ulong ticket = PositionGetTicket(index);
        if(ticket == 0) return false;
        return FillPositionInfo(out, ticket);
    }

    //+------------------------------------------------------------------+
    //| Kiểm tra xem có positions nào đang mở không                       |
    //| @param magic   Magic number để lọc positions                      |
    //| @param symbol  Symbol để lọc positions                            |
    //| @return       true nếu có ít nhất 1 position đang mở             |
    //+------------------------------------------------------------------+
    bool HasOpenPositions(const string symbol, const ulong magic) override {
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

  private:
    //+------------------------------------------------------------------+
    //| Fill PositionInfo struct từ MT5 position properties              |
    //| IMPORTANT: Assume position đã được select trước đó               |
    //+------------------------------------------------------------------+
    bool FillPositionInfo(PositionInfo &out, const ulong ticket) {
        // Validate position exists
        if(ticket == 0) return false;

        // Fill basic info
        out.ticket      = ticket;
        out.symbol      = PositionGetString(POSITION_SYMBOL);
        out.comment     = PositionGetString(POSITION_COMMENT);
        out.external_id = PositionGetString(POSITION_EXTERNAL_ID);

        // Fill integer fields
        out.magic           = PositionGetInteger(POSITION_MAGIC);
        out.identifier      = PositionGetInteger(POSITION_IDENTIFIER);
        out.type            = PositionGetInteger(POSITION_TYPE);
        out.reason          = PositionGetInteger(POSITION_REASON);
        out.time            = (datetime)PositionGetInteger(POSITION_TIME);
        out.time_msc        = PositionGetInteger(POSITION_TIME_MSC);
        out.time_update     = (datetime)PositionGetInteger(POSITION_TIME_UPDATE);
        out.time_update_msc = PositionGetInteger(POSITION_TIME_UPDATE_MSC);

        // Fill double fields
        out.volume        = PositionGetDouble(POSITION_VOLUME);
        out.price_open    = PositionGetDouble(POSITION_PRICE_OPEN);
        out.price_current = PositionGetDouble(POSITION_PRICE_CURRENT);
        out.sl            = PositionGetDouble(POSITION_SL);
        out.tp            = PositionGetDouble(POSITION_TP);
        out.swap          = PositionGetDouble(POSITION_SWAP);
        out.profit        = PositionGetDouble(POSITION_PROFIT);

        // Validation: Symbol must not be empty
        if(out.symbol == "") return false;

        return true;
    }
};