
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>

//+------------------------------------------------------------------+
//| TelegramEventHandler.mqh - Telegram notifications                 |
//+------------------------------------------------------------------+
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>

class TelegramEventHandler : public ITradeEventHandler {
  private:
    string m_botToken;
    string m_chatId;

  public:
    TelegramEventHandler(string botToken, string chatId) {
        m_botToken = botToken;
        m_chatId   = chatId;
    }

    void OnTradeEvent(const TradeEventContext &ctx) override {
        string message = FormatMessage(ctx);
        if(message != "") { SendTelegram(message); }
    }

    bool ShouldHandle(TRADE_EVENT_TYPE eventType) override {
        // Chỉ gửi notification cho các event quan trọng
        return (eventType == TRADE_EVENT_ORDER_FILLED || eventType == TRADE_EVENT_CLOSE
                || eventType == TRADE_EVENT_TRAILING);
    }

  private:
    string FormatMessage(const TradeEventContext &ctx) {
        string emoji = "";
        string title = "";

        switch(ctx.eventType) {
        case TRADE_EVENT_ORDER_FILLED:
            emoji = "🟢";
            title = "NEW POSITION";
            break;
        case TRADE_EVENT_CLOSE:
            emoji = "🔴";
            title = "CLOSED";
            break;
        case TRADE_EVENT_TRAILING:
            emoji = "📈";
            title = "TRAILING STOP";
            break;
        default: return "";
        }

        string msg
            = StringFormat("%s *%s*\n"
                           "Symbol: %s\n"
                           "Ticket: #%I64u\n"
                           "Volume: %.2f\n"
                           "Price: %.5f\n"
                           "SL: %.5f | TP: %.5f\n"
                           "Time: %s",
                           emoji, title, ctx.symbol, ctx.ticket, ctx.volume, ctx.price, ctx.sl,
                           ctx.tp, TimeToString(ctx.eventTime, TIME_DATE | TIME_SECONDS));

        if(ctx.comment != "") { msg += "\nNote: " + ctx.comment; }

        return msg;
    }

    void SendTelegram(string message) {
        // Skip nếu đang chạy trong Strategy Tester hoặc Optimization
        if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION)) {
            // Print("[Telegram] Skipped (running in tester mode): ", message);
            return;
        }

        string url    = "https://api.telegram.org/bot" + m_botToken + "/sendMessage";
        string params = "chat_id=" + m_chatId + "&text=" + message + "&parse_mode=Markdown";

        char data[];
        char result[];
        string headers = "Content-Type: application/x-www-form-urlencoded\r\n";

        StringToCharArray(params, data, 0, StringLen(params));

        int timeout = 5000;
        int res     = WebRequest("POST", url, headers, timeout, data, result, headers);

        if(res == -1) {
            int error = GetLastError();
            if(error == 4014) { // ERR_FUNCTION_NOT_ALLOWED
                Print("[Telegram] ERROR: URL not allowed. Please add 'https://api.telegram.org' to "
                      "Tools -> Options -> Expert Advisors -> Allow WebRequest for listed URL");
            } else {
                Print("[Telegram] Send failed. Error: ", error);
            }
        }
    }
};