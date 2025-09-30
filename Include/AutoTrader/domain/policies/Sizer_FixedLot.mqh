
class Sizer_FixedLot : public ISizer {
  double fixedLot;
public:
  Sizer_FixedLot(double lot=0.10): fixedLot(lot) {}
  virtual double Lots(string sym, int stopPoints, double suggested, long magic) { return fixedLot; }
};
