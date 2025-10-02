//+------------------------------------------------------------------+
//| Include/AutoTrader/adapters/visualization/SwingChartVisualizer.mqh |
//| Chart visualization adapter for swing structures                 |
//+------------------------------------------------------------------+

#include <AutoTrader/strategies/Strat_SwingStructure.mqh>
#include <AutoTrader/strategies/swing/SwingTypes.mqh>

//+------------------------------------------------------------------+
//| @brief Visualizes swing structures on chart                      |
//| @details Draws trendlines connecting swing points at each level  |
//+------------------------------------------------------------------+
class SwingChartVisualizer {
  private:
    Strat_SwingStructure *m_strategy; ///< Reference to swing strategy
    bool m_enabled;                   ///< Enable/disable visualization

    // Colors for each level (max 10 levels)
    color m_levelColors[10];

    // Track last drawn extreme per level to avoid duplicates
    int m_lastDrawnIndex[];

    //+------------------------------------------------------------------+
    //| Generate unique object name for trendline                       |
    //+------------------------------------------------------------------+
    string GenerateLineName(const int level, const datetime time1, const datetime time2) const {
        return StringFormat("SwingLine_L%d_%s_%s", level,
                            TimeToString(time1, TIME_DATE | TIME_MINUTES),
                            TimeToString(time2, TIME_DATE | TIME_MINUTES));
    }

    //+------------------------------------------------------------------+
    //| Create trendline between two extremes                           |
    //+------------------------------------------------------------------+
    bool CreateTrendLine(const string name, const datetime time1, const double price1,
                         const datetime time2, const double price2, const color clr,
                         const ENUM_LINE_STYLE style, const int width) {
        // Delete if exists
        ObjectDelete(0, name);

        // Create new trendline
        if(!ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2)) { return false; }

        // Set properties
        ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, name, OBJPROP_STYLE, style);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
        ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

        return true;
    }

    //+------------------------------------------------------------------+
    //| Draw line connecting two consecutive extremes at a level        |
    //+------------------------------------------------------------------+
    bool DrawSwingLine(const int level, const LocalExtreme &prev, const LocalExtreme &current) {
        if(!prev.IsValid() || !current.IsValid()) return false;

        // Get color and style for this level
        color lineColor       = (level < 10) ? m_levelColors[level] : clrGray;
        ENUM_LINE_STYLE style = STYLE_SOLID;
        int width             = 1;

        // Different style for non-signal levels
        if(m_strategy != NULL && level != m_strategy.GetSignalLevel()) {
            style = STYLE_DASH;
        } else {
            width = 2; // Thicker line for signal level
        }

        string name = GenerateLineName(level, prev.timestamp, current.timestamp);
        return CreateTrendLine(name, prev.timestamp, prev.price, current.timestamp, current.price,
                               lineColor, style, width);
    }

  public:
    //+------------------------------------------------------------------+
    //| Constructor                                                       |
    //+------------------------------------------------------------------+
    SwingChartVisualizer(Strat_SwingStructure *strategy, const bool enabled = true)
        : m_strategy(strategy), m_enabled(enabled) {
        // Initialize default colors for levels
        m_levelColors[0] = clrRed;
        m_levelColors[1] = clrBlue;
        m_levelColors[2] = clrGreen;
        m_levelColors[3] = clrOrange;
        m_levelColors[4] = clrMagenta;
        m_levelColors[5] = clrDodgerBlue;
        m_levelColors[6] = clrGoldenrod;
        m_levelColors[7] = clrPurple;
        m_levelColors[8] = clrCadetBlue;
        m_levelColors[9] = clrDarkGoldenrod;

        // Initialize tracking array
        if(m_strategy != NULL) {
            ArrayResize(m_lastDrawnIndex, m_strategy.GetLevels());
            ArrayInitialize(m_lastDrawnIndex, -1);
        }
    }

    //+------------------------------------------------------------------+
    //| Destructor                                                       |
    //+------------------------------------------------------------------+
    ~SwingChartVisualizer() {
        // Optionally clear all swing lines
        // ClearAll();
    }

    //+------------------------------------------------------------------+
    //| Enable/disable visualization                                    |
    //+------------------------------------------------------------------+
    void SetEnabled(const bool enabled) { m_enabled = enabled; }
    bool IsEnabled() const { return m_enabled; }

    //+------------------------------------------------------------------+
    //| Set color for specific level                                    |
    //+------------------------------------------------------------------+
    void SetLevelColor(const int level, const color clr) {
        if(level >= 0 && level < 10) { m_levelColors[level] = clr; }
    }

    //+------------------------------------------------------------------+
    //| Update visualization for all levels                             |
    //+------------------------------------------------------------------+
    void Update() {
        if(!m_enabled || m_strategy == NULL) return;

        int levels = m_strategy.GetLevels();

        for(int level = 0; level < levels; level++) { UpdateLevel(level); }
    }

    //+------------------------------------------------------------------+
    //| Update visualization for specific level                         |
    //+------------------------------------------------------------------+
    void UpdateLevel(const int level) {
        if(!m_enabled || m_strategy == NULL) return;

        int currentSize = m_strategy.GetLevelSize(level);
        if(currentSize < 2) return; // Need at least 2 points to draw a line

        // Check if there are new extremes to draw
        if(m_lastDrawnIndex[level] >= currentSize - 1) return;

        // Draw lines for new extremes
        int startIndex = MathMax(1, m_lastDrawnIndex[level] + 1);

        for(int i = startIndex; i < currentSize; i++) {
            LocalExtreme prev = m_strategy.GetExtreme(level, i - 1);
            LocalExtreme curr = m_strategy.GetExtreme(level, i);

            if(DrawSwingLine(level, prev, curr)) { m_lastDrawnIndex[level] = i; }
        }
    }

    //+------------------------------------------------------------------+
    //| Clear all swing lines from chart                                |
    //+------------------------------------------------------------------+
    void ClearAll() {
        int total = ObjectsTotal(0, 0, OBJ_TREND);

        for(int i = total - 1; i >= 0; i--) {
            string name = ObjectName(0, i, 0, OBJ_TREND);
            if(StringFind(name, "SwingLine_") == 0) { ObjectDelete(0, name); }
        }

        // Reset tracking
        ArrayInitialize(m_lastDrawnIndex, -1);
    }

    //+------------------------------------------------------------------+
    //| Clear swing lines for specific level                            |
    //+------------------------------------------------------------------+
    void ClearLevel(const int level) {
        string prefix = StringFormat("SwingLine_L%d_", level);
        int total     = ObjectsTotal(0, 0, OBJ_TREND);

        for(int i = total - 1; i >= 0; i--) {
            string name = ObjectName(0, i, 0, OBJ_TREND);
            if(StringFind(name, prefix) == 0) { ObjectDelete(0, name); }
        }

        if(level >= 0 && level < ArraySize(m_lastDrawnIndex)) { m_lastDrawnIndex[level] = -1; }
    }

    //+------------------------------------------------------------------+
    //| Draw text label at extreme point                                |
    //+------------------------------------------------------------------+
    bool DrawExtremeLabel(const int level, const LocalExtreme &ext, const string text = "") {
        if(!m_enabled || !ext.IsValid()) return false;

        string name = StringFormat("SwingLabel_L%d_%s", level, TimeToString(ext.timestamp));

        // Delete if exists
        ObjectDelete(0, name);

        // Create text label
        if(!ObjectCreate(0, name, OBJ_TEXT, 0, ext.timestamp, ext.price)) { return false; }

        string labelText = (text != "") ? text : StringFormat("L%d", level);

        ObjectSetString(0, name, OBJPROP_TEXT, labelText);
        ObjectSetInteger(0, name, OBJPROP_COLOR, m_levelColors[level]);
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, name, OBJPROP_ANCHOR, (ext.IsHigh() ? ANCHOR_TOP : ANCHOR_BOTTOM));
        ObjectSetInteger(0, name, OBJPROP_BACK, true);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

        return true;
    }
};
