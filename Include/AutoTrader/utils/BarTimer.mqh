
//+------------------------------------------------------------------+
//| Include/AutoTrader/utils/BarTimer.mqh                            |
//| Helper class để detect new bar theo timeframe                    |
//+------------------------------------------------------------------+

#property strict

//+------------------------------------------------------------------+
//| BarTimer - Phát hiện nến mới theo timeframe                      |
//+------------------------------------------------------------------+
class BarTimer {
private:
  string m_symbol;
  ENUM_TIMEFRAMES m_timeframe;
  datetime m_lastBarTime;
  bool m_initialized;

public:
  //+------------------------------------------------------------------+
  //| Constructor                                                       |
  //+------------------------------------------------------------------+
  BarTimer(string symbol, ENUM_TIMEFRAMES timeframe)
      : m_symbol(symbol), m_timeframe(timeframe), m_lastBarTime(0), m_initialized(false) {}

  //+------------------------------------------------------------------+
  //| Kiểm tra có phải nến mới không                                   |
  //+------------------------------------------------------------------+
  bool IsNewBar() {
    datetime currentBarTime = iTime(m_symbol, m_timeframe, 0);

    // Lần đầu khởi tạo
    if(!m_initialized) {
      m_lastBarTime = currentBarTime;
      m_initialized = true;
      return false; // Không trigger lần đầu
    }

    // So sánh với nến trước
    if(currentBarTime != m_lastBarTime) {
      m_lastBarTime = currentBarTime;
      return true; // Có nến mới
    }

    return false; // Vẫn đang ở nến cũ
  }

  //+------------------------------------------------------------------+
  //| Reset timer (dùng khi thay đổi symbol/timeframe)                |
  //+------------------------------------------------------------------+
  void Reset() {
    m_lastBarTime = 0;
    m_initialized = false;
  }

  //+------------------------------------------------------------------+
  //| Lấy thời gian của nến hiện tại                                   |
  //+------------------------------------------------------------------+
  datetime GetCurrentBarTime() const { return m_lastBarTime; }

  //+------------------------------------------------------------------+
  //| Lấy số giây còn lại đến nến mới                                  |
  //+------------------------------------------------------------------+
  int GetSecondsToNextBar() const {
    if(!m_initialized) return 0;

    datetime currentTime = TimeCurrent();
    int periodSeconds    = PeriodSeconds(m_timeframe);
    datetime nextBarTime = m_lastBarTime + periodSeconds;

    return (int)(nextBarTime - currentTime);
  }

  //+------------------------------------------------------------------+
  //| Format thời gian còn lại dạng MM:SS                              |
  //+------------------------------------------------------------------+
  string GetTimeToNextBarString() const {
    int seconds = GetSecondsToNextBar();
    if(seconds < 0) return "00:00";

    int minutes = seconds / 60;
    int secs    = seconds % 60;

    return StringFormat("%02d:%02d", minutes, secs);
  }
};

//+------------------------------------------------------------------+
//| Multi-Timeframe BarTimer                                          |
//+------------------------------------------------------------------+
class MultiBarTimer {
private:
  struct TimeframeState {
    ENUM_TIMEFRAMES timeframe;
    datetime lastBarTime;
    bool initialized;
  };

  string m_symbol;
  TimeframeState m_states[];
  int m_count;

public:
  //+------------------------------------------------------------------+
  //| Constructor                                                       |
  //+------------------------------------------------------------------+
  MultiBarTimer(string symbol) : m_symbol(symbol), m_count(0) { ArrayResize(m_states, 0); }

  //+------------------------------------------------------------------+
  //| Thêm timeframe cần theo dõi                                      |
  //+------------------------------------------------------------------+
  void AddTimeframe(ENUM_TIMEFRAMES timeframe) {
    // Check duplicate
    for(int i = 0; i < m_count; i++) {
      if(m_states[i].timeframe == timeframe) return;
    }

    ArrayResize(m_states, m_count + 1);
    m_states[m_count].timeframe   = timeframe;
    m_states[m_count].lastBarTime = 0;
    m_states[m_count].initialized = false;
    m_count++;
  }

  //+------------------------------------------------------------------+
  //| Kiểm tra nến mới cho timeframe cụ thể                            |
  //+------------------------------------------------------------------+
  bool IsNewBar(ENUM_TIMEFRAMES timeframe) {
    int index = FindTimeframeIndex(timeframe);
    if(index < 0) return false;

    datetime currentBarTime = iTime(m_symbol, timeframe, 0);

    // First time
    if(!m_states[index].initialized) {
      m_states[index].lastBarTime = currentBarTime;
      m_states[index].initialized = true;
      return false;
    }

    // Compare
    if(currentBarTime != m_states[index].lastBarTime) {
      m_states[index].lastBarTime = currentBarTime;
      return true;
    }

    return false;
  }

  //+------------------------------------------------------------------+
  //| Kiểm tra nến mới cho tất cả timeframes                           |
  //+------------------------------------------------------------------+
  void CheckAllTimeframes(bool &results[]) {
    ArrayResize(results, m_count);

    for(int i = 0; i < m_count; i++) { results[i] = IsNewBar(m_states[i].timeframe); }
  }

  //+------------------------------------------------------------------+
  //| Reset tất cả                                                      |
  //+------------------------------------------------------------------+
  void ResetAll() {
    for(int i = 0; i < m_count; i++) {
      m_states[i].lastBarTime = 0;
      m_states[i].initialized = false;
    }
  }

private:
  //+------------------------------------------------------------------+
  //| Tìm index của timeframe                                          |
  //+------------------------------------------------------------------+
  int FindTimeframeIndex(ENUM_TIMEFRAMES timeframe) {
    for(int i = 0; i < m_count; i++) {
      if(m_states[i].timeframe == timeframe) return i;
    }
    return -1;
  }
};

class ThrottledTimer {
private:
  datetime m_lastExecution;
  int m_minIntervalSeconds;

public:
  ThrottledTimer(int minIntervalSeconds = 5)
      : m_lastExecution(0), m_minIntervalSeconds(minIntervalSeconds) {}

  bool ShouldExecute() {
    datetime now = TimeCurrent();

    if(now - m_lastExecution >= m_minIntervalSeconds) {
      m_lastExecution = now;
      return true;
    }

    return false;
  }
};
