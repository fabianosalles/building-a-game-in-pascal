unit sdlParticles;

{$mode objfpc}{$H+}

interface

uses
  fgl,
  SDL2,
  sdlGameObjects;


type

  { TParticle }

  TParticle = class(TGameObject)
  private
    fLife     : real;
    fAngle    : real;
    fSpeed    : real;
    fColor    : TSDL_Color;
  strict private
    fVelocity : TPoint;
    function GetAlive: boolean;
    function GetAngleInRadians: real; inline;
    function GetVelocity: TPoint;
  public
    constructor Create(aPosition: TPoint; life, angle, speed: real);

    procedure Update(const deltaTime: real); override;

    property Life : real read fLife write fLife;
    property Angle : real read fAngle write fAngle;
    property Speed: real read fSpeed write fSpeed;
    property Color: TSDL_Color read fColor write fColor;

    property Alive: boolean read GetAlive;
    property AngleInRadians: real read GetAngleInRadians;
    property Velocity: TPoint read GetVelocity;
  end;

  TParticleList = specialize TFPGObjectList<TParticle>;

  TEmmiterKind = (
    Radial,
    Rectangular
  );


  { TEmmiter }

  TEmmiter = class(TGameObject)
  strict private
  const
    POOL_SIZE = 1024 * 4;
  var
    fParticles : TParticleList;
    fKind      : TEmmiterKind;
    fBounds    : TSDL_Rect;
  public
    constructor Create; override;
    procedure Update(const deltaTime: real); override;
  end;







implementation

{ TEmmiter }

constructor TEmmiter.Create;
begin
  fKind := Rectangular;
  fParticles := TParticleList.Create(true);
  fParticles.Capacity:= POOL_SIZE;
end;

procedure TEmmiter.Update(const deltaTime: real);
var
  i: integer;
begin
  for i :=0 to Pred(fParticles.Count-1) do
     fParticles[i].Update(deltaTime);
end;

{ TParticle }

function TParticle.GetAngleInRadians: real;
begin
  result := fAngle * (pi / 180);
end;

function TParticle.GetAlive: boolean;
begin
  result := fLife > 0;
end;

function TParticle.GetVelocity: TPoint;
var
  radians: real;
begin
  radians := GetAngleInRadians;
  result.x := fSpeed * cos(radians);
  result.y := fSpeed * sin(radians);
end;


constructor TParticle.Create(aPosition: TPoint; life, angle, speed: real);
begin
  inherited Create;
  Self.Position := aPosition;
  fLife:= life;
  fAngle:= angle;
  fSpeed:= speed;
end;

procedure TParticle.Update(const deltaTime: real);
begin
  fLife := fLife - deltaTime;
  if (fLife > 0) then
  begin
    Position.X := Position.X + (fVelocity.X * deltaTime);
    Position.Y := Position.Y + (fVelocity.Y * deltaTime);
  end;
end;


end.

