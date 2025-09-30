// Include/AutoTrader/adapters/mt5/Mt5PositionsAdapter.mqh

#include <AutoTrader/domain/ports/iPositions.mqh>

class Mt5PositionsAdapter : public IPositions {
  int m_lastIndex;

public:
  Mt5PositionsAdapter() : m_lastIndex(-1) {}

  int Total() override { return PositionsTotal(); }



  bool Current(PositionInfo &out) override {
    if(m_lastIndex < 0) return false;
    out.ticket        = (ulong)PositionGetInteger(POSITION_TICKET);
    out.symbol        = PositionGetString(POSITION_SYMBOL);
    out.magic         = (long)PositionGetInteger(POSITION_MAGIC);
    out.type          = (long)PositionGetInteger(POSITION_TYPE);
    out.volume        = PositionGetDouble(POSITION_VOLUME);
    out.price_open    = PositionGetDouble(POSITION_PRICE_OPEN);
    out.price_current = PositionGetDouble(POSITION_PRICE_CURRENT);
    out.sl            = PositionGetDouble(POSITION_SL);
    out.tp            = PositionGetDouble(POSITION_TP);
    return true;
  }

  bool FirstBySymbolMagic(const string sym, const long magic, PositionInfo &out) override {
    const int n = PositionsTotal(); // :contentReference[oaicite:1]{index=1}
    for(int i = 0; i < n; i++) {
      // Cách 1: PositionGetSymbol(i) tự "select" position đó vào cache         //
      // :contentReference[oaicite:2]{index=2}
      string psym = PositionGetSymbol(i);
      if(psym == sym) {
        long pmagic = PositionGetInteger(POSITION_MAGIC); // :contentReference[oaicite:3]{index=3}
        if(pmagic == magic) {
          out.ticket = (ulong)PositionGetInteger(POSITION_TICKET); // :contentReference[oaicite:4]{index=4}
          out.symbol        = psym;
          out.magic         = pmagic;
          out.type          = (long)PositionGetInteger(POSITION_TYPE);
          out.volume        = PositionGetDouble(POSITION_VOLUME);
          out.price_open    = PositionGetDouble(POSITION_PRICE_OPEN);
          out.price_current = PositionGetDouble(POSITION_PRICE_CURRENT);
          out.sl            = PositionGetDouble(POSITION_SL);
          out.tp            = PositionGetDouble(POSITION_TP);
          return true;
        }
      }
    }
    return false;
  }

  int CountBySymbolMagic(const string sym, const long magic) override {
    const int n = PositionsTotal();
    int count   = 0;
    for(int i = 0; i < n; i++) {
      string psym = PositionGetSymbol(i); // chọn position theo index
      if(psym == sym && PositionGetInteger(POSITION_MAGIC) == magic)
        count++; // :contentReference[oaicite:5]{index=5}
    }
    return count;
  }
};
