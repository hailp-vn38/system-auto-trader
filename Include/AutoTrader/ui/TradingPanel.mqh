//+------------------------------------------------------------------+
//|                                                 TradingPanel.mqh |
//|                       Reusable Panel component for trading UI    |
//+------------------------------------------------------------------+
#property copyright "AutoTrader"
#property version "1.00"

#include <ChartObjects/ChartObjectsTxtControls.mqh>

//--- Panel colors
#define PANEL_BG_COLOR clrWhite
#define PANEL_BORDER_COLOR clrDarkGray
#define HEADER_BG_COLOR clrDodgerBlue
#define HEADER_TEXT_COLOR clrWhite
#define ROW_BG_COLOR clrWhiteSmoke
#define TEXT_COLOR clrBlack
#define LOG_BG_COLOR clrGhostWhite
#define LOG_TEXT_COLOR clrDarkSlateGray

//+------------------------------------------------------------------+
//| Struct cho một row label-value                                   |
//+------------------------------------------------------------------+
struct PanelRow {
    string label;
    string value;
};

//+------------------------------------------------------------------+
//| TradingPanel class                                               |
//+------------------------------------------------------------------+
class TradingPanel {
  private:
    // Panel properties
    string m_title;
    int m_x;
    int m_y;
    int m_width;
    ENUM_BASE_CORNER m_corner;

    // UI objects
    CChartObjectRectLabel m_background;
    CChartObjectLabel m_headerLabel;
    CChartObjectRectLabel m_headerBg;
    CChartObjectButton m_collapseButton;

    // State
    bool m_isCollapsed;

    // Info row objects
    CChartObjectLabel m_symbolLabel;
    CChartObjectLabel m_symbolValue;
    CChartObjectLabel m_tfLabel;
    CChartObjectLabel m_tfValue;
    CChartObjectLabel m_magicLabel;
    CChartObjectLabel m_magicValue;

    // Dynamic rows
    PanelRow m_rows[];
    CChartObjectLabel m_rowLabels[];
    CChartObjectLabel m_rowValues[];

    // Text area
    string m_textContent;
    CChartObjectLabel m_textLabel;

    // Log stack
    string m_logs[];
    CChartObjectLabel m_logLabels[];
    int m_maxLogs;

    // Layout
    int m_currentY;
    int m_rowHeight;
    int m_padding;
    int m_fontSize;

  public:
    //--- Constructor
    TradingPanel(string title, int x, int y, int width = 350,
                 ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER) {
        m_title       = title;
        m_x           = x;
        m_y           = y;
        m_width       = width;
        m_corner      = corner;
        m_currentY    = 0;
        m_rowHeight   = 25;
        m_padding     = 10;
        m_fontSize    = 9;
        m_maxLogs     = 10;
        m_textContent = "";
        m_isCollapsed = false;
    }

    //--- Destructor
    ~TradingPanel() { Destroy(); }

    //--- Khởi tạo panel
    bool Create(string symbol = "", string timeframe = "", int magic = 0) {
        string prefix = "TradingPanel_" + m_title + "_";

        // Background
        m_background.Create(0, prefix + "BG", 0, m_x, m_y, m_width, 100);
        m_background.BackColor(PANEL_BG_COLOR);
        m_background.BorderType(BORDER_FLAT);
        m_background.Color(PANEL_BORDER_COLOR);
        m_background.Corner(m_corner);
        m_background.Selectable(false); // Không cho phép di chuyển
        m_background.Z_Order(0);        // Layer dưới cùng

        // Fill properties - Đảm bảo background được fill và nằm trên nến
        ObjectSetInteger(0, prefix + "BG", OBJPROP_FILL, true);
        ObjectSetInteger(0, prefix + "BG", OBJPROP_BACK, false); // Foreground - che nến

        m_currentY = 0;

        // Header
        CreateHeader(prefix);
        m_currentY += m_rowHeight + 5;

        // Info row (Symbol, TF, Magic)
        if(symbol != "" || timeframe != "" || magic != 0) {
            CreateInfoRow(prefix, symbol, timeframe, magic);
            m_currentY += m_rowHeight + 5;
        }

        // Update background height
        UpdateBackgroundHeight();

        return true;
    }

    //--- Thêm text content
    void AddText(string text) {
        m_textContent = text;
        string prefix = "TradingPanel_" + m_title + "_";

        if(m_textLabel.Name() == "") {
            m_textLabel.Create(0, prefix + "Text", 0, m_x + m_padding,
                               m_y + m_currentY + m_padding);
        }

        m_textLabel.Description(text);
        m_textLabel.Color(TEXT_COLOR);
        m_textLabel.FontSize(m_fontSize);
        m_textLabel.Corner(m_corner);

        m_currentY += m_rowHeight;
        UpdateBackgroundHeight();
    }

    //--- Thêm row với label và value
    void AddRow(string label, string value) {
        int size = ArraySize(m_rows);
        ArrayResize(m_rows, size + 1);
        ArrayResize(m_rowLabels, size + 1);
        ArrayResize(m_rowValues, size + 1);

        m_rows[size].label = label;
        m_rows[size].value = value;

        string prefix      = "TradingPanel_" + m_title + "_Row_" + IntegerToString(size) + "_";

        // Label
        m_rowLabels[size].Create(0, prefix + "Label", 0, m_x + m_padding, m_y + m_currentY + 5);
        m_rowLabels[size].Description(label + ":");
        m_rowLabels[size].Color(TEXT_COLOR);
        m_rowLabels[size].FontSize(m_fontSize);
        m_rowLabels[size].Corner(m_corner);

        // Value
        m_rowValues[size].Create(0, prefix + "Value", 0, m_x + m_width - m_padding - 100,
                                 m_y + m_currentY + 5);
        m_rowValues[size].Description(value);
        m_rowValues[size].Color(clrDarkBlue);
        m_rowValues[size].FontSize(m_fontSize);
        m_rowValues[size].Corner(m_corner);

        m_currentY += m_rowHeight;
        UpdateBackgroundHeight();
    }

    //--- Update row value
    void UpdateRow(string label, string value) {
        for(int i = 0; i < ArraySize(m_rows); i++) {
            if(m_rows[i].label == label) {
                m_rows[i].value = value;
                m_rowValues[i].Description(value);
                return;
            }
        }
    }

    //--- Thêm log vào cuối (chronological order)
    void AddLog(string logMessage) {
        string timestamp = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
        string fullLog   = timestamp + " | " + logMessage;

        int size         = ArraySize(m_logs);

        // Nếu đã đầy, xóa log đầu tiên (cũ nhất)
        if(size >= m_maxLogs) {
            // Xóa label của log đầu tiên (index 0)
            if(ArraySize(m_logLabels) > 0 && m_logLabels[0].Name() != "") {
                m_logLabels[0].Delete();
            }

            // Shift array lên (xóa phần tử đầu)
            for(int i = 0; i < size - 1; i++) { m_logs[i] = m_logs[i + 1]; }
            size = m_maxLogs - 1;
            ArrayResize(m_logs, size);
            ArrayResize(m_logLabels, size);
        }

        // Thêm log mới vào cuối
        ArrayResize(m_logs, size + 1);
        ArrayResize(m_logLabels, size + 1);
        m_logs[size] = fullLog;

        // Redraw all logs
        RedrawLogs();
    }

    //--- Clear logs
    void ClearLogs() {
        ArrayResize(m_logs, 0);
        for(int i = 0; i < ArraySize(m_logLabels); i++) { m_logLabels[i].Delete(); }
        ArrayResize(m_logLabels, 0);
        UpdateBackgroundHeight();
    }

    //--- Set max logs
    void SetMaxLogs(int maxLogs) { m_maxLogs = (maxLogs > 0) ? maxLogs : 10; }

    //--- Toggle collapse/expand
    void ToggleCollapse() {
        m_isCollapsed = !m_isCollapsed;
        UpdateCollapseState();
    }

    //--- Get collapse button name (for event handling)
    string GetCollapseButtonName() { return "TradingPanel_" + m_title + "_CollapseBtn"; }

    //--- Check if collapsed
    bool IsCollapsed() { return m_isCollapsed; }

    //--- Update info row
    void UpdateInfo(string symbol, string timeframe, int magic) {
        if(m_symbolValue.Name() != "") m_symbolValue.Description(symbol);
        if(m_tfValue.Name() != "") m_tfValue.Description(timeframe);
        if(m_magicValue.Name() != "") m_magicValue.Description(IntegerToString(magic));
    }

    //--- Destroy panel
    void Destroy() {
        m_background.Delete();
        m_headerLabel.Delete();
        m_headerBg.Delete();
        m_collapseButton.Delete();
        m_symbolLabel.Delete();
        m_symbolValue.Delete();
        m_tfLabel.Delete();
        m_tfValue.Delete();
        m_magicLabel.Delete();
        m_magicValue.Delete();
        m_textLabel.Delete();

        for(int i = 0; i < ArraySize(m_rowLabels); i++) {
            m_rowLabels[i].Delete();
            m_rowValues[i].Delete();
        }

        for(int i = 0; i < ArraySize(m_logLabels); i++) { m_logLabels[i].Delete(); }
    }

  private:
    //--- Tạo header
    void CreateHeader(string prefix) {
        // Header background
        m_headerBg.Create(0, prefix + "HeaderBg", 0, m_x + 1, m_y + 1, m_width - 2, m_rowHeight);
        m_headerBg.BackColor(HEADER_BG_COLOR);
        m_headerBg.BorderType(BORDER_FLAT);
        m_headerBg.Corner(m_corner);
        m_headerBg.Selectable(false);
        m_headerBg.Z_Order(1);

        // Fill properties cho header
        ObjectSetInteger(0, prefix + "HeaderBg", OBJPROP_FILL, true);
        ObjectSetInteger(0, prefix + "HeaderBg", OBJPROP_BACK, false); // Foreground

        // Header label - căn giữa
        int centerX = m_x + m_width / 2;
        int centerY = m_y + m_rowHeight / 2 - 1;

        m_headerLabel.Create(0, prefix + "Header", 0, centerX, centerY);
        m_headerLabel.Description(m_title);
        m_headerLabel.Color(HEADER_TEXT_COLOR);
        m_headerLabel.FontSize(m_fontSize + 1);
        m_headerLabel.Anchor(ANCHOR_CENTER);
        m_headerLabel.Corner(m_corner);

        // Collapse button - góc phải header
        int btnSize = 18;
        int btnX    = m_x + m_width - btnSize - 5;
        int btnY    = m_y + (m_rowHeight - btnSize) / 2 + 1;

        m_collapseButton.Create(0, prefix + "CollapseBtn", 0, btnX, btnY, btnSize, btnSize);
        m_collapseButton.Description("−"); // Minus sign
        m_collapseButton.FontSize(10);
        m_collapseButton.Color(clrWhite);
        m_collapseButton.BackColor(clrRoyalBlue);
        m_collapseButton.BorderColor(clrWhite);
        m_collapseButton.Corner(m_corner);
        m_collapseButton.Selectable(false); // Không cho phép di chuyển
        m_collapseButton.Z_Order(1);        // Đưa lên trên cùng
    }

    //--- Tạo info row
    void CreateInfoRow(string prefix, string symbol, string timeframe, int magic) {
        int colWidth = (m_width - 4 * m_padding) / 3;
        int y        = m_y + m_currentY;
        int labelGap = 12; // Gap giữa label và value

        // Symbol
        if(symbol != "") {
            m_symbolLabel.Create(0, prefix + "SymbolLabel", 0, m_x + m_padding, y + 5);
            m_symbolLabel.Description("Symbol:");
            m_symbolLabel.Color(TEXT_COLOR);
            m_symbolLabel.FontSize(m_fontSize - 1);
            m_symbolLabel.Corner(m_corner);

            m_symbolValue.Create(0, prefix + "SymbolValue", 0, m_x + m_padding, y + 5 + labelGap);
            m_symbolValue.Description(symbol);
            m_symbolValue.Color(clrDarkBlue);
            m_symbolValue.FontSize(m_fontSize);
            m_symbolValue.Corner(m_corner);
        }

        // Timeframe
        if(timeframe != "") {
            m_tfLabel.Create(0, prefix + "TFLabel", 0, m_x + m_padding + colWidth, y + 5);
            m_tfLabel.Description("TF:");
            m_tfLabel.Color(TEXT_COLOR);
            m_tfLabel.FontSize(m_fontSize - 1);
            m_tfLabel.Corner(m_corner);

            m_tfValue.Create(0, prefix + "TFValue", 0, m_x + m_padding + colWidth,
                             y + 5 + labelGap);
            m_tfValue.Description(timeframe);
            m_tfValue.Color(clrDarkBlue);
            m_tfValue.FontSize(m_fontSize);
            m_tfValue.Corner(m_corner);
        }

        // Magic
        if(magic != 0) {
            m_magicLabel.Create(0, prefix + "MagicLabel", 0, m_x + m_padding + 2 * colWidth, y + 5);
            m_magicLabel.Description("Magic:");
            m_magicLabel.Color(TEXT_COLOR);
            m_magicLabel.FontSize(m_fontSize - 1);
            m_magicLabel.Corner(m_corner);

            m_magicValue.Create(0, prefix + "MagicValue", 0, m_x + m_padding + 2 * colWidth,
                                y + 5 + labelGap);
            m_magicValue.Description(IntegerToString(magic));
            m_magicValue.Color(clrDarkBlue);
            m_magicValue.FontSize(m_fontSize);
            m_magicValue.Corner(m_corner);
        }
    }

    //--- Redraw logs
    void RedrawLogs() {
        // Clear old labels
        for(int i = 0; i < ArraySize(m_logLabels); i++) { m_logLabels[i].Delete(); }

        // Store current Y before logs
        int logsStartY = m_currentY;

        // Recalculate currentY (không tính logs)
        m_currentY = m_rowHeight + 5;                                 // Header
        if(m_symbolValue.Name() != "") m_currentY += m_rowHeight + 5; // Info row
        if(m_textContent != "") m_currentY += m_rowHeight;            // Text
        m_currentY += ArraySize(m_rows) * m_rowHeight;                // Rows

        // Draw logs
        string prefix = "TradingPanel_" + m_title + "_Log_";
        ArrayResize(m_logLabels, ArraySize(m_logs));

        for(int i = 0; i < ArraySize(m_logs); i++) {
            m_logLabels[i].Create(0, prefix + IntegerToString(i), 0, m_x + m_padding,
                                  m_y + m_currentY + 5);
            m_logLabels[i].Description(m_logs[i]);
            m_logLabels[i].Color(LOG_TEXT_COLOR);
            m_logLabels[i].FontSize(m_fontSize - 1);
            m_logLabels[i].Corner(m_corner);

            m_currentY += 20; // Log height smaller than row height
        }

        UpdateBackgroundHeight();
    }

    //--- Update background height
    void UpdateBackgroundHeight() {
        int totalHeight = m_currentY + m_padding + 5;
        m_background.Y_Size(totalHeight);
    }

    //--- Update collapse state
    void UpdateCollapseState() {
        if(m_isCollapsed) {
            // Thu nhỏ - chỉ hiện header
            m_collapseButton.Description("+"); // Plus sign

            // Ẩn tất cả content
            HideContent();

            // Resize background về chỉ header
            m_background.Y_Size(m_rowHeight + 5);
        } else {
            // Mở rộng
            m_collapseButton.Description("−"); // Minus sign

            // Hiện tất cả content
            ShowContent();

            // Recalculate và update background height
            m_currentY = m_rowHeight + 5;
            if(m_symbolValue.Name() != "") m_currentY += m_rowHeight + 5;
            if(m_textContent != "") m_currentY += m_rowHeight;
            m_currentY += ArraySize(m_rows) * m_rowHeight;
            m_currentY += ArraySize(m_logs) * 20;
            UpdateBackgroundHeight();
        }
    }

    //--- Ẩn content
    void HideContent() {
        // Info row
        m_symbolLabel.Timeframes(OBJ_NO_PERIODS);
        m_symbolValue.Timeframes(OBJ_NO_PERIODS);
        m_tfLabel.Timeframes(OBJ_NO_PERIODS);
        m_tfValue.Timeframes(OBJ_NO_PERIODS);
        m_magicLabel.Timeframes(OBJ_NO_PERIODS);
        m_magicValue.Timeframes(OBJ_NO_PERIODS);

        // Text
        m_textLabel.Timeframes(OBJ_NO_PERIODS);

        // Rows
        for(int i = 0; i < ArraySize(m_rowLabels); i++) {
            m_rowLabels[i].Timeframes(OBJ_NO_PERIODS);
            m_rowValues[i].Timeframes(OBJ_NO_PERIODS);
        }

        // Logs
        for(int i = 0; i < ArraySize(m_logLabels); i++) {
            m_logLabels[i].Timeframes(OBJ_NO_PERIODS);
        }
    }

    //--- Hiện content
    void ShowContent() {
        // Info row
        m_symbolLabel.Timeframes(OBJ_ALL_PERIODS);
        m_symbolValue.Timeframes(OBJ_ALL_PERIODS);
        m_tfLabel.Timeframes(OBJ_ALL_PERIODS);
        m_tfValue.Timeframes(OBJ_ALL_PERIODS);
        m_magicLabel.Timeframes(OBJ_ALL_PERIODS);
        m_magicValue.Timeframes(OBJ_ALL_PERIODS);

        // Text
        m_textLabel.Timeframes(OBJ_ALL_PERIODS);

        // Rows
        for(int i = 0; i < ArraySize(m_rowLabels); i++) {
            m_rowLabels[i].Timeframes(OBJ_ALL_PERIODS);
            m_rowValues[i].Timeframes(OBJ_ALL_PERIODS);
        }

        // Logs
        for(int i = 0; i < ArraySize(m_logLabels); i++) {
            m_logLabels[i].Timeframes(OBJ_ALL_PERIODS);
        }
    }
};
//+------------------------------------------------------------------+
