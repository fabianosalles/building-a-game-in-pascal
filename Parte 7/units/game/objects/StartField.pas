unit StartField;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  SDL2,

  sdlGameTexture,
  sdlGameTypes,
  sdlEngine,
  sdlGameObjects,
  sdlParticles,

  sysutils,
  classes,
  {$IFDEF FPC}
  fgl,
  {$ELSE}
  Generics.Collections,
  {$ENDIF}
  math;

type
  TStar = class
  private
    fPosition : TVector3D;
    fRadius   : Real;
    fLife     : Real;
    fStartLife: Real;
  public
    constructor Create;
    destructor Destroy;
    property Position : TVector3D read fPosition;
    property Radius   : Real read fRadius write fRadius;
    property Life     : Real read fLife write fLife;
    property StartLife: Real read fStartLife write fStartLife;
  end;

  TStarField = class( TInterfacedObject, IUpdatable, IDrawable )
  private
    const
      STARS_COUNT = 200;
    procedure SetCount(const Value: integer);
    function GetCount: integer;
    var
      fStars : array of TStar;
    procedure RandomizeStarts;
    procedure SpawnNewStar(i: integer);
  public
    constructor Create; overload;
    constructor Create(const Count: integer); overload;
    destructor Destroy;
    procedure Update(const deltaTime : real );
    procedure Draw;
    property Count :integer read GetCount write SetCount;
  end;

implementation

{ TSatarField }

constructor TStarField.Create;
begin
  inherited;
  SetCount(STARS_COUNT);
  RandomizeStarts;
end;

constructor TStarField.Create(const Count: integer);
begin
  inherited Create;
  SetCount(Count);
  RandomizeStarts;
end;

destructor TStarField.Destroy;
var
  i : integer;
begin
  for i := 0 to Pred(Count) do
  begin
    fStars[i].Free;
    fStars[i] := nil;
  end;
end;

procedure TStarField.Draw;
const
  LayerColors: array[0..2,0..2] of byte = (
      ($99,$99,$99),
      (111,100,255),
      (6,00,171));
var
  i : integer;
  rect    : TSDL_Rect;
  renderer: PSDL_Renderer;
begin
  renderer := TEngine.GetInstance.Renderer;
  for i:=0 to Pred(Count) do begin
    rect.x := trunc( fStars[i].Position.X - fStars[i].Radius);
    rect.y := trunc( fStars[i].Position.Y - fStars[i].Radius);
    rect.w := trunc(2 * fStars[i].Radius);
    rect.h := rect.w;
    SDL_SetRenderDrawColor(renderer,
      LayerColors[Trunc(fStars[i].Position.Z), 0],
      LayerColors[Trunc(fStars[i].Position.Z), 1],
      LayerColors[Trunc(fStars[i].Position.Z), 2],
      Byte( Round(150* (fStars[i].Life / fStars[i].StartLife))));

    SDL_RenderFillRect(renderer, @rect);
  end;
end;

function TStarField.GetCount: integer;
begin
  result := Length(fStars);
end;

procedure TStarField.RandomizeStarts;
var
  i : integer;
begin
  for i := 0 to Pred(Count) do
    SpawnNewStar(i);
end;

procedure TStarField.SetCount(const Value: integer);
var
  i, x : integer;
begin
  if (Value < Count) then
  begin
    for i := Pred(Count) to 0 do
    begin
      fStars[i].Free;
      fStars[i] := nil;
    end;
    SetLength(fStars, Value);
  end
  else begin
    SetLength(fStars, Value);
    for i := 0 to Pred(Count) do
      if (fStars[i] = nil) then
          fStars[i] := TStar.Create;
  end;
end;

procedure TStarField.SpawnNewStar(i: integer);
begin
  fStars[i].Position.X := RandomRange(-25, TEngine.GetInstance.Window.w+25);
  fStars[i].Position.Y := RandomRange(-25, TEngine.GetInstance.Window.h+25);
  fStars[i].Position.Z := RandomRange(0, 2);
  fStars[i].Radius     := RandomRange(1, 4) / 2;
  fStars[i].StartLife  := RandomRange(1000, 8000);
  fStars[i].Life       := fStars[i].StartLife;
end;

procedure TStarField.Update(const deltaTime: real);
var
  i : integer;
begin
  for i := 0 to Pred(Count) do
  begin
    if fStars[i].Life > 0 then
       fStars[i].Life := fStars[i].Life - (1000*deltaTime)
    else
      SpawnNewStar(i);
  end;
end;

{ TStar }

constructor TStar.Create;
begin
  inherited;
  fPosition := TVector3D.Create;
  fRadius   := 0;
  fLife     := 1000;
end;

destructor TStar.Destroy;
begin
  fPosition.Free;
end;

end.
