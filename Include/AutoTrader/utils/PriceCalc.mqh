
namespace PriceCalc {
  double SL(string sym, int orderType, int points){
    double pip = SymbolInfoDouble(sym, SYMBOL_POINT);
    double bid = SymbolInfoDouble(sym, SYMBOL_BID);
    double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
    return (orderType==ORDER_TYPE_BUY) ? (bid - points*pip) : (ask + points*pip);
  }
  double TP(string sym, int orderType, int points){
    double pip = SymbolInfoDouble(sym, SYMBOL_POINT);
    double bid = SymbolInfoDouble(sym, SYMBOL_BID);
    double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
    return (orderType==ORDER_TYPE_BUY) ? (bid + points*pip) : (ask - points*pip);
  }
}
