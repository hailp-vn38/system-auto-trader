
#include "App_Config.mqh"
#include "App_Constants.mqh"

#include <AutoTrader/adapters/mt5/Mt5ExecutionAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5MarketDataAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5OrdersAdapter.mqh>
#include <AutoTrader/adapters/mt5/Mt5PositionsAdapter.mqh>
#include <AutoTrader/adapters/storage/HttpApiStorageBatch.mqh>
#include <AutoTrader/adapters/storage/SQLiteStorage.mqh>
#include <AutoTrader/adapters/telemetry/PrintLogger.mqh>
#include <AutoTrader/app/Orchestrator.mqh>
#include <AutoTrader/domain/policies/Risk_AllowOneOpen.mqh>
#include <AutoTrader/domain/ports/ITargets.mqh>
#include <AutoTrader/exits/RangeBreakoutExits.mqh>
#include <AutoTrader/handler/RangeBreakoutHandler.mqh>
#include <AutoTrader/sizers/Sizer_MultiMode.mqh>
#include <AutoTrader/strategies/RangeBreakout.mqh>
#include <AutoTrader/targets/Target_MultiMode.mqh>
#include <AutoTrader/trailing/Trailing_BreakEven.mqh>
#include <AutoTrader/trailing/Trailing_Distance.mqh>
#include <AutoTrader/utils/BarTimer.mqh>

Mt5MarketDataAdapter *g_md;
Mt5ExecutionAdapter *g_exec;
Mt5PositionsAdapter *g_pos;
Mt5OrdersAdapter *g_orders;

Risk_AllowOneOpen *g_risk;
Sizer_MultiMode *g_sizer;

RangeBreakout *g_sig;

ITargets *g_targets;
RangeBreakoutExits *g_exit;
PrintLogger *g_log;

ITrailing *g_trail;

RangeBreakoutHandler *handler;
Orchestrator *g_app;
BarTimer *g_barTimer;

//+------------------------------------------------------------------+
//| Map ENUM_TARGET_CALC_MODE to ENUM_TSL_CALC_MODE                  |
//+------------------------------------------------------------------+
ENUM_TSL_CALC_MODE MapTrailingCalcMode(const ENUM_TARGET_CALC_MODE mode) {
    switch(mode) {
    case CALC_MODE_POINTS: return TSL_CALC_POINTS;
    case CALC_MODE_PERCENT: return TSL_CALC_PERCENT;
    case CALC_MODE_FACTOR: return TSL_CALC_RR;
    default: return TSL_CALC_OFF;
    }
}

//+------------------------------------------------------------------+
//| Khởi tạo Trailing Break Even                                     |
//+------------------------------------------------------------------+
ITrailing *createTrailingBreakEven() {
    return new Trailing_BreakEven(g_md, g_exec, g_pos, InpBeStopTrigger, InpBeStopBufferValue,
                                  InpBECalcMode);
}

//+------------------------------------------------------------------+
//| Khởi tạo Trailing Distance                                       |
//+------------------------------------------------------------------+
ITrailing *createTrailingDistance() {
    // Chuyển đổi mode từ config sang TSL mode
    ENUM_TSL_CALC_MODE tslMode = MapTrailingCalcMode(InpTslCalcMode);

    // Validate mode: Distance trailing yêu cầu mode cụ thể (không cho phép OFF)
    if(tslMode == TSL_CALC_OFF) {
        if(g_log) {
            g_log.Warn("[RangeBreakout] Trailing distance yêu cầu mode Points/Percent/Factor - "
                       "mặc định chuyển sang Percent.");
        }
        tslMode = TSL_CALC_PERCENT;
    }

    // Tạo instance với đầy đủ dependencies
    return new Trailing_Distance(g_md, g_exec, g_pos, InpTslTrigger, InpTslDistance,
                                 InpTslStepValue, tslMode, g_log);
}

//+------------------------------------------------------------------+
//| Khởi tạo Trailing Stop strategy theo config                      |
//| @return ITrailing* - trailing instance hoặc NULL nếu disabled    |
//+------------------------------------------------------------------+
ITrailing *initializeTrailing() {
    switch(InpTrailingMode) {
    case TRAILING_STOP_BREAK_EVEN: {
        if(g_log) g_log.Info("[RangeBreakout] Initializing Trailing Break Even...");
        return createTrailingBreakEven();
    }

    case TRAILING_STOP_DISTANCE: {
        if(g_log) g_log.Info("[RangeBreakout] Initializing Trailing Distance...");
        return createTrailingDistance();
    }

    default: {
        if(g_log) g_log.Info("[RangeBreakout] Trailing stop disabled (TRAILING_STOP_OFF).");
        return NULL;
    }
    }
}

int OnInit() {
    // Khởi tạo Logger trước để dùng cho các component khác
    g_log = new PrintLogger();

    // Khởi tạo Adapter
    g_md     = new Mt5MarketDataAdapter();
    g_exec   = new Mt5ExecutionAdapter(InpMagic, 0);
    g_pos    = new Mt5PositionsAdapter();
    g_orders = new Mt5OrdersAdapter();

    // Khởi tạo sizer theo mode đã chọn
    g_sizer = new Sizer_MultiMode(InpLotValue, InpLotMode);

    // Cho phép trade
    g_risk = new Risk_AllowOneOpen(g_pos, 1);

    // Khởi tạo chiến lược open/close
    g_sig = new RangeBreakout(g_md, InpTimeStartHour, InpTimeStartMin, InpTimeEndHour,
                              InpTimeEndMin, InpMinRangePoints, InpMaxRangePoints,
                              InpOrderBufferPoints, InpDeleteOldBox);
    if(!g_sig.IsReady()) {
        Print("Signal not ready");
        return (INIT_FAILED);
    }

    g_exit = new RangeBreakoutExits(g_orders, InpClosePositionType, InpDailyPositionCloseTime,
                                    InpPendingOrderExpiryTime, InpDeletePendingOrders);

    // Khởi tạo tính stoplost/takeprofit
    g_targets
        = new Target_MultiMode(g_md, InpTargetValue, InpTargetMode, InpStopValue, InpStopLossMode);

    // Khởi tạo Trailing Stop strategy
    g_trail = initializeTrailing();

    // Khởi tạo handler sự kiện (tuỳ chọn)
    handler = new RangeBreakoutHandler(g_exec, g_orders, g_pos, _Symbol, InpMagic,
                                       InpClosePositionsOnNewSignal);

    if(_Period != InpTimeframe) {
        Print("[RangeBreakout] Warning: Chart timeframe ", EnumToString(_Period),
              " khác với cấu hình InpTimeframe=", EnumToString(InpTimeframe),
              ". EA sẽ chạy theo InpTimeframe.");
    }

    // Orchestrator: bắt buộc (signal, exec, marketdata)
    g_app      = new Orchestrator(_Symbol, InpTimeframe, 5, InpMagic, g_sig, g_exec, g_md);

    g_barTimer = new BarTimer(_Symbol, InpTimeframe);

    g_app.SetSizer(g_sizer);
    g_app.SetTargets(g_targets);
    if(g_risk != NULL) { g_app.SetRisk(g_risk); }
    g_app.SetExitSignal(g_exit);
    if(g_trail != NULL) { g_app.SetTrailing(g_trail); }
    g_app.SetEventHandler(handler);

    if(g_log) g_log.Info("EA Init OK");
    Comment("EMA(21/50) demo running..."); // quick HUD
    return (INIT_SUCCEEDED);
}

void OnTick() {
    // Chỉ chạy khi có nến mới
    if(g_barTimer.IsNewBar() && g_app != NULL) { g_app.OnTick(); }
}

//+------------------------------------------------------------------+
//| Trade transaction event handler                                   |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request,
                        const MqlTradeResult &result) {
    if(g_app != NULL) { g_app.OnTradeTransaction(trans, request, result); }
}

void OnDeinit(const int reason) {
    if(g_app != NULL) {
        g_app.OnDeinit();
        delete g_app;
        g_app = NULL;
    }

    if(handler != NULL) {
        delete handler;
        handler = NULL;
    }

    if(g_log != NULL) {
        delete g_log;
        g_log = NULL;
    }

    if(g_trail != NULL) {
        delete g_trail;
        g_trail = NULL;
    }

    if(g_targets != NULL) {
        delete g_targets;
        g_targets = NULL;
    }

    if(g_exit != NULL) {
        delete g_exit;
        g_exit = NULL;
    }

    if(g_sig != NULL) {
        delete g_sig;
        g_sig = NULL;
    }

    if(g_sizer != NULL) {
        delete g_sizer;
        g_sizer = NULL;
    }

    if(g_risk != NULL) {
        delete g_risk;
        g_risk = NULL;
    }

    if(g_exec != NULL) {
        delete g_exec;
        g_exec = NULL;
    }

    if(g_orders != NULL) {
        delete g_orders;
        g_orders = NULL;
    }

    if(g_md != NULL) {
        delete g_md;
        g_md = NULL;
    }

    if(g_pos != NULL) {
        delete g_pos;
        g_pos = NULL;
    }

    if(g_barTimer != NULL) {
        delete g_barTimer;
        g_barTimer = NULL;
    }
}
