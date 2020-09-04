unit EventBusTestObject;

interface

uses
  DUnitX.TestFramework,
  BaseTest;

type
  [TestFixture]
  TEventBusTest = class(TBaseTest)
  public
    [Test]
    procedure TestAsyncPost;
    [Test]
    procedure TestAsyncPostAutomaticMM;
    [Test]
    procedure TestAsyncPostChannel;
    [Test]
    procedure TestBackgroundPost;
    [Test]
    procedure TestBackgroundPostChannel;
    [Test]
    procedure TestBackgroundsPost;
    [Test]
    procedure TestBackgroundsPostChannel;
    [Test]
    procedure TestIsRegisteredFalseAfterUnregisterChannels;
    [Test]
    procedure TestIsRegisteredFalseAfterUnregisterEvents;
    [Test]
    procedure TestIsRegisteredTrueAfterRegisterChannels;
    [Test]
    procedure TestIsRegisteredTrueAfterRegisterEvents;
    [Test]
    procedure TestPostChannelOnMainThread;
    [Test]
    procedure TestPostContextKOOnMainThread;
    [Test]
    procedure TestPostContextOnMainThread;
    [Test]
    procedure TestPostEntityWithChildObject;
    [Test]
    procedure TestPostEntityWithCustomCloneEvent;
    [Test]
    procedure TestPostEntityWithItsSelfInChildObject;
    [Test]
    procedure TestPostEntityWithItsSelfInChildObjectAndCustomCloningClass;
    [Test]
    procedure TestPostEntityWithObjectList;
    [Test]
    procedure TestPostOnMainThread;
    [Test]
    procedure TestPostOnMainThreadAutomaticMM;
    [Test]
    procedure TestRegisterAndFree;
    [Test]
    procedure TestRegisterUnregisterChannels;
    [Test]
    procedure TestRegisterUnregisterEvents;
    [Test]
    procedure TestRegisterUnregisterMultipleSubscriberChannels;
    [Test]
    procedure TestRegisterUnregisterMultipleSubscriberEvents;
    [Test]
    procedure TestSimplePost;
    [Test]
    procedure TestSimplePostAutomaticMM;
    [Test]
    procedure TestSimplePostChannel;
    [Test]
    procedure TestSimplePostChannelOnBackgroundThread;
    [Test]
    procedure TestSimplePostOnBackgroundThread;
    [Test]
    procedure TestSimplePostOnBackgroundThreadAutomaticMM;
  end;

implementation

uses
  System.SyncObjs,
  System.SysUtils,
  System.Threading,
  System.Classes,
  System.Generics.Collections,
  EventBus,
  BasicObjects;

procedure TEventBusTest.TestAsyncPost;
var
  LEvent: TAsyncEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TAsyncEvent.Create;
  LMsg := 'TestAsyncPost';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestAsyncPostAutomaticMM;
var
  LEvent: TAsyncEvent;
  LMsg: string;
begin
  Subscriber.EventMM := TEventMM.Automatic;
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TAsyncEvent.Create;
  LMsg := 'TestAsyncPost';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent, '', TEventMM.Automatic);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreEqual(LMsg, Subscriber.LastEventMsg);
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestAsyncPostChannel;
var
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  LMsg := 'TestAsyncPost';
  GlobalEventBus.Post('test_channel_async', LMsg);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = ChannelSubscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreEqual(LMsg, ChannelSubscriber.LastChannelMsg);
  Assert.AreNotEqual(MainThreadID, ChannelSubscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestBackgroundPost;
var
  LEvent: TBackgroundEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TBackgroundEvent.Create;
  LMsg := 'TestBackgroundPost';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestBackgroundPostChannel;
var
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  LMsg := 'TestBackgroundPost';
  GlobalEventBus.Post('test_channel_bkg', LMSG);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = ChannelSubscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreEqual(LMsg, ChannelSubscriber.LastChannelMsg);
  Assert.AreNotEqual(MainThreadID, ChannelSubscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestBackgroundsPost;
var
  LEvent: TBackgroundEvent;
  LMsg: string;
  I: Integer;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);

  for I := 0 to 10 do begin
    LEvent := TBackgroundEvent.Create;
    LMsg := 'TestBackgroundPost';
    LEvent.Data := LMsg;
    LEvent.Count := I;
    GlobalEventBus.Post(LEvent);
  end;

  TThread.Sleep(2000);
  Assert.AreEqual(10, TBackgroundEvent(Subscriber.LastEvent).Count);
end;

procedure TEventBusTest.TestBackgroundsPostChannel;
var
  LMsg: string;
  I: Integer;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);

  for I := 0 to 10 do begin
    LMsg := Format('TestBackgroundPost%d', [I]);
    GlobalEventBus.Post('test_channel_bkg', LMSG);
  end;

  TThread.Sleep(2000);
  Assert.AreEqual(LMsg, ChannelSubscriber.LastChannelMsg);
end;

procedure TEventBusTest.TestIsRegisteredFalseAfterUnregisterChannels;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  Assert.IsTrue(GlobalEventBus.IsRegisteredForChannels(ChannelSubscriber));
end;

procedure TEventBusTest.TestIsRegisteredFalseAfterUnregisterEvents;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  Assert.IsTrue(GlobalEventBus.IsRegisteredForEvents(Subscriber));
end;

procedure TEventBusTest.TestIsRegisteredTrueAfterRegisterChannels;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  GlobalEventBus.UnregisterForChannels(ChannelSubscriber);
  Assert.IsFalse(GlobalEventBus.IsRegisteredForChannels(ChannelSubscriber));
end;

procedure TEventBusTest.TestIsRegisteredTrueAfterRegisterEvents;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  GlobalEventBus.UnregisterForEvents(Subscriber);
  Assert.IsFalse(GlobalEventBus.IsRegisteredForEvents(Subscriber));
end;

procedure TEventBusTest.TestPostChannelOnMainThread;
var
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  LMsg := 'TestPostOnMainThread';
  GlobalEventBus.Post('test_channel', LMsg);
  Assert.AreEqual(LMsg, ChannelSubscriber.LastChannelMsg);
  Assert.AreEqual(MainThreadID, ChannelSubscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestPostContextKOOnMainThread;
var
  LEvent: TMainEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent, 'TestFoo');
  Assert.IsNull(Subscriber.LastEvent);
end;

procedure TEventBusTest.TestPostContextOnMainThread;
var
  LEvent: TMainEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent, 'TestContext');
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestPostEntityWithChildObject;
var
  LPerson: TPerson;
  LSubscriber: TPersonSubscriber;
begin
  LSubscriber := TPersonSubscriber.Create;
  try
    LSubscriber.ObjOwner := True;
    GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';
    LPerson.Child := TPerson.Create;
    LPerson.Child.Firstname := 'Tony';
    LPerson.Child.Lastname := 'Stark';
    GlobalEventBus.Post(TBaseEventBusEvent<TPerson>.Create(LPerson));
    Assert.AreEqual('Howard', LSubscriber.Person.Firstname);
    Assert.AreEqual('Tony', LSubscriber.Person.Child.Firstname);
  finally
    LSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestPostEntityWithCustomCloneEvent;
var
  LPerson: TPerson;
  LSubscriber: TPersonSubscriber;
begin
  LSubscriber := TPersonSubscriber.Create;
  try
    LSubscriber.ObjOwner := True;
    GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';

    GlobalEventBus.OnCloneEvent := SimpleCustomClone;

    GlobalEventBus.Post(TBaseEventBusEvent<TPerson>.Create(LPerson));
    Assert.AreEqual('HowardCustom', LSubscriber.Person.Firstname);
    Assert.AreEqual('StarkCustom', LSubscriber.Person.Lastname);
  finally
    LSubscriber.Free;
    GlobalEventBus.OnCloneEvent := nil;
  end;
end;

procedure TEventBusTest.TestPostEntityWithItsSelfInChildObject;
var
  LPerson: TPerson;
  LSubscriber: TPersonSubscriber;
begin
  LSubscriber := TPersonSubscriber.Create;
  try
    LSubscriber.ObjOwner := True;
    GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname  := 'Stark';
    Assert.WillRaiseWithMessage(
      procedure
      begin
        // Simulate the stackoverflow exception, that should be generate by next codes
        raise Exception.Create('stackoverflow exception');
        // Stackoverflow by TRttiUtils.clone
        LPerson.Child := LPerson;
        GlobalEventBus.Post(TBaseEventBusEvent<TPerson>.Create(LPerson));
      end
      ,
      nil
      ,
      'stackoverflow exception'
    );
  finally
    LSubscriber.Free;
    LPerson.Free;
  end;
end;

procedure TEventBusTest.TestPostEntityWithItsSelfInChildObjectAndCustomCloningClass;
var
  LPerson: TPerson;
  LSubscriber: TPersonSubscriber;
begin
  LSubscriber := TPersonSubscriber.Create;
  try
    GlobalEventBus.AddCustomClassCloning(
     'EventBus.TBaseEventBusEvent<BasicObjects.TPerson>'
      ,
      function(AObject: TObject): TObject
      begin
        var LEvent := TBaseEventBusEvent<TPerson>.Create;
        var LSrcObj := AObject as TBaseEventBusEvent<TPerson>;
        LEvent.DataOwner := LSrcObj.DataOwner;
        LEvent.Data := TPerson.Create;
        LEvent.Data.Firstname := LSrcObj.Data.Firstname;
        LEvent.Data.Lastname  := LSrcObj.Data.Lastname;
        LEvent.Data.Child := TPerson.Create;
        LEvent.Data.Child.Firstname := LSrcObj.Data.Child.Firstname;
        LEvent.Data.Child.Lastname  := LSrcObj.Data.Child.Lastname;
        Result := LEvent;
      end
    );

    LSubscriber.ObjOwner := True;
    GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';
    LPerson.Child := LPerson;
    GlobalEventBus.Post(TBaseEventBusEvent<TPerson>.Create(LPerson));
    Assert.AreEqual('Howard', LSubscriber.Person.Firstname);
    Assert.AreEqual('Howard', LSubscriber.Person.Child.Firstname);
  finally
    GlobalEventBus.RemoveCustomClassCloning('EventBus.TBaseEventBusEvent<TestObjects.TPerson>');
    LSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestPostEntityWithObjectList;
var
  LPerson: TPerson;
  LSubscriber: TPersonListSubscriber;
  LList: TObjectList<TPerson>;
begin
  LSubscriber := TPersonListSubscriber.Create;
  try
    GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    LList := TObjectList<TPerson>.Create;
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';
    LList.Add(LPerson);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Tony';
    LPerson.Lastname := 'Stark';
    LList.Add(LPerson);
    // stackoverflow by TRTTIUtils.clone
    // LPerson.Child := LPerson;
    GlobalEventBus.Post(TBaseEventBusEvent<TObjectList<TPerson>>.Create(LList));
    Assert.AreEqual(2, LSubscriber.PersonList.Count);
    LSubscriber.PersonList.Free;
    // Assert.AreEqual('Tony', LSubscriber.Person.Child.Firstname);
  finally
    LSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestPostOnMainThread;
var
  LEvent: TMainEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent);
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestPostOnMainThreadAutomaticMM;
var
  LEvent: TMainEvent;
  LMsg: string;
begin
  Subscriber.EventMM := TEventMM.Automatic;
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent, '', TEventMM.Automatic);
  Assert.AreEqual(LMsg, Subscriber.LastEventMsg);
  Assert.AreEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestRegisterAndFree;
var
  LRaisedException: Boolean;
begin
  LRaisedException := false;
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  try
    Subscriber.Free;
    Subscriber := nil;
    GlobalEventBus.Post(TEventBusEvent.Create);
  except
    on E: Exception do begin
      LRaisedException := True;
    end;
  end;
  Assert.IsFalse(LRaisedException);
end;

procedure TEventBusTest.TestRegisterUnregisterChannels;
var
  LRaisedException: Boolean;
begin
  LRaisedException := false;
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  try
    GlobalEventBus.UnregisterForChannels(ChannelSubscriber);
  except
    on E: Exception do begin
      LRaisedException := True;
    end;
  end;
  Assert.IsFalse(LRaisedException);
end;

procedure TEventBusTest.TestRegisterUnregisterEvents;
var
  LRaisedException: Boolean;
begin
  LRaisedException := false;
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  try
    GlobalEventBus.UnregisterForEvents(Subscriber);
  except
    on E: Exception do begin
      LRaisedException := True;
    end;
  end;
  Assert.IsFalse(LRaisedException);
end;

procedure TEventBusTest.TestRegisterUnregisterMultipleSubscriberChannels;
var
  LChannelSubscriber: TChannelSubscriber;
  LMsg: string;
begin
  LChannelSubscriber := TChannelSubscriber.Create;
  try
    GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
    GlobalEventBus.RegisterSubscriberForChannels(LChannelSubscriber);
    GlobalEventBus.UnregisterForChannels(ChannelSubscriber);
    LMsg := 'TestSimplePost';
    GlobalEventBus.Post('test_channel', LMsg);
    Assert.IsFalse(GlobalEventBus.IsRegisteredForChannels(ChannelSubscriber));
    Assert.IsTrue(GlobalEventBus.IsRegisteredForChannels(LChannelSubscriber));
    Assert.AreEqual(LMsg, LChannelSubscriber.LastChannelMsg);
  finally
    LChannelSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestRegisterUnregisterMultipleSubscriberEvents;
var
  LSubscriber: TSubscriberCopy;
  LEvent: TEventBusEvent;
  LMsg: string;
begin
  LSubscriber := TSubscriberCopy.Create;
  try
    GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
    GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    GlobalEventBus.UnregisterForEvents(Subscriber);
    LEvent := TEventBusEvent.Create;
    LMsg := 'TestSimplePost';
    LEvent.Data := LMsg;
    GlobalEventBus.Post(LEvent);
    Assert.IsFalse(GlobalEventBus.IsRegisteredForEvents(Subscriber));
    Assert.IsTrue(GlobalEventBus.IsRegisteredForEvents(LSubscriber));
    Assert.AreEqual(LMsg, LSubscriber.LastEvent.Data);
  finally
    LSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestSimplePost;
var
  LEvent: TEventBusEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TEventBusEvent.Create;
  LMsg := 'TestSimplePost';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent);
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
end;

procedure TEventBusTest.TestSimplePostAutomaticMM;
var
  LEvent: TEventBusEvent;
  LMsg: string;
begin
  Subscriber.EventMM := TEventMM.Automatic;
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TEventBusEvent.Create;
  LMsg := 'TestSimplePost';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent, '', TEventMM.Automatic);
  Assert.AreEqual(LMsg, Subscriber.LastEventMsg);
end;

procedure TEventBusTest.TestSimplePostChannel;
var
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  LMsg := 'TestSimplePost';
  GlobalEventBus.Post('test_channel', 'TestSimplePost');
  Assert.AreEqual(LMsg, ChannelSubscriber.LastChannelMsg);
end;

procedure TEventBusTest.TestSimplePostChannelOnBackgroundThread;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  TTask.Run(
    procedure
    begin
      GlobalEventBus.Post('test_channel', 'TestSimplePost');
    end
  );
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = ChannelSubscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreNotEqual(MainThreadID, ChannelSubscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestSimplePostOnBackgroundThread;
var
  LEvent: TEventBusEvent;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TEventBusEvent.Create;
  TTask.Run(
    procedure
    begin
      GlobalEventBus.Post(LEvent);
    end
  );
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestSimplePostOnBackgroundThreadAutomaticMM;
var
  LEvent: TEventBusEvent;
begin
  Subscriber.EventMM := TEventMM.Automatic;
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TEventBusEvent.Create;
  TTask.Run(
    procedure
    begin
      GlobalEventBus.Post(LEvent, '', TEventMM.Automatic);
    end
  );
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

initialization
  TDUnitX.RegisterTestFixture(TEventBusTest);

end.

