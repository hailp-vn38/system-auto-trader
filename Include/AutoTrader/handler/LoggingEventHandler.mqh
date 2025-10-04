//+------------------------------------------------------------------+
//| LoggingEventHandler.mqh - Console logging                         |
//+------------------------------------------------------------------+
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>

class LoggingEventHandler : public ITradeEventHandler {
public:
  void OnTradeEvent(const TradeEventContext &ctx) override {
    string eventName = GetEventName(ctx.eventType);
    
    PrintFormat("[%s] %s | Ticket: %I64u | %s | Vol: %.2f | Price: %.5f | SL: %.5f | TP: %.5f | %s",
                TimeToString(ctx.eventTime, TIME_DATE|TIME_SECONDS),
                eventName,
                ctx.ticket,
                ctx.symbol,
                ctx.volume,
                ctx.price,
                ctx.sl,
                ctx.tp,
                ctx.comment);
  }

private:
  string GetEventName(TRADE_EVENT_TYPE type) {
    switch(type) {
      case TRADE_EVENT_OPEN:          return "OPEN";
      case TRADE_EVENT_CLOSE:         return "CLOSE";
      case TRADE_EVENT_MODIFY:        return "MODIFY";
      case TRADE_EVENT_PARTIAL_CLOSE: return "PARTIAL";
      case TRADE_EVENT_TRAILING:      return "TRAILING";
      case TRADE_EVENT_ORDER_PLACED:  return "ORDER_PLACED";
      case TRADE_EVENT_ORDER_FILLED:  return "ORDER_FILLED";
      case TRADE_EVENT_ORDER_CANCEL:  return "ORDER_CANCEL";
      case TRADE_EVENT_SYSTEM:        return "SYSTEM";
      default: return "UNKNOWN";
    }
  }
};

//+------------------------------------------------------------------+
//| CompositeEventHandler.mqh - Multiple handlers                     |
//+------------------------------------------------------------------+
#include <AutoTrader/domain/ports/ITradeEventHandler.mqh>

class CompositeEventHandler : public ITradeEventHandler {
private:
  ITradeEventHandler *m_handlers[];
  int m_count;

public:
  CompositeEventHandler() : m_count(0) {
    ArrayResize(m_handlers, 0);
  }
  
  ~CompositeEventHandler() {
    // Cleanup handlers
    for(int i = 0; i < m_count; i++) {
      if(m_handlers[i] != NULL) {
        delete m_handlers[i];
      }
    }
  }
  
  void AddHandler(ITradeEventHandler *handler) {
    if(handler == NULL) return;
    
    ArrayResize(m_handlers, m_count + 1);
    m_handlers[m_count] = handler;
    m_count++;
  }
  
  void OnTradeEvent(const TradeEventContext &ctx) override {
    for(int i = 0; i < m_count; i++) {
      if(m_handlers[i] != NULL && m_handlers[i].ShouldHandle(ctx.eventType)) {
        m_handlers[i].OnTradeEvent(ctx);
      }
    }
  }
};

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
    m_chatId = chatId;
  }
  
  void OnTradeEvent(const TradeEventContext &ctx) override {
    string message = FormatMessage(ctx);
    if(message != "") {
      SendTelegram(message);
    }
  }
  
  bool ShouldHandle(TRADE_EVENT_TYPE eventType) override {
    // Chỉ gửi notification cho các event quan trọng
    return (eventType == TRADE_EVENT_ORDER_FILLED || 
            eventType == TRADE_EVENT_CLOSE ||
            eventType == TRADE_EVENT_TRAILING);
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
      default:
        return "";
    }
    
    string msg = StringFormat(
      "%s *%s*\n"
      "Symbol: %s\n"
      "Ticket: #%I64u\n"
      "Volume: %.2f\n"
      "Price: %.5f\n"
      "SL: %.5f | TP: %.5f\n"
      "Time: %s",
      emoji, title,
      ctx.symbol,
      ctx.ticket,
      ctx.volume,
      ctx.price,
      ctx.sl, ctx.tp,
      TimeToString(ctx.eventTime, TIME_DATE|TIME_SECONDS)
    );
    
    if(ctx.comment != "") {
      msg += "\nNote: " + ctx.comment;
    }
    
    return msg;
  }
  
  void SendTelegram(string message) {
    string url = "https://api.telegram.org/bot" + m_botToken + "/sendMessage";
    string params = "chat_id=" + m_chatId + "&text=" + message + "&parse_mode=Markdown";
    
    char data[];
    char result[];
    string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
    
    StringToCharArray(params, data, 0, StringLen(params));
    
    int timeout = 5000;
    int res = WebRequest("POST", url, headers, timeout, data, result, headers);
    
    if(res == -1) {
      Print("Telegram send failed: ", GetLastError());
    }
  }
};