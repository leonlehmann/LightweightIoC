unit IoCTests;

interface

uses
  TestFramework;
type
  ITest1 = interface
    ['{754A4635-31BB-45B4-88E8-55C6B7AEC359}']
  end;

  ITest2 = interface
    ['{754A4635-31BB-45B4-88E8-55C6B7AEC359}']
  end;

  TIoCContainerTests = class(TTestCase)
  published
    procedure TestDefault;
    procedure TestSingleton;
    procedure TestNamedSingletons;
    procedure TestSingletonInstance;
  end;

implementation

uses
  IoC;

type
  TTest1 = class(TInterfacedObject,ITest1)
  end;

  TTest11 = class(TInterfacedObject,ITest1)
  end;


  TTest2 = class(TInterfacedObject,ITest1)
  end;


{ TIoCContainerTests }

//Test if the Default container is created.
procedure TIoCContainerTests.TestDefault;
var
  t1 : ITest1;
  t2 : ITest1;
begin
  TIoC.Container.Clear;
  TIoC.Container.RegisterType<ITest1,TTest1>;

  t1 := TIoC.Container.Resolve<ITest1>;
  t2 := TIoC.Container.Resolve<ITest1>;
  Check(t1 <> nil);
  Check(t2 <> nil);
  Check(t1 <> t2);

end;


procedure TIoCContainerTests.TestNamedSingletons;
var
  t1 : ITest1;
  t2 : ITest1;
  t3 : ITest2;
  c : TIoC;
begin
  c := TIoC.Create;
  try
    c.RegisterType<ITest1,TTest1>(true,'One');
    c.RegisterType<ITest1,TTest11>(true,'OneOne');
    //test that key = type + name
    c.RegisterType<ITest2,TTest2>(true,'One');

    //name is not case sensitive
    t1 := c.Resolve<ITest1>('one');
    t2 := c.Resolve<ITest1>('oneone');
    t3 := c.Resolve<ITest2>('ONE');

    Check(t1 <> nil);
    Check(t2 <> nil);
    Check(t1 <> t2);
    Check(t3 <> nil);
  finally
    c.Free;
  end;
end;

procedure TIoCContainerTests.TestSingleton;
var
  t1 : ITest1;
  t2 : ITest1;
  c : TIoC;
begin
  c := TIoC.Create;
  try
    c.RegisterType<ITest1,TTest1>(true);
    t1 := c.Resolve<ITest1>;
    t2 := c.Resolve<ITest1>;
    Check(t1 <> nil);
    Check(t2 <> nil);
    Check(t1 = t2);
  finally
    c.Free;
  end;

end;

procedure TIoCContainerTests.TestSingletonInstance;
var
  t1 : ITest1;
  t2 : ITest1;
  c : TIoC;
begin
  c := TIoC.Create;
  try
    t1 := TTest1.Create;
    c.RegisterSingleton<ITest1>(t1);
    t2 := c.Resolve<ITest1>;
    Check(t2 <> nil);
    Check(t1 = t2);
  finally
    c.Free;
  end;
end;

initialization
  TestFramework.RegisterTest(TIoCContainerTests.Suite);

end.
