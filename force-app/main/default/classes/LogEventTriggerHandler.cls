/** Persists Log_Event__e platform events to Application_Log__c in bulk. */
public without sharing class LogEventTriggerHandler {
  public static void persist(List<Log_Event__e> events) {
    List<Application_Log__c> logs = new List<Application_Log__c>();
    for (Log_Event__e evt : events) {
      logs.add(
        new Application_Log__c(
          Level__c = evt.Level__c,
          Source__c = evt.Source__c,
          Message__c = evt.Message__c,
          Detail__c = evt.Detail__c,
          Transaction_Id__c = evt.Transaction_Id__c,
          Logged_By__c = evt.User_Id__c
        )
      );
    }
    Database.insert(logs, false);
  }
}
