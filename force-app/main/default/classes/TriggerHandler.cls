/**
 * Base class for all trigger handlers.
 *
 * Usage (one trigger per object, all events):
 *   trigger AccountTrigger on Account (before insert, before update, before delete,
 *       after insert, after update, after delete, after undelete) {
 *       new AccountTriggerHandler().run();
 *   }
 *
 * Features
 *  - Routes each trigger event to an overridable method.
 *  - Recursion control: a handler can cap how many times it runs per transaction.
 *  - Bypass switches: code (TriggerHandler.bypass) and admin-controlled
 *    (Trigger_Setting__mdt.Is_Active__c = false) without a deployment.
 */
public virtual class TriggerHandler {
  @TestVisible
  private static Set<String> bypassedHandlers = new Set<String>();
  @TestVisible
  private static Map<String, Integer> runCounts = new Map<String, Integer>();

  @TestVisible
  private TriggerOperation context;
  @TestVisible
  private Boolean isTriggerExecuting;
  private Integer maxRunsPerTransaction = 5;

  public TriggerHandler() {
    this.isTriggerExecuting = Trigger.isExecuting;
    this.context = Trigger.operationType;
  }

  /** Entry point called from the trigger. */
  public void run() {
    if (!shouldRun()) {
      return;
    }
    incrementRunCount();
    switch on context {
      when BEFORE_INSERT {
        beforeInsert(Trigger.new);
      }
      when BEFORE_UPDATE {
        beforeUpdate(Trigger.new, Trigger.oldMap);
      }
      when BEFORE_DELETE {
        beforeDelete(Trigger.oldMap);
      }
      when AFTER_INSERT {
        afterInsert(Trigger.new, Trigger.newMap);
      }
      when AFTER_UPDATE {
        afterUpdate(Trigger.new, Trigger.oldMap);
      }
      when AFTER_DELETE {
        afterDelete(Trigger.oldMap);
      }
      when AFTER_UNDELETE {
        afterUndelete(Trigger.new);
      }
    }
  }

  /** Limits how many times this handler may run in a single transaction. */
  public void setMaxRunsPerTransaction(Integer max) {
    this.maxRunsPerTransaction = max;
  }

  // ---- Bypass API -------------------------------------------------------
  public static void bypass(String handlerName) {
    bypassedHandlers.add(handlerName);
  }
  public static void clearBypass(String handlerName) {
    bypassedHandlers.remove(handlerName);
  }
  public static void clearAllBypasses() {
    bypassedHandlers.clear();
  }
  public static Boolean isBypassed(String handlerName) {
    return bypassedHandlers.contains(handlerName);
  }

  // ---- Overridable event methods ----------------------------------------
  protected virtual void beforeInsert(List<SObject> newRecords) {
  }
  protected virtual void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
  }
  protected virtual void beforeDelete(Map<Id, SObject> oldMap) {
  }
  protected virtual void afterInsert(List<SObject> newRecords, Map<Id, SObject> newMap) {
  }
  protected virtual void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
  }
  protected virtual void afterDelete(Map<Id, SObject> oldMap) {
  }
  protected virtual void afterUndelete(List<SObject> newRecords) {
  }

  // ---- Internals ---------------------------------------------------------
  @TestVisible
  private String getHandlerName() {
    return String.valueOf(this).substringBefore(':');
  }

  @TestVisible
  private Boolean shouldRun() {
    if (!isTriggerExecuting || context == null) {
      throw new TriggerHandlerException('TriggerHandler.run() must be called from a trigger.');
    }
    String name = getHandlerName();
    if (isBypassed(name) || !TriggerSettings.isActive(name)) {
      return false;
    }
    Integer count = runCounts.containsKey(name) ? runCounts.get(name) : 0;
    if (count >= maxRunsPerTransaction) {
      Logger.warn(
        name,
        'Max runs per transaction reached (' + maxRunsPerTransaction + '); skipping.'
      );
      return false;
    }
    return true;
  }

  private void incrementRunCount() {
    String name = getHandlerName();
    Integer count = runCounts.containsKey(name) ? runCounts.get(name) : 0;
    runCounts.put(name, count + 1);
  }

  public class TriggerHandlerException extends Exception {
  }
}
