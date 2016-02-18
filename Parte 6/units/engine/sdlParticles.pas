unit sdlParticles;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  SysUtils,
{$IFDEF FPC}
  fgl,
{$ELSE}
   Generics.Collections,
{$ENDIF}
  SDL2,
  sdlEngine,
  sdlGameObjects,
  sdlGameTypes;


type

  { TParticle }

  TParticle = class(TGameObject)
  strict private
    fLife         : real;
    fInitialLife  : real;
    fAngle        : real;
    fSpeed        : real;
    fColor        : TSDL_Color;
    fWidth        : integer;
    fHeight       : integer;
    fVelocity     : TVector;
    function GetAlive: boolean;
    function GetAngleInRadians: real; inline;
    function GetVelocity: TVector;
  public
    constructor Create(aPosition: TVector; life, angle, speed: real);
    destructor Destroy; override;

    procedure Update(const deltaTime: real); override;

    property Life : real read fLife write fLife;
    property InitialLife: real read fInitialLife;
    property Angle : real read fAngle write fAngle;
    property Speed: real read fSpeed write fSpeed;
    property Color: TSDL_Color read fColor write fColor;
    property Width: integer read fWidth write fWidth;
    property Height: integer read fHeight write fHeight;

    property Alive: boolean read GetAlive;
    property AngleInRadians: real read GetAngleInRadians;
    property Velocity: TVector read GetVelocity;
  end;

  {$IFDEF FPC}
  TParticleList = specialize TFPGObjectList<TParticle>;
  {$ELSE}
  TParticleList = TObjectList<TParticle>;
  {$ENDIF}

  TEmitterKind = (
    ekContinuous,
    ekOneShot
  );


  { TEmmiter }
  PEmitter = ^TEmitter;
  TEmitter = class(TInterfacedObject, IUpdatable, IDrawable)
  strict private
  var
    fParticles : TParticleList;
    fKind      : TEmitterKind;
    fBounds    : TRect;

    fTimeAccum      : Real;
    fSpawnFrequency : Real;

    fActive        : Boolean;
    fGravity       : TVector;
    fAngle         : TRangeReal;
    fSpeed         : TRangeReal;
    fWidth         : TRangeReal;
    fHeight        : TRangeReal;
    fLifeSpan      : TRangeReal;
    fEmissionRate  : Integer;
    fMaxCount      : integer;
    fRenderer      : PSDL_Renderer;

    fOnAllParticleDied : TNotifyEvent;

    procedure CreateNewParticle;
    procedure UpdateParticles(const deltaTime: real);
    procedure SpawnParticles(const deltaTime: real);
  protected
     procedure doOnAllParticleDied; virtual;
  public
    constructor Create(renderer: PSDL_Renderer);
    destructor Destroy; override;
    procedure Update(const deltaTime: real);
    procedure Draw;

    procedure Start;
    procedure Stop;

    property Particles : TParticleList read fParticles;
    property Kind      : TEmitterKind read fKind write fKind;
    property Bounds    : TRect read fBounds write fBounds;

    property Active       : boolean read fActive;
    property Angle        : TRangeReal read fAngle write fAngle;
    property Speed        : TRangeReal read fSpeed write fSpeed;
    property Width        : TRangeReal read fWidth write fWidth;
    property Height       : TRangeReal read fHeight write fHeight;
    property LifeSpan     : TRangeReal read fLifeSpan write fLifeSpan;
    property Gravity      : TVector read fGravity write fGRavity;
    property MaxCount     : integer read fMaxCount write fMaxCount;
    property EmissionRate : Integer read fEmissionRate write fEmissionRate;

    property OnAllParticleDied : TNotifyEvent read fOnAllParticleDied write fOnAllParticleDied;
  end;

  {$IFDEF FPC}
  TGEmitterList = specialize TFPGObjectList<TEmitter>;
  {$ELSE}
  TGEmitterList = TObjectList<TEmitter>;
  {$ENDIF}

  TEmitterList = class(TGEmitterList)
  public
    procedure Draw;
    procedure Update(const deltaTime: real);
    procedure Start;
    procedure Stop;
  end;




  TEmitterFactory  = class
    class function NewSmokeOneShot: TEmitter;
    class function NewSmokeContinuous: TEmitter;
  end;


implementation

{ TEmmiter }

constructor TEmitter.Create(renderer: PSDL_Renderer);
begin
  fRenderer      := renderer;
  fAngle         := TRangeReal.Create;
  fSpeed         := TRangeReal.Create;
  fWidth         := TRangeReal.Create;
  fHeight        := TRangeReal.Create;
  fLifeSpan      := TRangeReal.Create;
  fGravity       := TVector.Create;
  fBounds        := TRect.Create;

  Kind := ekContinuous;
  fParticles := TParticleList.Create(true);
  fParticles.Capacity:= 50;
  fActive := false;

  fGravity.X := 1;
  fGravity.Y := 0;

  fAngle.Min := 90 - 10;
  fAngle.Max := 90 + 10;

  fSpeed.Min := 05;
  fSpeed.Max := 15;

  fEmissionRate := 10;

  fLifeSpan.Min := 1;
  fLifeSpan.Max := 3;

  fMaxCount := 100;

  fWidth.Min := 6;
  fWidth.Max := 8;

  fHeight.Min := 6;
  fHeight.Max := 8;

  fTimeAccum := 0;
end;

procedure TEmitter.doOnAllParticleDied;
begin
  if Assigned(fOnAllParticleDied) then
     fOnAllParticleDied(Self);
end;

procedure TEmitter.Draw;
var
  i: integer;
  p: TParticle;
  r: TSDL_Rect;
begin
  SDL_SetRenderDrawBlendMode(fRenderer, SDL_BLENDMODE_ADD);
  for i :=0 to fParticles.Count-1 do
  begin
    p := Particles[i];
    if p.Alive then begin
      r.x := round(p.Position.X);
      r.y := round(p.Position.Y);
      r.w := round(p.Width);
      r.h := round(p.Height);

      SDL_SetRenderDrawColor(fRenderer, p.Color.r, p.Color.g, p.Color.b, p.Color.a);
      SDL_RenderFillRect(fRenderer, PSDL_Rect(@r));
    end;
  end;
end;

procedure TEmitter.CreateNewParticle;
var
  lParticle : TParticle;
  lPosition : TVector;
  lLife     : Real;
  lAngle    : Real;
  lSpeed    : Real;
  lColor    : TSDL_Color;
begin
  lPosition := TVector.Create((fBounds.x) + Random(fBounds.w),
                              (fBounds.y) + Random(fBounds.h));

  lLife     := fLifeSpan.Min + Random(Round(fLifeSpan.Max));
  lAngle    := fAngle.Min + (random * (fAngle.Max - fAngle.Min));
  lSpeed    := fSpeed.Min + (random * (fSpeed.Max - fSpeed.Min));
  lColor.r := $FF;
  lColor.g := $FF;
  lColor.b := $AA;
  lColor.a := $FF;

  lParticle := TParticle.Create(lPosition, lLife, lAngle, lSpeed);
  lParticle.Color  := lColor;
  lParticle.Width  := Round(fWidth.Min + random * (fWidth.Max - fWidth.Min));
  lParticle.Height := Round(fHeight.Min + random * (fHeight.Max - Height.Min));
  fParticles.Add(lParticle);
end;

destructor TEmitter.Destroy;
begin
  fAngle.Free;
  fSpeed.Free;
  fWidth.Free;
  fHeight.Free;
  fLifeSpan.Free;
  fGravity.Free;
  fBounds.Free;
  fParticles.Free;
  inherited;
end;


procedure TEmitter.SpawnParticles(const deltaTime: real);
begin
  case fKind of
    ekContinuous:
      begin
        if (fTimeAccum >= fSpawnFrequency) and (fParticles.Count < fMaxCount) then
        begin
          CreateNewParticle;
          fTimeAccum := fTimeAccum - fSpawnFrequency;
        end;
      end;
  end;
end;

procedure TEmitter.Start;
var
  i : integer;
begin
  case fKind of
    ekContinuous:
      begin
         fSpawnFrequency := ( MSecsPerSec / fEmissionRate ) / MSecsPerSec;
      end;

    ekOneShot:
      begin
        fParticles.Clear;
        for i:=0 to fMaxCount-1 do
          CreateNewParticle;
      end;
  end;
  fActive := true;
end;

procedure TEmitter.Stop;
begin
  fActive := false;
end;

procedure TEmitter.Update(const deltaTime: real);
begin
  fTimeAccum := fTimeAccum + deltaTime;

  if fActive then
    SpawnParticles(deltaTime);

  UpdateParticles(deltaTime);
end;

procedure TEmitter.UpdateParticles(const deltaTime: real);
var
  i: integer;
  p: TParticle;
  color: TSDL_Color;
  listChanged: boolean;
begin
  listChanged := false;
  for i:= Particles.Count-1 downto 0 do
  begin
     p := fParticles[i];
     p.Life := p.Life - deltaTime;
     if p.Alive then begin
        p.Position.X := p.Position.X + (p.Velocity.X * deltaTime) + (fGravity.X * deltaTime);
        p.Position.Y := p.Position.Y + (p.Velocity.Y * deltaTime) + (fGravity.Y * deltaTime);

        color := p.Color;
        if p.InitialLife <= 0 then
           color.a := 0
        else
           color.a := round(255 * (p.Life / p.InitialLife));
        p.Color := color;
     end
     else begin
        fParticles.Remove(p);
        listChanged := true;
     end;
  end;
  if (listChanged and (Particles.Count = 0)) then
    doOnAllParticleDied;
end;

{ TParticle }

function TParticle.GetAngleInRadians: real;
begin
  result := fAngle * (pi / 180);
end;

destructor TParticle.Destroy;
begin
  fVelocity.Free;
  inherited;
end;

function TParticle.GetAlive: boolean;
begin
  result := fLife > 0;
end;

function TParticle.GetVelocity: TVector;
var
  radians: real;
begin
  radians := GetAngleInRadians;
  fVelocity.x := fSpeed * cos(radians);
  fVelocity.y := fSpeed * sin(radians);
  result := fVelocity;
end;


constructor TParticle.Create(aPosition: TVector; life, angle, speed: real);
begin
  inherited Create;
  Self.Position := aPosition;
  fLife:= life;
  fInitialLife := life;
  fAngle:= angle;
  fSpeed:= speed;
  fVelocity := TVector.Create;
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



{ TEmitterFactory }

class function TEmitterFactory.NewSmokeContinuous: TEmitter;
var
 bounds : TSDL_Rect;
begin
  result := NewSmokeOneShot;
  result.Kind := ekContinuous;
  result.LifeSpan.Min := 0.2;
  result.LifeSpan.Max := 0.5;
  result.MaxCount := 500;
  result.EmissionRate := 30;
end;

class function TEmitterFactory.NewSmokeOneShot: TEmitter;
begin
  result := TEmitter.Create(TEngine.GetInstance.Renderer);
  result.Kind := ekOneShot;

  result.Bounds.x := 300;
  result.Bounds.y := 200;
  result.Bounds.w := 5;
  result.Bounds.h := 10;

  result.Width.Min := 2;
  result.Width.Max := 2;

  result.Height.Min := 1;
  result.Height.Max := 2;

  result.LifeSpan.Min := 1;
  result.LifeSpan.Max := 2;

  result.Gravity.Y := 50;
  result.Gravity.X := 0;

  result.Angle.Min := 270-30;
  result.Angle.Max := 270+30;

  result.MaxCount := 10;
end;



procedure TEmitterList.Draw;
var
  i : integer;
begin
  for i:=0 to Count-1 do
    Items[i].Draw;
end;

procedure TEmitterList.Start;
var
  i : integer;
begin
  for i:=0 to Count-1 do
    Items[i].Start
end;

procedure TEmitterList.Stop;
var
  i : integer;
begin
  for i:=0 to Count-1 do
    Items[i].Stop;
end;


procedure TEmitterList.Update(const deltaTime: real);
var
  i : integer;
begin
  for i:=0 to Count-1 do
    Items[i].Update(deltaTime);
end;

end.

