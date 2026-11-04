@IsTest
private class AccountTriggerHandler_Test {
  @IsTest
  static void normalizesNameAndPhoneInBulk() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
      accounts.add(
        new Account(
          Name = '  Test   Clinic ' + i + ' ',
          Phone = '212.555.' + String.valueOf(1000 + i)
        )
      );
    }
    Test.startTest();
    insert accounts;
    Test.stopTest();

    for (Account acc : [SELECT Name, Phone FROM Account]) {
      Assert.isFalse(acc.Name.contains('  '), 'Name whitespace should be normalized');
      Assert.isTrue(acc.Phone.startsWith('(212) 555-'), 'Phone should be formatted: ' + acc.Phone);
    }
  }

  @IsTest
  static void deactivationClosesOpenTasks() {
    Account acc = new Account(Name = 'Synthetic Provider Group', Active__c = true);
    insert acc;
    insert new Task(Subject = 'Follow up', WhatId = acc.Id, Status = 'Not Started');

    Test.startTest();
    acc.Active__c = false;
    update acc;
    Test.stopTest();

    Assert.areEqual(0, [SELECT COUNT() FROM Task WHERE WhatId = :acc.Id AND IsClosed = FALSE]);
  }
}
