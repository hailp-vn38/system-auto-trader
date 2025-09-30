
class Risk_AllowAll : public IRisk {
public:
  virtual bool AllowTrade(string sym, long magic) { return true; }
};
