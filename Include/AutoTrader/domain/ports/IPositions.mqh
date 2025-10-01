//+------------------------------------------------------------------+
//| Include/AutoTrader/domain/ports/IPositions.mqh                   |
//+------------------------------------------------------------------+

enum ENUM_POS_SIDE { POS_SIDE_BUY = POSITION_TYPE_BUY, POS_SIDE_SELL = POSITION_TYPE_SELL };

struct PositionInfo {
  // --- string props ---
  string symbol;      // POSITION_SYMBOL
  ulong magic;        // POSITION_MAGIC
  string comment;     // POSITION_COMMENT
  string external_id; // POSITION_EXTERNAL_ID

  // --- integer/datetime props ---
  ulong ticket;    // POSITION_TICKET (as ulong for convenience)
  long identifier; // POSITION_IDENTIFIER (order ticket that opened/reopened)

  long type;   // POSITION_TYPE (ENUM_POSITION_TYPE)
  long reason; // POSITION_REASON (ENUM_POSITION_REASON)

  datetime time;        // POSITION_TIME
  long time_msc;        // POSITION_TIME_MSC
  datetime time_update; // POSITION_TIME_UPDATE
  long time_update_msc; // POSITION_TIME_UPDATE_MSC

  // --- double props ---
  double volume;        // POSITION_VOLUME
  double price_open;    // POSITION_PRICE_OPEN
  double price_current; // POSITION_PRICE_CURRENT
  double sl;            // POSITION_SL
  double tp;            // POSITION_TP
  double swap;          // POSITION_SWAP
  double profit;        // POSITION_PROFIT

  // tiện ích
  bool IsSell() const { return (type == POSITION_TYPE_SELL); }
  bool IsBuy() const { return (type == POSITION_TYPE_BUY); }
};

class IPositions {
public:
  // Tổng số position mở
  virtual int Total() = 0;
  // Lấy vị thế mới nhất theo symbol & magic
  virtual bool Current(const string sym, const long magic, PositionInfo &out) = 0;
  // Lấy vị thế đầu tiên (oldest) theo symbol & magic
  virtual bool FirstBySymbolMagic(const string sym, const long magic, PositionInfo &out) = 0;
  // Đếm số lượng vị thế theo symbol & magic
  virtual int CountBySymbolMagic(const string sym, const long magic) = 0;
  // Lấy danh sách các vị thế theo symbol & magic
  virtual int ListBySymbolMagic(const string sym, const long magic, PositionInfo &buffer[]) = 0;

};
//+------------------------------------------------------------------+
