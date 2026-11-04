@IsTest
private class Logger_Test {
  @IsTest
  static void publishesAndPersistsLogs() {
    Test.startTest();
    Logger.info('Logger_Test', 'hello');
    try {
      Integer x = 1 / 0;
    } catch (MathException ex) {
      Logger.error('Logger_Test', ex);
    }
    Test.stopTest(); // delivers platform events

    Assert.areEqual(2, Logger.published.size());
    List<Application_Log__c> logs = [
      SELECT Level__c, Source__c
      FROM Application_Log__c
      ORDER BY Level__c
    ];
    Assert.areEqual(2, logs.size(), 'Both events should be persisted');
    Assert.areEqual('ERROR', logs[0].Level__c);
  }

  @IsTest
  static void truncatesLongValues() {
    Assert.areEqual('abc', Logger.truncate('abcdef', 3));
    Assert.isNull(Logger.truncate(null, 3));
  }
}
