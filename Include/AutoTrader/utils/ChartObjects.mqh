//+------------------------------------------------------------------+
//| Include/AutoTrader/utils/ChartObjects.mqh                        |
//| Lightweight wrapper for drawing objects on MT5 charts            |
//| Usage style matches system: class instance with dot calls        |
//+------------------------------------------------------------------+

// Helpers for unique names
namespace ChartObjUtil {
  inline string MkName(const string prefix){
    static uint _ctr = 0;
    return prefix + "_" + IntegerToString((int)TimeLocal()) + "_" + (string) (++_ctr);
  }
}

// High-level wrapper over MT5 Object* APIs
class ChartObject {
private:
  long     m_chart_id;
  string   m_name;
  int      m_type;      // OBJ_* constant
  int      m_subwin;

  bool seti(int prop, long val)  { return ObjectSetInteger(m_chart_id, m_name, prop, val); }
  bool setd(int prop, double v)  { return ObjectSetDouble (m_chart_id, m_name, prop, v);   }
  bool sets(int prop, string v)  { return ObjectSetString (m_chart_id, m_name, prop, v);   }
  bool geti(int prop, long &val) { return ObjectGetInteger(m_chart_id, m_name, prop, val); }
  bool getd(int prop, double &v) { return ObjectGetDouble (m_chart_id, m_name, prop, v);   }

public:
  ChartObject(): m_chart_id(0), m_name(""), m_type(-1), m_subwin(0) {}

  // Create generic object with two anchor points (time/price)
  bool Create(const int obj_type,
              const string name_prefix,
              const datetime t1, const double p1,
              const datetime t2=0, const double p2=0.0,
              const long chart_id=0, const int subwin=0)
  {
    m_chart_id = (chart_id==0 ? ChartID() : chart_id);
    m_name     = ChartObjUtil::MkName(name_prefix);
    m_type     = obj_type;
    m_subwin   = subwin;
    bool ok = ObjectCreate(m_chart_id, m_name, m_type, m_subwin, t1, p1, t2, p2);
    if(!ok) return false;
    // default styling
    seti(OBJPROP_COLOR, clrDodgerBlue);
    seti(OBJPROP_WIDTH, 1);
    seti(OBJPROP_BACK,  false);
    seti(OBJPROP_SELECTABLE, true);
    seti(OBJPROP_SELECTED,   false);
    return true;
  }

  // Convenience creators ------------------------------------------------
  bool Label(const string text, const int x_shift=10, const int y_shift=10,
             const long chart_id=0, const int subwin=0)
  {
    m_chart_id = (chart_id==0 ? ChartID() : chart_id);
    m_name     = ChartObjUtil::MkName("LBL");
    m_type     = OBJ_LABEL;
    m_subwin   = subwin;
    if(!ObjectCreate(m_chart_id, m_name, OBJ_LABEL, m_subwin, 0, 0.0)) return false;
    sets(OBJPROP_TEXT, text);
    seti(OBJPROP_COLOR, clrWhite);
    seti(OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    seti(OBJPROP_XDISTANCE, x_shift);
    seti(OBJPROP_YDISTANCE, y_shift);
    return true;
  }

  bool Rectangle(const string name_prefix,
                 const datetime t1, const double p1,
                 const datetime t2, const double p2,
                 const long chart_id=0, const int subwin=0)
  {
    if(!Create(OBJ_RECTANGLE, name_prefix, t1, p1, t2, p2, chart_id, subwin)) return false;
    seti(OBJPROP_BACK, true);
    seti(OBJPROP_COLOR, clrAqua);
    seti(OBJPROP_STYLE, STYLE_SOLID);
    seti(OBJPROP_FILL,  true);
    seti(OBJPROP_BACK,  true);
    seti(OBJPROP_TRANSPARENCY, 80);
    return true;
  }

  bool HLine(const string name_prefix, const double price,
             const color c=clrGold, const long chart_id=0, const int subwin=0)
  {
    if(!Create(OBJ_HLINE, name_prefix, 0, price, 0, 0.0, chart_id, subwin)) return false;
    seti(OBJPROP_COLOR, c);
    seti(OBJPROP_WIDTH, 1);
    return true;
  }

  bool VLine(const string name_prefix, const datetime t,
             const color c=clrSilver, const long chart_id=0, const int subwin=0)
  {
    if(!Create(OBJ_VLINE, name_prefix, t, 0.0, 0, 0.0, chart_id, subwin)) return false;
    seti(OBJPROP_COLOR, c);
    seti(OBJPROP_WIDTH, 1);
    return true;
  }

  bool Trend(const string name_prefix,
             const datetime t1, const double p1,
             const datetime t2, const double p2,
             const bool ray=false,
             const color c=clrDeepSkyBlue, const int width=1,
             const long chart_id=0, const int subwin=0)
  {
    if(!Create(OBJ_TREND, name_prefix, t1, p1, t2, p2, chart_id, subwin)) return false;
    seti(OBJPROP_RAY, ray);
    seti(OBJPROP_COLOR, c);
    seti(OBJPROP_WIDTH, width);
    return true;
  }

  bool Arrow(const string name_prefix, const datetime t, const double price,
             const ENUM_ARROW_CODE code=ARROW_DOWN, const color c=clrRed,
             const long chart_id=0, const int subwin=0)
  {
    if(!Create(OBJ_ARROW, name_prefix, t, price, 0, 0.0, chart_id, subwin)) return false;
    seti(OBJPROP_ARROWCODE, code);
    seti(OBJPROP_COLOR, c);
    return true;
  }

  // Mutators ------------------------------------------------------------
  bool SetColor(const color c)        { return seti(OBJPROP_COLOR, c); }
  bool SetWidth(const int w)          { return seti(OBJPROP_WIDTH, w); }
  bool SetStyle(const ENUM_LINE_STYLE s){ return seti(OBJPROP_STYLE, s); }
  bool SetBack(const bool back)       { return seti(OBJPROP_BACK, back); }
  bool SetFill(const bool f)          { return seti(OBJPROP_FILL, f); }
  bool SetZOrder(const int z)         { return seti(OBJPROP_ZORDER, z); }

  bool SetText(const string txt, const int fsize=10, const string font="Arial", const color c=clrWhite){
    if(m_type!=OBJ_TEXT && m_type!=OBJ_LABEL) return false;
    sets(OBJPROP_TEXT, txt);
    sets(OBJPROP_FONT, font);
    seti(OBJPROP_FONTSIZE, fsize);
    seti(OBJPROP_COLOR, c);
    return true;
  }

  // Move/resize anchors (time/price)
  bool SetPoint1(const datetime t, const double p){
    if(m_type==OBJ_LABEL || m_type==OBJ_VLINE || m_type==OBJ_HLINE) return false;
    return ObjectMove(m_chart_id, m_name, 0, t, p);
  }
  bool SetPoint2(const datetime t, const double p){
    if(m_type==OBJ_LABEL || m_type==OBJ_VLINE || m_type==OBJ_HLINE) return false;
    return ObjectMove(m_chart_id, m_name, 1, t, p);
  }

  // For label: shift in pixels/corner
  bool SetCorner(const ENUM_BASE_CORNER corner){ return seti(OBJPROP_CORNER, corner); }
  bool SetShift(const int x, const int y){
    bool a = seti(OBJPROP_XDISTANCE, x);
    bool b = seti(OBJPROP_YDISTANCE, y);
    return (a && b);
  }

  // Visibility: set timeframe mask (use OBJ_ALL_PERIODS for all)
  bool SetTimeframeMask(const long mask){ return seti(OBJPROP_TIMEFRAMES, mask); }

  // Existence / delete
  bool Exists() const { return ObjectFind(m_chart_id, m_name) >= 0; }
  bool Delete(){
    if(m_name=="") return false;
    bool ok = ObjectDelete(m_chart_id, m_name);
    m_name = "";
    return ok;
  }

  // Accessors
  string Name() const { return m_name; }
  int    Type() const { return m_type; }
  int    Subwindow() const { return m_subwin; }
  long   ChartId() const { return m_chart_id; }

  // Convenience: update rectangle corners
  bool UpdateRectangle(const datetime t1, const double p1,
                       const datetime t2, const double p2)
  {
    if(m_type!=OBJ_RECTANGLE) return false;
    bool a = ObjectMove(m_chart_id, m_name, 0, t1, p1);
    bool b = ObjectMove(m_chart_id, m_name, 1, t2, p2);
    return (a && b);
  }

  // Convenience: text anchored at bar time/price
  bool TextAt(const string txt, const datetime t, const double p,
              const color c=clrWhite, const int fsize=10, const string font="Arial")
  {
    if(m_type!=OBJ_TEXT){
      // recreate as text if needed
      long cid = (m_chart_id==0 ? ChartID() : m_chart_id);
      if(!ObjectCreate(cid, m_name, OBJ_TEXT, m_subwin, t, p)) return false;
      m_chart_id = cid; m_type = OBJ_TEXT;
    } else {
      if(!ObjectMove(m_chart_id, m_name, 0, t, p)) return false;
    }
    sets(OBJPROP_TEXT, txt);
    sets(OBJPROP_FONT, font);
    seti(OBJPROP_FONTSIZE, fsize);
    seti(OBJPROP_COLOR, c);
    return true;
  }
};

//-------------------------------------------------------------------------
// Optional convenience: timeframe mask helpers (use with SetTimeframeMask)
//-------------------------------------------------------------------------
namespace ChartTfMask {
  // Predefined masks (values are defined by MT5; use documented constants if available)
  // If your build doesn't expose OBJ_PERIOD_* constants, keep OBJ_ALL_PERIODS for all.
  const long ALL = OBJ_ALL_PERIODS;
}



// Example
// // Vẽ vùng range
// void DrawRange(const datetime tStart, const datetime tEnd, double hi, double lo){
//   ChartObject rect;
//   if(rect.Rectangle("RANGE", tStart, hi, tEnd, lo)){
//     rect.SetColor(clrDodgerBlue);
//     rect.SetFill(true);
//     rect.SetTimeframeMask(ChartTfMask::ALL);
//   }
// }

// // Gắn mũi tên tại thời điểm vào lệnh
// void MarkEntry(const bool isSell, const datetime t, const double px){
//   ChartObject arr;
//   arr.Arrow("ENTRY", t, px, isSell ? ARROW_DOWN : ARROW_UP, isSell ? clrTomato : clrLime);
//   arr.SetZOrder(1);
// }

