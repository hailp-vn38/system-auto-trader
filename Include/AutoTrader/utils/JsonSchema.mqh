
namespace JsonSchema {
  string EventOpen(string sym,long magic,ulong ticket,int orderType,double lots,double price,double sl,double tp,datetime ts){
    return StringFormat("{\"type\":\"open\",\"ts\":%d,\"symbol\":\"%s\",\"magic\":%I64d,\"payload\":{\"ticket\":%I64u,\"orderType\":%d,\"lots\":%s,\"price\":%s,\"sl\":%s,\"tp\":%s}}",
      (int)ts, sym, magic, ticket, orderType, DoubleToString(lots,2), DoubleToString(price,_Digits), DoubleToString(sl,_Digits), DoubleToString(tp,_Digits));
  }
  string EventClose(string sym,long magic,ulong ticket,double closePrice,double profit,datetime ts,string reason){
    return StringFormat("{\"type\":\"close\",\"ts\":%d,\"symbol\":\"%s\",\"magic\":%I64d,\"payload\":{\"ticket\":%I64u,\"closePrice\":%s,\"profit\":%s,\"reason\":\"%s\"}}",
      (int)ts, sym, magic, ticket, DoubleToString(closePrice,_Digits), DoubleToString(profit,2), reason);
  }
  string EventTrailing(string sym,long magic,ulong ticket,double newSL,datetime ts){
    return StringFormat("{\"type\":\"trailing\",\"ts\":%d,\"symbol\":\"%s\",\"magic\":%I64d,\"payload\":{\"ticket\":%I64u,\"newSL\":%s}}",
      (int)ts, sym, magic, ticket, DoubleToString(newSL,_Digits));
  }
  string EventModify(string sym,long magic,ulong ticket,double newSL,double newTP,datetime ts,string reason){
    return StringFormat("{\"type\":\"modify\",\"ts\":%d,\"symbol\":\"%s\",\"magic\":%I64d,\"payload\":{\"ticket\":%I64u,\"sl\":%s,\"tp\":%s,\"reason\":\"%s\"}}",
      (int)ts, sym, magic, ticket, DoubleToString(newSL,_Digits), DoubleToString(newTP,_Digits), reason);
  }
  string EventPartial(string sym,long magic,ulong ticket,double closedLots,double closePrice,double profit,datetime ts,string reason){
    return StringFormat("{\"type\":\"partial\",\"ts\":%d,\"symbol\":\"%s\",\"magic\":%I64d,\"payload\":{\"ticket\":%I64u,\"closedLots\":%s,\"closePrice\":%s,\"profit\":%s,\"reason\":\"%s\"}}",
      (int)ts, sym, magic, ticket, DoubleToString(closedLots,2), DoubleToString(closePrice,_Digits), DoubleToString(profit,2), reason);
  }
}
