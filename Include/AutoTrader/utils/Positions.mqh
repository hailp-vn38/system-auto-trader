
namespace PositionsEx {
  int CountBySymbolMagic(string sym, long magic){
    int n = PositionsTotal(), c=0;
    for(int i=0;i<n;i++){
      if(PositionSelectByTicket(i)){
        string s = PositionGetString(POSITION_SYMBOL);
        long mg  = PositionGetInteger(POSITION_MAGIC);
        if(s==sym && mg==magic) c++;
      }
    }
    return c;
  }

  bool SelectFirstBySymbolMagic(string sym, long magic, ulong &ticketOut){
    int n = PositionsTotal();
    for(int i=0;i<n;i++){
      if(PositionSelectByTicket(i)){
        string s = PositionGetString(POSITION_SYMBOL);
        long mg  = PositionGetInteger(POSITION_MAGIC);
        if(s==sym && mg==magic){
          ticketOut = (ulong)PositionGetInteger(POSITION_TICKET);
          return true;
        }
      }
    }
    return false;
  }
}
