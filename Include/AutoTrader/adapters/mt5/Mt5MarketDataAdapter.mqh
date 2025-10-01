
#include <AutoTrader/domain/ports/IMarketData.mqh>
class Mt5MarketDataAdapter : public IMarketData {
public:
  bool LastBidAsk(const string sym, double &bid, double &ask) override {
    bid = SymbolInfoDouble(sym, SYMBOL_BID);
    ask = SymbolInfoDouble(sym, SYMBOL_ASK);
    return (bid > 0 && ask > 0);
  }

  double Point(const string sym) override { return SymbolInfoDouble(sym, SYMBOL_POINT); }

  double TickSize(const string sym) override {
    return SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
  }

  bool OHLC(const string sym, ENUM_TIMEFRAMES tf, int shift, double &o, double &h, double &l,
            double &c) override {
    o = iOpen(sym, tf, shift);
    h = iHigh(sym, tf, shift);
    l = iLow(sym, tf, shift);
    c = iClose(sym, tf, shift);
    return (h > 0 && l > 0);
  }
};