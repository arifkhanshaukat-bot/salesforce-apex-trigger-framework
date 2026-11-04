@IsTest
private class TriggerHandler_Test {
  private class CountingHandler extends TriggerHandler {
    public Integer calls = 0;
    protected override void beforeInsert(List<SObject> newRecords) {
      calls++;
    }
  }

  private static CountingHandler handlerIn(TriggerOperation op) {
    CountingHandler h = new CountingHandler();
    h.isTriggerExecuting = true;
    h.context = op;
    return h;
  }

  @IsTest
  static void routesToEventMethod() {
    CountingHandler h = handlerIn(TriggerOperation.BEFORE_INSERT);
    h.run();
    Assert.areEqual(1, h.calls, 'beforeInsert should run once');
  }

  @IsTest
  static void respectsCodeBypass() {
    CountingHandler h = handlerIn(TriggerOperation.BEFORE_INSERT);
    TriggerHandler.bypass(h.getHandlerName());
    h.run();
    Assert.areEqual(0, h.calls, 'Bypassed handler must not run');
    TriggerHandler.clearAllBypasses();
    Assert.isFalse(TriggerHandler.isBypassed(h.getHandlerName()));
  }

  @IsTest
  static void respectsMetadataSwitch() {
    CountingHandler h = handlerIn(TriggerOperation.BEFORE_INSERT);
    TriggerSettings.overrides.put(h.getHandlerName(), false);
    h.run();
    Assert.areEqual(0, h.calls, 'Handler switched off in settings must not run');
  }

  @IsTest
  static void capsRecursion() {
    CountingHandler h = handlerIn(TriggerOperation.BEFORE_INSERT);
    h.setMaxRunsPerTransaction(2);
    for (Integer i = 0; i < 5; i++) {
      h.run();
    }
    Assert.areEqual(2, h.calls, 'Handler should stop after the configured max runs');
  }

  @IsTest
  static void throwsOutsideTrigger() {
    CountingHandler h = new CountingHandler();
    try {
      h.run();
      Assert.fail('Expected TriggerHandlerException');
    } catch (TriggerHandler.TriggerHandlerException ex) {
      Assert.isTrue(ex.getMessage().contains('must be called from a trigger'));
    }
  }
}
