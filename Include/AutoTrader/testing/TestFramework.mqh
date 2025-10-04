//+------------------------------------------------------------------+
//|                                                TestFramework.mqh |
//|                                  Copyright 2025, AutoTrader Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AutoTrader Team"
#property link "https://github.com/hailp-vn38/system-auto-trader"
#property version "1.00"
#property strict

//+------------------------------------------------------------------+
//| Test Result Structure                                             |
//+------------------------------------------------------------------+
struct TestResult {
    string testName;
    bool passed;
    string message;
    datetime executionTime;
};

//+------------------------------------------------------------------+
//| Test Framework Class                                              |
//+------------------------------------------------------------------+
class TestFramework {
  private:
    TestResult m_results[];
    int m_totalTests;
    int m_passedTests;
    int m_failedTests;
    datetime m_startTime;

  public:
    TestFramework() : m_totalTests(0), m_passedTests(0), m_failedTests(0) {
        ArrayResize(m_results, 0);
        m_startTime = TimeCurrent();
    }

    ~TestFramework() { PrintReport(); }

    //+------------------------------------------------------------------+
    //| Assert Functions                                                  |
    //+------------------------------------------------------------------+
    void AssertTrue(string testName, bool condition, string message = "") {
        RecordResult(testName, condition, condition ? "PASS" : "FAIL: " + message);
    }

    void AssertFalse(string testName, bool condition, string message = "") {
        RecordResult(testName, !condition, !condition ? "PASS" : "FAIL: " + message);
    }

    void AssertEquals(string testName, double expected, double actual, double tolerance = 0.00001,
                      string message = "") {
        bool passed = MathAbs(expected - actual) <= tolerance;
        string msg
            = passed ? "PASS"
                     : StringFormat("FAIL: Expected %.5f, got %.5f. %s", expected, actual, message);
        RecordResult(testName, passed, msg);
    }

    void AssertEquals(string testName, int expected, int actual, string message = "") {
        bool passed = (expected == actual);
        string msg  = passed
                          ? "PASS"
                          : StringFormat("FAIL: Expected %d, got %d. %s", expected, actual, message);
        RecordResult(testName, passed, msg);
    }

    void AssertEquals(string testName, string expected, string actual, string message = "") {
        bool passed = (expected == actual);
        string msg
            = passed ? "PASS"
                     : StringFormat("FAIL: Expected '%s', got '%s'. %s", expected, actual, message);
        RecordResult(testName, passed, msg);
    }

    void AssertNotNull(string testName, void *pointer, string message = "") {
        bool passed = (pointer != NULL);
        string msg  = passed ? "PASS" : "FAIL: Pointer is NULL. " + message;
        RecordResult(testName, passed, msg);
    }

    void AssertNull(string testName, void *pointer, string message = "") {
        bool passed = (pointer == NULL);
        string msg  = passed ? "PASS" : "FAIL: Pointer is not NULL. " + message;
        RecordResult(testName, passed, msg);
    }

    //+------------------------------------------------------------------+
    //| Record Test Result                                                |
    //+------------------------------------------------------------------+
    void RecordResult(string testName, bool passed, string message) {
        m_totalTests++;
        if(passed) {
            m_passedTests++;
        } else {
            m_failedTests++;
        }

        int idx = ArraySize(m_results);
        ArrayResize(m_results, idx + 1);

        m_results[idx].testName      = testName;
        m_results[idx].passed        = passed;
        m_results[idx].message       = message;
        m_results[idx].executionTime = TimeCurrent();

        // Immediate feedback
        PrintFormat("[%s] %s: %s", passed ? "✓" : "✗", testName, message);
    }

    //+------------------------------------------------------------------+
    //| Print Final Report                                                |
    //+------------------------------------------------------------------+
    void PrintReport() {
        Print("=====================================");
        Print("         TEST REPORT");
        Print("=====================================");
        PrintFormat("Total Tests:  %d", m_totalTests);
        PrintFormat("Passed:       %d (%.1f%%)", m_passedTests,
                    m_totalTests > 0 ? (m_passedTests * 100.0 / m_totalTests) : 0);
        PrintFormat("Failed:       %d (%.1f%%)", m_failedTests,
                    m_totalTests > 0 ? (m_failedTests * 100.0 / m_totalTests) : 0);
        PrintFormat("Duration:     %d seconds", (int)(TimeCurrent() - m_startTime));
        Print("=====================================");

        if(m_failedTests > 0) {
            Print("Failed Tests:");
            for(int i = 0; i < ArraySize(m_results); i++) {
                if(!m_results[i].passed) {
                    PrintFormat("  - %s: %s", m_results[i].testName, m_results[i].message);
                }
            }
        }
        Print("=====================================");
    }

    //+------------------------------------------------------------------+
    //| Get Statistics                                                    |
    //+------------------------------------------------------------------+
    int GetTotalTests() const { return m_totalTests; }
    int GetPassedTests() const { return m_passedTests; }
    int GetFailedTests() const { return m_failedTests; }
    bool AllTestsPassed() const { return m_failedTests == 0 && m_totalTests > 0; }
};
