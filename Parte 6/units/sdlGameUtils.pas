unit sdlGameUtils;

{$IFDEF PFC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  SDL2;

type

  { Forwards }

  TFPSCounter = class;

  { Events }

  TFPSCounterEvent = procedure(Sender: TFPSCounter; Counted: word) of object;


  { TFPSCounter }

  TFPSCounter = class
  strict private
    fCount     : integer;
    fLastTicks : UInt32;
    fOnNotify  : TFPSCounterEvent;
  public
    constructor Create;
    procedure Reset;
    procedure Increment;
    property Count: integer read fCount;

    property OnNotify: TFPSCounterEvent read fOnNotify write fOnNotify;
  end;



implementation


{ TFPSCounter }

constructor TFPSCounter.Create;
begin
  Reset;
end;

procedure TFPSCounter.Reset;
begin
  fCount := 0;
  fLastTicks:= SDL_GetTicks;
end;

procedure TFPSCounter.Increment;
var
  lCurrentTicks, lElapsed: UInt32;
begin
  Inc(fCount);
  lCurrentTicks := SDL_GetTicks;
  lElapsed := ( lCurrentTicks - fLastTicks );
  if ( lElapsed > 1000 ) then
  begin
    fLastTicks:= lCurrentTicks;
    if Assigned(fOnNotify) then
       fOnNotify(self, fCount);
    fCount:= 0;
  end;
end;


end.

