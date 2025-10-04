#include <AutoTrader/domain/enums/Enum.mqh>
#include <AutoTrader/trailing/Trailing_BreakEven.mqh>

input group "<----COMMON SETTINGS----->";
input ulong InpMagic               = 45456; /* Magic Number */  // Magic Number
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M1; /* Timeframe */ // Timeframe

input group "<----SIGNAL SETTINGS----->";
input int InpTimeStartHour = 10; /* Time Start Hour */ // Giờ bắt đầu
input int InpTimeStartMin  = 0; /* Time Start Min */   // Phút bắt đầu
input int InpTimeEndHour   = 17; /* Time End Hour */   // Giờ kết thúc
input int InpTimeEndMin    = 0; /* Time End Min */     // Phút kết thúc
input bool InpDeleteOldBox = true;                     // Xoá hộp Range cũ khi bắt đầu ghi mới

input group "<----RANGE FILTER SETTINGS----->";
input double InpMinRangePoints  = 0; // Giá trị tối thiểu của Range Filter (khi dùng POINTS)
input double InpMaxRangePoints  = 0; // Giá trị tối đa của Range Filter (khi dùng POINTS)
input double InpMinRangePercent = 0; // Giá trị tối thiểu của Range Filter (khi dùng

input group "<----POSITIONS SETTINGS----->";
input bool InpCloseOnNewSignal         = false;          // Đóng vị thế khi có tín hiệu mới
input ENUM_CLOSE_TIME_MODE InpClosePositionType = CLOSE_TIME_OFF; // Kiểu đóng Position
input string InpDailyPositionCloseTime          = "18:00";        // Thời gian đóng vị thế [HH:MM]
// input int InpMaxBuyPositions                        = 1; // Số lượng vị thế mua tối đa trong ngày
// input int InpMaxSellPositions                       = 1; // Số lượng vị thế bán tối đa trong ngày
// input int InpMaxTotalPositions                      = 2; // Tổng số vị thế tối đa trong ngày

input group "<----ORDER SETTINGS----->";
input bool InpDeleteRemainingOrderOnFill = false;   // Xóa lệnh Order còn lại khi khớp
input double InpOrderBufferPoints        = 10.0;    // Điểm buffer cho lệnh
input bool InpDeletePendingOrders        = true;    // Xóa lệnh Order nếu chưa được khớp
input string InpPendingOrderExpiryTime   = "18:00"; // Thời gian xóa lệnh Order [HH:MM]

//                                      // PERCENT)
// input double InpMaxRangePercent = 0; // Giá trị tối đa của Range Filter (khi dùng PERCENT)

input group "<----TARGET SETTINGS----->";
input ENUM_TARGET_CALC_MODE InpTargetMode   = CALC_MODE_FACTOR; // Phương pháp tính Target
input double InpTargetValue                 = 2.0;              // Giá trị Target
input ENUM_TARGET_CALC_MODE InpStopLossMode = CALC_MODE_FACTOR; // Phương pháp tính Stop Loss
input double InpStopValue                   = 1.0;              // Giá trị Stop Loss

input group "<----LOTSIZE SETTINGS----->";
input ENUM_LOT_CALC_MODE InpLotMode = CALC_MODE_FIXED; // Phương pháp tính Lot Size
input double InpLotValue            = 0.01;            // Giá trị Calc Lot

input group "<----TRAILING STOP SETTINGS----->";
input ENUM_TRAILING_STOP_MODE InpTrailingMode = TRAILING_STOP_OFF; // Chế độ trailing stop
input ENUM_TSL_CALC_MODE InpBECalcMode        = TSL_CALC_PERCENT;  // Phương pháp tính BE Stop
input double InpBeStopTrigger                 = 0.5;  // Giá trị BE-Trigger : Points, Percent
input double InpBeStopBufferValue             = 0.05; // Giá trị BE-Buffer : Points, Percent

input ENUM_TSL_CALC_MODE InpTslCalcMode    = TSL_CALC_PERCENT; // Phương pháp tính TSL Stop
input double InpTslTrigger   = 0.7;  // Giá trị Distance Trigger : Points, Percent, RR
input double InpTslDistance  = 0.1;  // Giá trị Distance SL : Points, Percent, RR
input double InpTslStepValue = 0.05; // Giá trị Distance Step : Points, Percent, RR

// input group "<----MORE SETTINGS----->";
// input bool InpEnableComment = true;                  // Có hiển thị comment hay không
// input string InpFilePath    = "RangeBreakoutEA.csv"; // Đường dẫn file name.csv
// input bool InpSaveToFile    = false;                 // Lưu vào file
