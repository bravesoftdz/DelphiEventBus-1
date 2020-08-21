unit BasicObjects;

interface

uses
  System.Generics.Collections,
  System.SyncObjs,
  EventBus;

type
  TPerson = class(TObject)
  private
    FChild: TPerson;
    FFirstname: string;
    FLastname: string;
    procedure set_Child(const Value: TPerson);
    procedure set_Firstname(const Value: string);
    procedure set_Lastname(const Value: string);
  public
    destructor Destroy; override;
    property Child: TPerson read FChild write set_Child;
    property Firstname: string read FFirstname write set_Firstname;
    property Lastname: string read FLastname write set_Lastname;
  end;

  TEventBusEvent = class(TBaseEventBusEvent<string>)
  end;

  TMainEvent = class(TEventBusEvent)
  end;

  TAsyncEvent = class(TEventBusEvent)
  end;

  TBackgroundEvent = class(TEventBusEvent)
  private
    FCount: Integer;
    procedure set_Count(const Value: Integer);
  public
    property Count: Integer read FCount write set_Count;
  end;

  TBaseSubscriber = class(TObject)
  private
    FChannelMsg: string;
    FEvent: TEvent;
    FEventMM: TEventMM;
    FEventMsg: string;
    FLastEvent: TEventBusEvent;
    FLastEventThreadID: Cardinal;
    procedure set_LastEvent(const Value: TEventBusEvent);
    procedure set_LastEventThreadID(const Value: Cardinal);
  public
    constructor Create;
    destructor Destroy; override;
    property Event: TEvent read FEvent;
    property EventMM: TEventMM read FEventMM write FEventMM;
    property LastChannelMsg: string read FChannelMsg write FChannelMsg;
    property LastEvent: TEventBusEvent read FLastEvent write set_LastEvent;
    property LastEventMsg: string read FEventMsg write FEventMsg;
    property LastEventThreadID: Cardinal read FLastEventThreadID write set_LastEventThreadID;
  end;

  TSubscriber = class(TBaseSubscriber)
    [Subscribe(TThreadMode.Async)]
    procedure OnSimpleAsyncEvent(AEvent: TAsyncEvent);

    [Subscribe(TThreadMode.Background)]
    procedure OnSimpleBackgroundEvent(AEvent: TBackgroundEvent);

    [Subscribe(TThreadMode.Main, 'TestContext')]
    procedure OnSimpleContextEvent(AEvent: TMainEvent);

    [Subscribe]
    procedure OnSimpleEvent(AEvent: TEventBusEvent);

    [Subscribe(TThreadMode.Main)]
    procedure OnSimpleMainEvent(AEvent: TMainEvent);
  end;

  TChannelSubscriber = class(TBaseSubscriber)
    [Channel('test_channel_async', TThreadMode.Async)]
    procedure OnSimpleAsyncChannel(AMsg: string);

    [Channel('test_channel_bkg', TThreadMode.Background)]
    procedure OnSimpleBackgroundChannel(AMsg: string);

    [Channel('test_channel')]
    procedure OnSimpleChannel(AMsg: string);

    [Channel('test_channel_main', TThreadMode.Main)]
    procedure OnSimpleMainChannel(AMsg: string);
  end;

  TSubscriberCopy = class(TBaseSubscriber)
    [Subscribe]
    procedure OnSimpleEvent(AEvent: TEventBusEvent);
  end;

  TPersonSubscriber = class(TBaseSubscriber)
  private
    FObjOwner: Boolean;
    FPerson: TPerson;
    procedure set_ObjOwner(const Value: Boolean);
    procedure set_Person(const Value: TPerson);
  public
    constructor Create;
    destructor Destroy; override;

    [Subscribe]
    procedure OnPersonEvent(AEvent: TBaseEventBusEvent<TPerson>);

    property ObjOwner: Boolean read FObjOwner write set_ObjOwner;
    property Person: TPerson read FPerson write set_Person;
  end;

  TPersonListSubscriber = class(TBaseSubscriber)
  private
    FPersonList: TObjectList<TPerson>;
    procedure set_PersonList(const Value: TObjectList<TPerson>);
  public
    [Subscribe]
    procedure OnPersonListEvent(AEvent: TBaseEventBusEvent<TObjectList<TPerson>>);

    property PersonList: TObjectList<TPerson> read FPersonList write set_PersonList;
  end;

implementation

uses
  System.Classes;

constructor TBaseSubscriber.Create;
begin
  inherited Create;
  FLastEvent := nil;
  FEvent := TEvent.Create;
  FEventMM:= TEventMM.ManualAndFreeMain;
end;

destructor TBaseSubscriber.Destroy;
begin
  GlobalEventBus.UnregisterForEvents(Self);
  GlobalEventBus.UnregisterForChannels(Self);
  if Assigned(FLastEvent) and (FEventMM <> TEventMM.Automatic) then FLastEvent.Free;
  FEvent.Free;
  inherited;
end;

procedure TBaseSubscriber.set_LastEvent(const Value: TEventBusEvent);
begin
  TMonitor.Enter(Self);
  if Assigned(FLastEvent) then FLastEvent.Free;
  FLastEvent := Value;
  TMonitor.Exit(Self);
end;

procedure TBaseSubscriber.set_LastEventThreadID(const Value: Cardinal);
begin
  TMonitor.Enter(Self);
  FLastEventThreadID := Value;
  TMonitor.Exit(Self);
end;

procedure TSubscriber.OnSimpleAsyncEvent(AEvent: TAsyncEvent);
begin
  LastEvent := AEvent;
  LastEventMsg:= AEvent.Data;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TSubscriber.OnSimpleBackgroundEvent(AEvent: TBackgroundEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TSubscriber.OnSimpleContextEvent(AEvent: TMainEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
end;

procedure TSubscriber.OnSimpleEvent(AEvent: TEventBusEvent);
begin
  LastEvent := AEvent;
  LastEventMsg:= AEvent.Data;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TSubscriber.OnSimpleMainEvent(AEvent: TMainEvent);
begin
  LastEvent := AEvent;
  LastEventMsg:= AEvent.Data;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
end;

procedure TBackgroundEvent.set_Count(const Value: integer);
begin
  FCount := Value;
end;

procedure TSubscriberCopy.OnSimpleEvent(AEvent: TEventBusEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

destructor TPerson.Destroy;
begin
  if Assigned(Child) then begin
    if Integer(Self) <> Integer(Child) then Child.Free;
  end;

  inherited;
end;

procedure TPerson.set_Child(const Value: TPerson);
begin
  FChild := Value;
end;

procedure TPerson.set_Firstname(const Value: string);
begin
  FFirstname := Value;
end;

procedure TPerson.set_Lastname(const Value: string);
begin
  FLastname := Value;
end;


constructor TPersonSubscriber.Create;
begin
  inherited Create;
  FObjOwner := True;
end;

destructor TPersonSubscriber.Destroy;
begin
  if ObjOwner and Assigned(Person) then Person.Free;
  inherited;
end;

procedure TPersonSubscriber.OnPersonEvent(AEvent: TBaseEventBusEvent<TPerson>);
begin
  try
    AEvent.DataOwner := False;
    Person := AEvent.Data;
    LastEventThreadID := TThread.CurrentThread.ThreadID;
    Event.SetEvent;
  finally
    AEvent.Free;
  end;
end;

procedure TPersonSubscriber.set_ObjOwner(const Value: Boolean);
begin
  FObjOwner := Value;
end;

procedure TPersonSubscriber.set_Person(const Value: TPerson);
begin
  FPerson := Value;
end;

procedure TPersonListSubscriber.OnPersonListEvent(AEvent: TBaseEventBusEvent<TObjectList<TPerson>>);
begin
  try
    PersonList := AEvent.Data;
    AEvent.DataOwner := False;
    LastEventThreadID := TThread.CurrentThread.ThreadID;
    Event.SetEvent;
  finally
    AEvent.Free;
  end;
end;

procedure TPersonListSubscriber.set_PersonList(const Value: TObjectList<TPerson>);
begin
  FPersonList := Value;
end;

procedure TChannelSubscriber.OnSimpleAsyncChannel(AMsg: string);
begin
  LastChannelMsg := AMsg;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TChannelSubscriber.OnSimpleBackgroundChannel(AMsg: string);
begin
  LastChannelMsg := AMsg;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TChannelSubscriber.OnSimpleChannel(AMsg: string);
begin
  LastChannelMsg := AMsg;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TChannelSubscriber.OnSimpleMainChannel(AMsg: string);
begin
  LastChannelMsg := AMsg;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

end.

