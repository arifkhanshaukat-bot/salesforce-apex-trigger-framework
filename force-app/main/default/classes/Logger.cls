/**
 * Lightweight logger. Entries are published as Log_Event__e platform events so
 * they survive a rollback of the business transaction, then persisted to
 * Application_Log__c by LogEventTrigger. Support teams can read the log object
 * with a standard list view or report - no debug logs required.
 */
public without sharing class Logger {
  public enum Level {
    DEBUG,
    INFO,
    WARN,
    ERROR
  }

  @TestVisible
  private static List<Log_Event__e> published = new List<Log_Event__e>();

  public static void info(String source, String message) {
    log(Level.INFO, source, message, null);
  }
  public static void warn(String source, String message) {
    log(Level.WARN, source, message, null);
  }
  public static void error(String source, Exception ex) {
    log(Level.ERROR, source, ex.getMessage(), ex.getStackTraceString());
  }
  public static void error(String source, String message, String detail) {
    log(Level.ERROR, source, message, detail);
  }

  public static void log(Level lvl, String source, String message, String detail) {
    Log_Event__e evt = new Log_Event__e(
      Level__c = lvl.name(),
      Source__c = truncate(source, 255),
      Message__c = truncate(message, 131072),
      Detail__c = truncate(detail, 131072),
      Transaction_Id__c = Request.getCurrent().getRequestId(),
      User_Id__c = UserInfo.getUserId()
    );
    published.add(evt);
    EventBus.publish(evt);
  }

  @TestVisible
  private static String truncate(String value, Integer maxLength) {
    if (value == null || value.length() <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength);
  }
}
