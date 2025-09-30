
class ITelemetry {
public:
  virtual void Info(string msg)=0;
  virtual void Warn(string msg)=0;
  virtual void Error(string msg)=0;
  virtual void Event(string name, string detail)=0;
};
