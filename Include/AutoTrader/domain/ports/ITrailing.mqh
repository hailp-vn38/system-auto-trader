
class ITrailing {
public:
  virtual bool IsReady() const                                                      = 0;
  virtual bool Manage(const string sym, const ENUM_TIMEFRAMES tf, const long magic) = 0;
};
