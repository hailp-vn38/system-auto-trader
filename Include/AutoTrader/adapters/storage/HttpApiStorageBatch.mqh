
#include <AutoTrader/domain/ports/IStorage.mqh>
#include <AutoTrader/utils/JsonSchema.mqh>

class HttpApiStorageBatch : public IStorage {
  string endpoint, authHeader;
  string queue[]; // JSON events
  int threshold;
  datetime lastFlush;

public:
  HttpApiStorageBatch(string url, string auth, int flushThreshold = 10) {
    endpoint   = url;
    authHeader = auth;
    threshold  = flushThreshold;
    lastFlush  = 0;
    ArrayResize(queue, 0);
  }

  bool PostJSON(string json) {
    char data[];
    StringToCharArray(json, data);
    string headers = "Content-Type: application/json\r\n";
    if(StringLen(authHeader) > 0) { headers += authHeader + "\r\n"; }
    char result[];
    string result_headers;
    int code = WebRequest("POST", endpoint, headers, 8000, data, result, result_headers);
    if(code == 200 || code == 201) return true;
    PrintFormat("[HttpBatch] WebRequest code=%d", code);
    return false;
  }

  void Enqueue(string eventJson) {
    int n = ArraySize(queue);
    ArrayResize(queue, n + 1);
    queue[n] = eventJson;
    if(ArraySize(queue) >= threshold) Flush();
  }

  string BuildBatch() {
    string body = "[";
    for(int i = 0; i < ArraySize(queue); i++) {
      if(i > 0) body += ",";
      body += queue[i];
    }
    body += "]";
    return body;
  }

  virtual void SaveTradeOpen(string sym, long magic, ulong ticket, int orderType, double lots,
                             double price, double sl, double tp, datetime time) {
    Enqueue(JsonSchema::EventOpen(sym, magic, ticket, orderType, lots, price, sl, tp, time));
  }
  virtual void SaveTradeClose(string sym, long magic, ulong ticket, double closePrice,
                              double profit, datetime time, string reason) {
    Enqueue(JsonSchema::EventClose(sym, magic, ticket, closePrice, profit, time, reason));
  }
  virtual void SaveTrailing(string sym, long magic, ulong ticket, double newSL, datetime time) {
    Enqueue(JsonSchema::EventTrailing(sym, magic, ticket, newSL, time));
  }
  virtual void SaveOrderModify(string sym, long magic, ulong ticket, double newSL, double newTP,
                               datetime time, string reason) {
    Enqueue(JsonSchema::EventModify(sym, magic, ticket, newSL, newTP, time, reason));
  }
  virtual void SavePartialClose(string sym, long magic, ulong ticket, double closedLots,
                                double closePrice, double profit, datetime time, string reason) {
    Enqueue(JsonSchema::EventPartial(sym, magic, ticket, closedLots, closePrice, profit, time,
                                     reason));
  }

  virtual void Flush() {
    int n = ArraySize(queue);
    if(n == 0) return;
    string body = BuildBatch();
    if(PostJSON(body)) {
      ArrayResize(queue, 0);
      lastFlush = TimeCurrent();
    }
  }
};
