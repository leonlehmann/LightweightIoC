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
    TIoC.Container.RegisterType<IDrivable, TCar>('car');
    TIoC.Container.RegisterType<IDrivable, TBicycle>('bicycle');

    Writeln('[Car]');
    car := TIoC.Container.Resolve<IDrivable>('car');
    car.Drive;

    Writeln('[Bicycle]');
    bicycle := TIoC.Container.Resolve<IDrivable>('bicycle');
    bicycle.Drive;

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
