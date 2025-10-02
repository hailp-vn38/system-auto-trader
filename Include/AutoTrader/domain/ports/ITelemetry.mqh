
/**
 * @brief Interface for telemetry and logging operations.
 * This interface defines methods for logging information, warnings, errors, and events.
 */
class ITelemetry {
public:
  /**
   * @brief Logs an informational message.
   * @param msg The message to log.
   */
  virtual void Info(string msg) = 0;

  /**
   * @brief Logs a warning message.
   * @param msg The message to log.
   */
  virtual void Warn(string msg) = 0;

  /**
   * @brief Logs an error message.
   * @param msg The message to log.
   */
  virtual void Error(string msg) = 0;

  /**
   * @brief Logs a custom event with details.
   * @param name The event name.
   * @param detail Additional details about the event.
   */
  virtual void Event(string name, string detail) = 0;
};
