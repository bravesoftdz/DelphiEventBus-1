unit BaseTest;

interface

uses
  DUnitX.TestFramework,
  BasicObjects;

type
  [TestFixture]
  TBaseTest = class(TObject)
  private
    FChannelSubscriber: TChannelSubscriber;
    FSubscriber: TSubscriber;
  protected
    function SimpleCustomClone(const AObject: TObject): TObject;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  public
    property ChannelSubscriber: TChannelSubscriber read FChannelSubscriber write FChannelSubscriber;
    property Subscriber: TSubscriber read FSubscriber write FSubscriber;
  end;

implementation

uses
  System.SysUtils,
  EventBus;

procedure TBaseTest.Setup;
begin
  FChannelSubscriber := TChannelSubscriber.Create;
  FSubscriber := TSubscriber.Create;
end;

function TBaseTest.SimpleCustomClone(const AObject: TObject): TObject;
begin
  var LClone := TBaseEventBusEvent<TPerson>.Create;
  var LOriginal := AObject as TBaseEventBusEvent<TPerson>;
  LClone.DataOwner := LOriginal.DataOwner;
  LClone.Data := TPerson.Create;
  LClone.Data.Firstname := LOriginal.Data.Firstname + 'Custom';
  LClone.Data.Lastname  := LOriginal.Data.Lastname  + 'Custom';
  Result := LClone;
end;

procedure TBaseTest.TearDown;
begin
  GlobalEventBus.UnregisterForChannels(ChannelSubscriber);
  if Assigned(FChannelSubscriber) then FreeAndNil(FChannelSubscriber);

  GlobalEventBus.UnregisterForEvents(Subscriber);
  if Assigned(FSubscriber) then FreeAndNil(FSubscriber);
end;

end.
