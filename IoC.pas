unit IoC;

interface

uses
  Generics.Collections,
  TypInfo,
  Rtti,
  SysUtils;

type
  TResolutionResult = (Unknown, Success, InterfaceNotRegistered, ImplNotRegistered);

  TIoCContainer = class
  private
     FComponentRegistry : TDictionary<string,TObject>;
    type
      TIoCRegistration<T : IInterface> = class
      IInterface        : PTypeInfo;
      ImplClass         : TClass;
      IsSingleton       : boolean;
      Instance          : IInterface;
    end;

  private
    class var FDefault : TIoCContainer;
    class destructor ClassDestroy;
  protected
    function GetInterfaceKey<TInterface>(const name: string = ''): string;
    function InternalResolve<TInterface: IInterface>(out AInterface: TInterface; const name: string = ''): TResolutionResult;
     procedure InternalRegisterType<TInterface : IInterface>(const singleton : boolean; const AImplementation : TClass; const name : string = '');
  public
    constructor Create;
    destructor Destroy;override;
    class function DefaultContainer : TIoCContainer;

    // Register a type
    procedure RegisterType<TInterface: IInterface; TImplementation: class>(const name : string = '');overload;
    procedure RegisterType<TInterface: IInterface; TImplementation: class>(const singleton : boolean;const name : string = '');overload;

    // Register an instance as a singleton
    procedure RegisterSingleton<TInterface :IInterface>(const instance : TInterface; const name : string = '');

    // Resolve the specified component
    function Resolve<TInterface: IInterface>(const name: string = ''): TInterface;

    // Returns true if the service is in the component registry
    function HasService<T: IInterface> : boolean;

    // Empty the container
    procedure Clear;

  end;

  EIoCException = class(Exception);
  EIoCRegistrationException = class(EIoCException);
  EIoCResolutionException = class(EIoCException);

  TClassActivator = class
  private
    class var
      FRttiContext : TRttiContext;
      class constructor Create;
  public
    class function CreateInstance(const AClass : TClass) : IInterface;
  end;


implementation


{ Registration }

procedure TIoCContainer.RegisterType<TInterface, TImplementation>(const name: string);
begin
  InternalRegisterType<TInterface>(false, TImplementation, name);
end;

procedure TIoCContainer.RegisterType<TInterface, TImplementation>(const singleton: boolean; const name: string);
begin
  InternalRegisterType<TInterface>(singleton, TImplementation, name);
end;

procedure TIoCContainer.RegisterSingleton<TInterface>(const instance: TInterface; const name: string);
var
  key   : string;
  typeInformation : PTypeInfo;
  registration  : TIoCRegistration<TInterface>;
  obj     : TObject;
begin
  typeInformation := TypeInfo(TInterface);
  key := GetInterfaceKey<TInterface>(name);

  if not FComponentRegistry.TryGetValue(key,obj) then
  begin
    registration := TIoCRegistration<TInterface>.Create;
    registration.IInterface := typeInformation;
    registration.ImplClass := nil;
    registration.IsSingleton := true;
    registration.Instance := instance;
    FComponentRegistry.Add(key,registration);
  end
  else
    raise EIoCException.Create(Format('An implementation for type %s with name %s is already registered with the container',[typeInformation.Name, name]));
end;

procedure TIoCContainer.InternalRegisterType<TInterface>(const singleton : boolean; const AImplementation : TClass; const name : string = '');
var
  key   : string;
  typeInformation : PTypeInfo;
  registration  : TIoCRegistration<TInterface>;
  obj     : TObject;
  newName : string;
  newSingleton : boolean;
begin
  newSingleton := singleton;
  newName := name;

  typeInformation := TypeInfo(TInterface);
  if newName = '' then
    key := string(typeInformation.Name)
  else
    key := typeInformation.Name + '_' + newName;
  key := LowerCase(key);

  if not FComponentRegistry.TryGetValue(key,obj) then
  begin
    registration := TIoCRegistration<TInterface>.Create;
    registration.IInterface := typeInformation;
    registration.ImplClass := AImplementation;
    registration.IsSingleton := newSingleton;
    FComponentRegistry.Add(key,registration);
  end
  else
  begin
    registration := TIoCRegistration<TInterface>(obj);
    // Raise exception if singleton has already been instantiated
    if registration.IsSingleton and (registration.Instance <> nil)  then
      raise EIoCException.Create(Format('An implementation for type %s with name %s is already registered with the container',[typeInformation.Name, newName]));
    registration.IInterface := typeInformation;
    registration.ImplClass := AImplementation;
    registration.IsSingleton := newSingleton;
    FComponentRegistry.AddOrSetValue(key,registration);
  end;
end;


{ Resolution }

function TIoCContainer.Resolve<TInterface>(const name: string = ''): TInterface;
var
  resolveResult: TResolutionResult;
  errorMsg : string;
  pInfo : PTypeInfo;
begin
  pInfo := TypeInfo(TInterface);
  resolveResult := InternalResolve<TInterface>(result, name);

  //If we don't have a resolution then throw an exception
  if (result = nil) then
  begin
    case resolveResult of
      TResolutionResult.Success : ;
      TResolutionResult.InterfaceNotRegistered : errorMsg := Format('No implementation registered for type %s', [pInfo.Name]);
      TResolutionResult.ImplNotRegistered : errorMsg := Format('The Implementation registered for type %s does not actually implement %s', [pInfo.Name, pInfo.Name]);
    else
      //All other error types are treated as unknown
      errorMsg := Format('An Unknown Error has occurred for the resolution of the interface %s %s.', [pInfo.Name, name]);
    end;

    raise EIoCResolutionException.Create(errorMsg);
  end;
end;

function TIoCContainer.InternalResolve<TInterface>(out AInterface: TInterface; const name: string): TResolutionResult;
var
  key : string;
  errorMsg : string;
  container : TDictionary<string,TObject>;
  registrationObj : TObject;
  registration  : TIoCRegistration<TInterface>;
  resolvedInterface : IInterface;
  resolvedObj : TInterface;
  singleton: Boolean;
  instanciate: Boolean;
begin
  AInterface := Default(TInterface);
  Result := TResolutionResult.Unknown;

  //Get the key for the interace we are resolving and locate the container for that key
  key := GetInterfaceKey<TInterface>(name);
  container := FComponentRegistry;

  if not container.TryGetValue(key, registrationObj) then
  begin
    result := TResolutionResult.InterfaceNotRegistered;
    Exit;
  end;

  //Get the interface registration class
  registration := TIoCRegistration<TInterface>(registrationObj);
  singleton := registration.IsSingleton;

  instanciate := true;

  if singleton then
  begin
    //If a singleton was registered with this interface then check if it's already been instanciated
    if registration.Instance <> nil then
    begin
      //Get AInterface as TInterface
      if registration.Instance.QueryInterface(GetTypeData(TypeInfo(TInterface)).Guid, AInterface) <> 0 then
      begin
        result  := TResolutionResult.ImplNotRegistered;
        Exit;
      end;

      instanciate := False;
    end;
  end;

  if instanciate then
  begin
    //If the instance hasn't been instanciated then we need to lock and instanciate
    MonitorEnter(container);
    try
      if registration.ImplClass <> nil then
      begin
        resolvedInterface := TClassActivator.CreateInstance(registration.ImplClass)
      end;

      //Get AInterface as TInterface
      if resolvedInterface.QueryInterface(GetTypeData(TypeInfo(TInterface)).Guid, resolvedObj) <> 0 then
      begin
        result  := TResolutionResult.ImplNotRegistered;
        Exit;
      end;

      AInterface := resolvedObj;

      if singleton then
      begin
        registration.Instance := resolvedObj;

        //Reset the registration to show the instance which was created.
        container.AddOrSetValue(key, registration);
      end;
    finally
      MonitorExit(container);
    end;
  end;
end;

function TIoCContainer.GetInterfaceKey<TInterface>(const name: string): string;
var
  typeInformation : PTypeInfo;
begin
  //By default the key is the interface name unless otherwise found.
  typeInformation := TypeInfo(TInterface);
  result := string(typeInformation.Name);

  if (name <> '') then
    result := result + '_' + name;

  //All keys are stored in lower case form.
  result := LowerCase(result);
end;

function TIoCContainer.HasService<T>: boolean;
begin
  result := Resolve<T> <> nil;
end;


{ Constructor, Destructor and friends... }

class destructor TIoCContainer.ClassDestroy;
begin
  if FDefault <> nil then
    FDefault.Free;
end;

procedure TIoCContainer.Clear;
begin
  FComponentRegistry.Clear;
end;

constructor TIoCContainer.Create;
begin
  FComponentRegistry := TDictionary<string,TObject>.Create;
end;

class function TIoCContainer.DefaultContainer: TIoCContainer;
begin
  if FDefault = nil then
    FDefault := TIoCContainer.Create;

  result := FDefault;
end;

destructor TIoCContainer.Destroy;
var
  o : TObject;
begin
  if FComponentRegistry <> nil then
  begin
    for o in FComponentRegistry.Values do
      if o <> nil then
        o.Free;

    FComponentRegistry.Free;
  end;
  inherited;
end;


{ TActivator }

class constructor TClassActivator.Create;
begin
  TClassActivator.FRttiContext := TRttiContext.Create;
end;

class function TClassActivator.CreateInstance(const AClass : TClass): IInterface;
var
  rttiType : TRttiType;
  method: TRttiMethod;
begin
  result := nil;

  rttiType := FRttiContext.GetType(AClass);
  if not (rttiType is TRttiInstanceType) then
    exit;

  for method in TRttiInstanceType(rttiType).GetMethods do
  begin
    if method.IsConstructor and (Length(method.GetParameters) = 0) then
    begin
      Result := method.Invoke(TRttiInstanceType(rttiType).MetaclassType, []).AsInterface;
      Break;
    end;
  end;

end;

end.
