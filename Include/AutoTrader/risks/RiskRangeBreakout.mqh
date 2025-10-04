#include <AutoTrader/domain/ports/IExecution.mqh>
#include <AutoTrader/domain/ports/IPositions.mqh>
#include <AutoTrader/domain/ports/IRisk.mqh>

class RiskRangeBreakout : public IRisk {
  private:
    IPositions *m_pos;
    IExecution *m_exec;
    // Nếu true, đóng vị thế hiện tại nếu có tín hiệu mới
    bool m_closeOnNewSignal;

    bool CloseOnNewSignal(const string sym, const long magic) {
        if(!m_closeOnNewSignal) return true;
        // Kiểm tra nếu có vị thế mở nào không
        if(!m_pos.HasOpenPositions(sym, magic)) return true;

        // Đóng tất cả vị thế hiện tại
        return m_exec.CloseAllBySymbolMagic(sym, magic) > 0;
    }

  public:
    RiskRangeBreakout(IPositions *positions, IExecution *execution, const bool closeOnNewSignal)
        : m_pos(positions), m_exec(execution), m_closeOnNewSignal(closeOnNewSignal) {}

    // Cho phép giao dịch nếu chưa có vị thế mở nào
    virtual bool AllowTrade(const string sym, const long magic) override {
        if(m_pos == NULL || m_exec == NULL)
            return true; // Nếu không có adapter vị thế, cho phép giao dịch
        return CloseOnNewSignal(sym, magic);
    }
};
