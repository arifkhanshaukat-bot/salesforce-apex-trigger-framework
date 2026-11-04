/**
 * Reads Trigger_Setting__mdt so admins can switch a handler off in production
 * without a deployment. A handler with no setting record is active by default.
 */
public with sharing class TriggerSettings {
  @TestVisible
  private static Map<String, Boolean> overrides = new Map<String, Boolean>();

  public static Boolean isActive(String handlerName) {
    if (overrides.containsKey(handlerName)) {
      return overrides.get(handlerName);
    }
    Trigger_Setting__mdt setting = Trigger_Setting__mdt.getInstance(handlerName);
    return setting == null || setting.Is_Active__c;
  }
}
