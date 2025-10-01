
class ISizer {
public:
  virtual double Lots(const string sym, const int stopPoints, const double suggested,
                      const long magic) = 0;
};
