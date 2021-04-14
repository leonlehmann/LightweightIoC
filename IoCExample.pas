unit IoCExample;

interface

type
  IDrivable = interface
    ['{D2E0F52A-736A-4A22-A6E6-7562F4326A18}']
    procedure Drive;
  end;

  TCar = class(TInterfacedObject, IDrivable)
  published
    procedure Drive;
  end;

  TBicycle = class(TInterfacedObject, IDrivable)
  published
    procedure Drive;
  end;

implementation

procedure TCar.Drive;
begin
  Writeln('You are driving a car!' + sLineBreak);
end;

procedure TBicycle.Drive;
begin
  Writeln('You are driving a bicycle!' + sLineBreak);
end;

end.
