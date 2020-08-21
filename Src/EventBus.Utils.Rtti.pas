// ***************************************************************************
// Delphi MVC Framework
//
// Copyright (c) 2010-2016 Daniele Teti and the DMVCFramework Team
//
// https://github.com/danieleteti/delphimvcframework
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Updated by Wuping Xin Copyright (c) 2020
// ***************************************************************************

unit EventBus.Utils.Rtti;

interface

uses
  Data.DB,
  Generics.Collections,
  System.Rtti,
  System.SysUtils;

type
  TRttiUtils = class sealed
  public
    class var RttiContext: TRttiContext;

    class function BuildClass(
      AQualifiedName: string;
      AParams: array of TValue
    ): TObject;

    class function Clone(
      ASrcObj: TObject
    ): TObject; static;

    class procedure CopyObject(
      ASrcObj: TObject;
      ADesObj: TObject
    ); static;

    class function CreateObject(
      AQualifiedClassName: string
    ): TObject; overload; static;

    class function CreateObject(
      ARttiType: TRttiType
    ): TObject; overload; static;

    class procedure DataSetToObject(
      ADataSet: TDataSet;
      AObj: TObject
    );

    class function EqualValues(
      ASrc: TValue;
      ADest: TValue
    ): Boolean;

    class function ExistsProperty(
      AObj: TObject;
      const APropName: string;
      out AProp: TRttiProperty
    ): Boolean;

    class function FindByProperty<T: class>(
      AList: TObjectList<T>;
      APropName: string;
      APropValue: TValue
    ): T;

    class function FindType(
      AQualifiedName: string
    ): TRttiType;

    class procedure ForEachProperty(
      AClass: TClass;
      AProc: TProc<TRttiProperty>
    );

    class function GetAttribute<T: TCustomAttribute>(
      const ARttiObj: TRttiObject
    ): T; overload;

    class function GetAttribute<T: TCustomAttribute>(
      const ARttiType: TRttiType
    ): T; overload;

    class function GetField(
      AObj: TObject;
      const APropName: string
    ): TValue; overload;

    class function GetFieldType(
      AProp: TRttiProperty
    ): string;

    class function GetGUID<T>: TGUID;

    class function GetMethod(
      AObj: TObject;
      AMethodName: string
    ): TRttiMethod;

    class function GetProperty(
      AObj: TObject;
      const APropName: string
    ): TValue;

    class function GetPropertyAsString(
      AObj: TObject;
      const APropName: string
    ): string; overload;

    class function GetPropertyAsString(
      AObj: TObject;
      AProp: TRttiProperty
    ): string; overload;

    class function GetPropertyType(
      AObj: TObject;
      APropName: string
    ): string;

    class function HasAttribute<T: class>(
      AObj: TObject;
      out AAttribute: T
      ): Boolean; overload;

    class function HasAttribute<T: class>(
      ARttiMember: TRttiMember;
      out AAttribute: T
    ): Boolean; overload;

    class function HasAttribute<T: class>(
      ARttiMember: TRttiType;
      out AAttribute: T
    ): Boolean; overload;

    class function HasAttribute<T: TCustomAttribute>(
      const AObj: TRttiObject
    ): Boolean; overload;

    class function HasAttribute<T: TCustomAttribute>(
      const AObj: TRttiObject;
      out AAttribute: T
    ): Boolean; overload;

    class function HasStringValueAttribute(
      ARttiMember: TRttiMember;
      out Value: string
    ): Boolean;

    class function MethodCall(
      AObj: TObject;
      AMethodName: string;
      AParams: array of TValue;
      AExceptionOnNotFound: Boolean = True
    ): TValue;

    class procedure ObjectToDataSet(
      AObj: TObject;
      AField: TField;
      var Value: Variant
    );

    class procedure SetField(
      AObj: TObject;
      const APropName: string;
      const Value: TValue
    ); overload;

    class procedure SetProperty(
      AObj: TObject;
      const APropName: string;
      const Value: TValue
    ); overload; static;

    class function ValueAsString(
      const Value: TValue;
      const APropType: string;
      const ACustomFormat: string
    ): string;
  end;

  StringValueAttribute = class abstract(TCustomAttribute)
  private
    FValue: string;
    procedure set_Value(const Value: string);
  public
    constructor Create(Value: string);
    property Value: string read FValue write set_Value;
  end;

function FieldFor(const APropName: string): string; inline;

implementation

uses
  System.Classes,
  System.TypInfo,
  EventBus.Utils.DuckList;

class function TRttiUtils.BuildClass(AQualifiedName: string; AParams: array of TValue): TObject;
begin
  var T := FindType(AQualifiedName);
  var V := T.GetMethod('Create').Invoke(T.AsInstance.MetaclassType, AParams);
  Result := V.AsObject;
end;

class function TRttiUtils.Clone(ASrcObj: TObject): TObject;
begin
  Result := nil;
  if not Assigned(ASrcObj) then Exit;

  var LRttiType := RttiContext.GetType(ASrcObj.ClassType);
  var LCloned := CreateObject(LRttiType); // Create the clone first.

  for var LField in LRttiType.GetFields do begin
    if not LField.FieldType.IsInstance then begin
      LField.SetValue(LCloned, LField.GetValue(ASrcObj))
    end
    else begin
      var LSrcFieldValAsObj := LField.GetValue(ASrcObj).AsObject;

      if LSrcFieldValAsObj is TStream then begin
        var LSrcFieldValAsStream := TStream(LSrcFieldValAsObj);
        var LDesFieldValAsStream: TStream;
        var LSavedPosition := LSrcFieldValAsStream.Position;
        LSrcFieldValAsStream.Position := 0;

        if LField.GetValue(LCloned).IsEmpty then begin
          LDesFieldValAsStream := TMemoryStream.Create;
          LField.SetValue(LCloned, LDesFieldValAsStream);
        end
        else begin
          LDesFieldValAsStream := LField.GetValue(LCloned).AsObject as TStream;
        end;

        LDesFieldValAsStream.Position := 0;
        LDesFieldValAsStream.CopyFrom(LSrcFieldValAsStream, LSrcFieldValAsStream.Size);
        LDesFieldValAsStream.Position := LSavedPosition;
        LSrcFieldValAsStream.Position := LSavedPosition;
      end
      else begin
        if LSrcFieldValAsObj is TObjectList<TObject> then begin
          var LSrcFieldValAsCollection := TObjectList<TObject>(LSrcFieldValAsObj); // Type cast
          var LDesFieldValAsCollection: TObjectList<TObject>;

          if LField.GetValue(LCloned).IsEmpty then begin
            LDesFieldValAsCollection := TObjectList<TObject>.Create;
            LField.SetValue(LCloned, LDesFieldValAsCollection);
          end
          else begin
            LDesFieldValAsCollection := LField.GetValue(LCloned).AsObject as TObjectList<TObject>;
          end;

          // Must clear any existing collection items.
          LDesFieldValAsCollection.Clear;

          for var I := 0 to LSrcFieldValAsCollection.Count - 1 do begin
            LDesFieldValAsCollection.Add(TRttiUtils.Clone(LSrcFieldValAsCollection[I]));
          end;
        end
        else begin
          var LDesFieldValAsObj: TObject;

          if LField.GetValue(LCloned).IsEmpty then begin
            LDesFieldValAsObj := TRttiUtils.Clone(LSrcFieldValAsObj);
            LField.SetValue(LCloned, LDesFieldValAsObj);
          end
          else begin // The cloned object's constructor may have initialized the field.
            LDesFieldValAsObj := LField.GetValue(LCloned).AsObject;
            TRttiUtils.CopyObject(LSrcFieldValAsObj, LDesFieldValAsObj);
          end;

          LField.SetValue(LCloned, LDesFieldValAsObj);
        end;
      end;
    end;
  end;

  Result := LCloned;
end;

class procedure TRttiUtils.CopyObject(ASrcObj, ADesObj: TObject);
begin
  if not Assigned(ASrcObj) then begin
    raise Exception.Create('CopyObject source object null reference ');
  end;

  if not Assigned(ADesObj) then begin
    raise Exception.Create('CopyObject destination object null reference ');
  end;

  if ASrcObj.ClassType <> ADesObj.ClassType then begin
    raise Exception.Create('CopyObject source object and destination object are of different class type');
  end;

  var LRttiType := RttiContext.GetType(ASrcObj.ClassType);

  for var LField in LRttiType.GetFields do begin
    if not LField.FieldType.IsInstance then begin
      LField.SetValue(ADesObj, LField.GetValue(ASrcObj))
    end
    else begin
      var LSrcFieldValAsObj := LField.GetValue(ASrcObj).AsObject;
      if LSrcFieldValAsObj is TStream then begin
        var LSrcFieldValAsStream := TStream(LSrcFieldValAsObj);
        var LSavedPosition := LSrcFieldValAsStream.Position;
        LSrcFieldValAsStream.Position := 0;

        var LDesFieldValAsStream: TStream;
        if LField.GetValue(ASrcObj).IsEmpty then begin
          LDesFieldValAsStream := TMemoryStream.Create;
          LField.SetValue(ADesObj, LDesFieldValAsStream);
        end
        else begin
          LDesFieldValAsStream := LField.GetValue(ADesObj).AsObject as TStream;
        end;

        LDesFieldValAsStream.Position := 0;
        LDesFieldValAsStream.CopyFrom(LSrcFieldValAsStream, LSrcFieldValAsStream.Size);
        LDesFieldValAsStream.Position := LSavedPosition;
        LSrcFieldValAsStream.Position := LSavedPosition;
      end
      else begin
        if TDuckTypedList.CanBeWrappedAsList(LSrcFieldValAsObj) then begin
          var LSrcFieldValAsCollection := WrapAsList(LSrcFieldValAsObj);
          var LDesFieldValAsCollection: IWrappedList;

          if LField.GetValue(ADesObj).IsEmpty then begin
            LDesFieldValAsCollection := WrapAsList(CreateObject(LField.FieldType));
            LField.SetValue(ADesObj, LDesFieldValAsCollection.WrappedObject);
          end
          else begin
            LDesFieldValAsCollection := WrapAsList(LField.GetValue(ADesObj).AsObject);
          end;

          LDesFieldValAsCollection.Clear;
          for var I := 0 to LSrcFieldValAsCollection.Count - 1 do begin
           LDesFieldValAsCollection.Add(TRttiUtils.Clone(LSrcFieldValAsCollection.GetItem(I)));
          end;
        end
        else begin
          var LDesFieldValAsObj: TObject;
          if LField.GetValue(ADesObj).IsEmpty then begin
            LDesFieldValAsObj := TRttiUtils.Clone(LSrcFieldValAsObj);
            LField.SetValue(ADesObj, LDesFieldValAsObj);
          end
          else begin
            LDesFieldValAsObj := LField.GetValue(ADesObj).AsObject;
            TRttiUtils.CopyObject(LSrcFieldValAsObj, LDesFieldValAsObj);
          end;
        end;
      end;
    end;
  end;
end;

class function TRttiUtils.CreateObject(AQualifiedClassName: string): TObject;
begin
  var LRttiType := RttiContext.FindType(AQualifiedClassName);
  if Assigned(LRttitype) then begin
    Result := CreateObject(LRttiType)
  end
  else begin
    raise Exception.CreateFmt('Cannot find RTTI for %s. Is the type linked in the module?', [AQualifiedClassName]);
  end;
end;

class function TRttiUtils.CreateObject(ARttiType: TRttiType): TObject;
begin
  { First solution, clear and slow }
  Result := nil;
  for var LMethod in ARttiType.GetMethods do begin
    if LMethod.HasExtendedInfo and LMethod.IsConstructor then begin
      if Length(LMethod.GetParameters) = 0 then begin
        var LMetaClass := ARttiType.AsInstance.MetaclassType;
        Result := LMethod.Invoke(LMetaClass, []).AsObject;
        Break;
      end;
    end;
  end;

  if not Assigned(Result) then
    raise Exception.Create('Cannot find a proper constructor for ' + ARttiType.ToString);
  { Second solution, dirty and fast }
  // Result := TObject(ARttiType.GetMethod('Create').Invoke(ARttiType.AsInstance.MetaclassType, []).AsObject);
end;

class procedure TRttiUtils.DataSetToObject(ADataSet: TDataset; AObj: TObject);
begin
  var LRttiType := RttiContext.GetType(AObj.ClassType);
  var LProps := LRttiType.GetProperties;

  for var LProp in LProps do begin
    if not SameText(LProp.Name, 'ID') then begin
      var LField := ADataSet.FindField(LProp.Name);

      if Assigned(LField) and not LField.ReadOnly then begin
        if LField is TIntegerField then begin
          SetProperty(AObj, LProp.Name, TIntegerField(LField).Value)
        end
        else begin
          SetProperty(AObj, LProp.Name, TValue.From<Variant>(LField.Value))
        end;
      end;
    end;
  end;
end;

class function TRttiUtils.EqualValues(ASrc, ADest: TValue): Boolean;
begin
  // Really UniCodeCompareStr (Annoying VCL Name for backwards compatablity)
  Result := AnsiCompareStr(ASrc.ToString, ADest.ToString) = 0;
end;

class function TRttiUtils.ExistsProperty(AObj: TObject; const APropName: string; out AProp: TRttiProperty): Boolean;
begin
  AProp := RttiContext.GetType(AObj.ClassInfo).GetProperty(APropName);
  Result := Assigned(AProp);
end;

class function TRttiUtils.FindByProperty<T>(AList: TObjectList<T>; APropName: string; APropValue: TValue): T;
begin
  Result := nil;
  var LFound := False;

  for var LElem in AList do begin
    var LVal := GetProperty(LElem, APropName);

    case LVal.Kind of
      tkInteger:
        LFound := LVal.AsInteger = APropValue.AsInteger;
      tkFloat:
        LFound := Abs(LVal.AsExtended - APropValue.AsExtended) < 0.001;
      tkString, tkLString, tkWString, tkUString:
        LFound := LVal.AsString = APropValue.AsString;
      tkInt64:
        LFound := LVal.AsInt64 = APropValue.AsInt64;
    else
      raise Exception.Create('Property type not supported');
    end;

    if LFound then Result := LElem;
  end;
end;

class function TRttiUtils.FindType(AQualifiedName: string): TRttiType;
begin
  Result := RttiContext.FindType(AQualifiedName);
end;

class procedure TRttiUtils.ForEachProperty(AClass: TClass; AProc: TProc<TRttiProperty>);
begin
  var LRttiTy := RttiContext.GetType(AClass);
  if Assigned(LRttiTy) then begin
    var LProps := LRttiTy.GetProperties;
    for var LProp in LProps do AProc(LProp);
  end;
end;

class function TRttiUtils.GetAttribute<T>(const ARttiObj: TRttiObject): T;
begin
  Result := nil;
  var LAttrs := ARttiObj.GetAttributes;
  for var LAttr in  LAttrs do
  begin
    if LAttr.ClassType.InheritsFrom(T) then Exit(T(LAttr));
  end;
end;

class function TRttiUtils.GetAttribute<T>(const ARttiType: TRttiType): T;
begin
  Result := nil;
  var LAttrs := ARttiType.GetAttributes;
  for var LAttr in LAttrs do
  begin
    if LAttr.ClassType.InheritsFrom(T) then Exit(T(LAttr));
  end;
end;

class function TRttiUtils.GetField(AObj: TObject; const APropName: string): TValue;
begin
  var LRttiTy := RttiContext.GetType(AObj.ClassType);
  if not Assigned(LRttiTy) then begin
    raise Exception.CreateFmt('Cannot get RTTI for type [%s]', [LRttiTy.ToString]);
  end;

  var LField := LRttiTy.GetField(FieldFor(APropName));
  if Assigned(LField) then begin
    Result := LField.GetValue(AObj)
  end
  else begin
    var LProp := LRttiTy.GetProperty(APropName);
    if not Assigned(LProp) then begin
      raise Exception.CreateFmt('Cannot get RTTI for property [%s.%s]', [LRttiTy.ToString, APropName]);
    end;
    Result := LProp.GetValue(AObj);
  end;
end;

class function TRttiUtils.GetFieldType(AProp: TRttiProperty): string;
begin
  var LPropTyInfo: PTypeInfo := AProp.PropertyType.Handle;

  if LPropTyInfo.Kind in [tkString, tkWString, tkChar, tkWChar, tkLString, tkUString] then
    Result := 'string'
  else if LPropTyInfo.Kind in [tkInteger, tkInt64] then
    Result := 'integer'
  else if LPropTyInfo = TypeInfo(TDate) then
    Result := 'date'
  else if LPropTyInfo = TypeInfo(TDateTime) then
    Result := 'datetime'
  else if LPropTyInfo = TypeInfo(Currency) then
    Result := 'decimal'
  else if LPropTyInfo = TypeInfo(TTime) then
    Result := 'time'
  else if LPropTyInfo.Kind = tkFloat then
    Result := 'float'
  else if (LPropTyInfo.Kind = tkEnumeration) { and (LPropTyInfo.Name = 'Boolean') } then
    Result := 'Boolean'
  else if AProp.PropertyType.IsInstance and AProp.PropertyType.AsInstance.MetaclassType.InheritsFrom(TStream) then
    Result := 'blob'
  else
    Result := EmptyStr;
end;

class function TRttiUtils.GetGUID<T>: TGUID;
begin
  var LRttiTy := RttiContext.GetType(TypeInfo(T));
  if not (LRttiTy.TypeKind = tkInterface) then raise Exception.Create('Type is no interface');
  Result := TRttiInterfaceType(LRttiTy).GUID;
end;

class function TRttiUtils.GetMethod(AObj: TObject; AMethodName: string): TRttiMethod;
begin
  var LRttiTy := RttiContext.GetType(AObj.ClassInfo);
  Result := LRttiTy.GetMethod(AMethodName);
end;

class function TRttiUtils.GetProperty(AObj: TObject; const APropName: string): TValue;
begin
  var LRttiType := RttiContext.GetType(AObj.ClassType);
  if not Assigned(LRttiType) then raise Exception.CreateFmt('Cannot get RTTI for type [%s]', [LRttiType.ToString]);

  var LProp := LRttiType.GetProperty(APropName);
  if not Assigned(LProp) then begin
    raise Exception.CreateFmt('Cannot get RTTI for property [%s.%s]', [LRttiType.ToString, APropName]);
  end;

  if LProp.IsReadable then begin
    Result := LProp.GetValue(AObj)
  end
  else begin
    raise Exception.CreateFmt('Property is not readable [%s.%s]', [LRttiType.ToString, APropName]);
  end;
end;

class function TRttiUtils.GetPropertyAsString(AObj: TObject; const APropName: string): string;
begin
  var LProp := RttiContext.GetType(AObj.ClassType).GetProperty(APropName);
  if Assigned(LProp) then begin
    Result := GetPropertyAsString(AObj, LProp)
  end
  else begin
    Result := ''
  end;
end;

class function TRttiUtils.GetPropertyAsString(AObj: TObject; AProp: TRttiProperty): string;
begin
  if AProp.IsReadable then begin
    var LVal := AProp.GetValue(AObj);
    var LFieldTy := GetFieldType(AProp);
    var LCustomFormat: string;
    HasStringValueAttribute(AProp, LCustomFormat);
    Result := ValueAsString(LVal, LFieldTy, LCustomFormat);
  end
  else begin
    Result := '';
  end;
end;

class function TRttiUtils.GetPropertyType(AObj: TObject; APropName: string): string;
begin
  Result := GetFieldType(RttiContext.GetType(AObj.ClassInfo).GetProperty(APropName));
end;

{ TListDuckTyping }
class function TRttiUtils.HasAttribute<T>(AObj: TObject; out AAttribute: T): Boolean;
begin
  Result := HasAttribute<T>(RttiContext.GetType(AObj.ClassType), AAttribute)
end;

class function TRttiUtils.HasAttribute<T>(ARttiMember: TRttiMember; out AAttribute: T): Boolean;
begin
  AAttribute := nil;
  Result := False;
  var LAttrs := ARttiMember.GetAttributes;
  for var LAttr in LAttrs do begin
    if LAttr is T then begin
      AAttribute := T(LAttr);
      Exit(True);
    end;
  end;
end;

class function TRttiUtils.HasAttribute<T>(const AObj: TRttiObject): Boolean;
begin
  Result := Assigned(GetAttribute<T>(AObj));
end;

class function TRttiUtils.HasAttribute<T>(const AObj: TRttiObject; out AAttribute: T): Boolean;
begin
  AAttribute := GetAttribute<T>(AObj);
  Result := Assigned(AAttribute);
end;

class function TRttiUtils.HasAttribute<T>(ARttiMember: TRttiType; out AAttribute: T): Boolean;
begin
  AAttribute := nil;
  Result := False;
  var LAttrs := ARttiMember.GetAttributes;
  for var LAttr in LAttrs do begin
    if LAttr is T then begin
      AAttribute := T(LAttr);
      Exit(True);
    end;
  end;
end;

class function TRttiUtils.HasStringValueAttribute(ARttiMember: TRttiMember; out Value: string): Boolean;
var
  LAttr: StringValueAttribute;
begin
  Result := HasAttribute<StringValueAttribute>(ARttiMember, LAttr);

  if Result then begin
    Value := StringValueAttribute(LAttr).Value
  end
  else begin
    Value := '';
  end;
end;

class function TRttiUtils.MethodCall(AObj: TObject; AMethodName: string; AParams: array of TValue;
  AExceptionOnNotFound: Boolean): TValue;
begin
  Result := nil;
  var LFound := False;
  var LRttiType := RttiContext.GetType(AObj.ClassInfo);
  var LParamsLen := Length(AParams);

  for var LRttiMethod in LRttiType.GetMethods do begin
    var LMethodParamsLen := Length(LRttiMethod.GetParameters);
    if LRttiMethod.Name.Equals(AMethodName) and (LMethodParamsLen = LParamsLen) then begin
      LFound := True;
      Result := LRttiMethod.Invoke(AObj, AParams);
      Break;
    end;
  end;

  if not LFound and AExceptionOnNotFound then begin
    raise Exception.CreateFmt('Cannot find compatible mehod "%s" in the object', [AMethodName]);
  end;
end;

class procedure TRttiUtils.ObjectToDataSet(AObj: TObject; AField: TField; var Value: Variant);
begin
  Value := GetProperty(AObj, AField.FieldName).AsVariant;
end;

class procedure TRttiUtils.SetField(AObj: TObject; const APropName: string; const Value: TValue);
begin
  var LRttiType := RttiContext.GetType(AObj.ClassType);
  if not Assigned(LRttiType) then raise Exception.CreateFmt('Cannot get RTTI for type [%s]', [LRttiType.ToString]);

  var LField := LRttiType.GetField(FieldFor(APropName));
  if Assigned(LField) then begin
    LField.SetValue(AObj, Value)
  end
  else begin
    var LProp := LRttiType.GetProperty(APropName);
    if Assigned(LProp) then begin
      if LProp.IsWritable then LProp.SetValue(AObj, Value)
    end
    else begin
      raise Exception.CreateFmt('Cannot get RTTI for field or property [%s.%s]', [LRttiType.ToString, APropName]);
    end;
  end;
end;

class procedure TRttiUtils.SetProperty(AObj: TObject; const APropName: string; const Value: TValue);
begin
  var LRttiType := RttiContext.GetType(AObj.ClassType);
  if not Assigned(LRttiType) then begin
    raise Exception.CreateFmt('Cannot get RTTI for type [%s]', [LRttiType.ToString]);
  end;

  var LProp := LRttiType.GetProperty(APropName);
  if not Assigned(LProp) then begin
    raise Exception.CreateFmt('Cannot get RTTI for property [%s.%s]', [LRttiType.ToString, APropName]);
  end;

  if LProp.IsWritable then begin
    LProp.SetValue(AObj, Value)
  end
  else begin
    raise Exception.CreateFmt('Property is not writeable [%s.%s]', [LRttiType.ToString, APropName]);
  end;
end;

class function TRttiUtils.ValueAsString(const Value: TValue; const APropType, ACustomFormat: string): string;
begin
  case Value.Kind of
    tkUnknown:
      Result := '';
    tkInteger:
      Result := IntToStr(Value.AsInteger);
    tkChar:
      Result := Value.AsString;
    tkEnumeration:
      if APropType = 'Boolean' then
        Result := BoolToStr(Value.AsBoolean, True)
      else
        Result := '(enumeration)';
    tkFloat:
      begin
        if APropType = 'datetime' then begin
          if ACustomFormat = '' then
            Exit(DateTimeToStr(Value.AsExtended))
          else
            Exit(FormatDateTime(ACustomFormat, Value.AsExtended))
        end
        else begin
          if APropType = 'date' then begin
            if ACustomFormat = '' then
              Exit(DateToStr(Value.AsExtended))
            else
              Exit(FormatDateTime(ACustomFormat, Trunc(Value.AsExtended)))
          end
          else begin
            if APropType = 'time' then begin
              if ACustomFormat = '' then
                Exit(TimeToStr(Value.AsExtended))
              else
                Exit(FormatDateTime(ACustomFormat, Frac(Value.AsExtended)))
            end;
          end;
        end;

        if ACustomFormat.IsEmpty then begin
          Result := FloatToStr(Value.AsExtended)
        end
        else begin
          Result := FormatFloat(ACustomFormat, Value.AsExtended);
        end;
      end;
    tkString:
      Result := Value.AsString;
    tkSet:
      Result := '(set)';
    tkClass:
      Result := Value.AsObject.QualifiedClassName;
    tkMethod:
      Result := '(method)';
    tkWChar:
      Result := Value.AsString;
    tkLString:
      Result := Value.AsString;
    tkWString:
      Result := Value.AsString;
    tkVariant:
      Result := string(Value.AsVariant);
    tkArray:
      Result := '(array)';
    tkRecord:
      Result := '(record)';
    tkInterface:
      Result := '(interface)';
    tkInt64:
      Result := IntToStr(Value.AsInt64);
    tkDynArray:
      Result := '(array)';
    tkUString:
      Result := Value.AsString;
    tkClassRef:
      Result := '(classref)';
    tkPointer:
      Result := '(pointer)';
    tkProcedure:
      Result := '(procedure)';
  end;
end;

function FieldFor(const APropName: string): string; inline;
begin
  Result := 'F' + APropName;
end;

constructor StringValueAttribute.Create(Value: string);
begin
  inherited Create;
  FValue := Value;
end;

procedure StringValueAttribute.set_Value(const Value: string);
begin
  FValue := Value;
end;

end.
