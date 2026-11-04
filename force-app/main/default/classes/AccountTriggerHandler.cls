/**
 * Example handler showing the intended pattern: no SOQL/DML in loops,
 * field changes in before-context, related work in after-context.
 */
public with sharing class AccountTriggerHandler extends TriggerHandler {
  public AccountTriggerHandler() {
    super();
    setMaxRunsPerTransaction(2);
  }

  protected override void beforeInsert(List<SObject> newRecords) {
    normalize((List<Account>) newRecords);
  }

  protected override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
    normalize((List<Account>) newRecords);
  }

  protected override void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
    Set<Id> deactivated = new Set<Id>();
    for (Account acc : (List<Account>) newRecords) {
      Account old = (Account) oldMap.get(acc.Id);
      if (old.Active__c == true && acc.Active__c == false) {
        deactivated.add(acc.Id);
      }
    }
    if (!deactivated.isEmpty()) {
      closeOpenTasks(deactivated);
    }
  }

  @TestVisible
  private static void normalize(List<Account> accounts) {
    for (Account acc : accounts) {
      if (acc.Name != null) {
        acc.Name = acc.Name.normalizeSpace();
      }
      if (acc.Phone != null) {
        String digits = acc.Phone.replaceAll('[^0-9]', '');
        if (digits.length() == 10) {
          acc.Phone =
            '(' +
            digits.substring(0, 3) +
            ') ' +
            digits.substring(3, 6) +
            '-' +
            digits.substring(6);
        }
      }
    }
  }

  private static void closeOpenTasks(Set<Id> accountIds) {
    List<Task> openTasks = [
      SELECT Id
      FROM Task
      WHERE WhatId IN :accountIds AND IsClosed = FALSE
      WITH USER_MODE
    ];
    for (Task t : openTasks) {
      t.Status = 'Completed';
    }
    try {
      update as user openTasks;
    } catch (DmlException ex) {
      Logger.error('AccountTriggerHandler.closeOpenTasks', ex);
    }
  }
}
