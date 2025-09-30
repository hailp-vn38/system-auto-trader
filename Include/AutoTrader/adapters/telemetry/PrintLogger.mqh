
#include <AutoTrader/domain/ports/ITelemetry.mqh>
class PrintLogger : public ITelemetry {
public:
  virtual void Info(string msg) { Print("[INFO] ", msg); }
  virtual void Warn(string msg) { Print("[WARN] ", msg); }
  virtual void Error(string msg) { Print("[ERROR] ", msg); }
  virtual void Event(string name, string detail) { PrintFormat("[EVENT] %s | %s", name, detail); }
};
