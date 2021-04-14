program LightweightIoC;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  TestFramework,
  TextTestRunner,
  IoCTests in 'IoCTests.pas',
  IoC in 'IoC.pas',
  IoCExample in 'IoCExample.pas';

var
  car: IDrivable;
  bicycle: IDrivable;

begin
  try
    { Run tests }
    with TextTestRunner.RunRegisteredTests do
      Free;

    // Example from unit IoCExample with IDrivable and TCar
    TIoCContainer.DefaultContainer.RegisterType<IDrivable, TCar>('car');
    TIoCContainer.DefaultContainer.RegisterType<IDrivable, TBicycle>('bicycle');

    Writeln('[Car]');
    car := TIoCContainer.DefaultContainer.Resolve<IDrivable>('car');
    car.Drive;

    Writeln('[Bicycle]');
    bicycle := TIoCContainer.DefaultContainer.Resolve<IDrivable>('bicycle');
    bicycle.Drive;

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
