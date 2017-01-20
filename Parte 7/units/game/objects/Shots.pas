unit Shots;

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

  { TShot }

type
  TShotDirection = (
    Up,
    Down
  );


  TShot = class ( TGameObject )
  strict private
    fDirection       : TShotDirection;
    fSpeed           : real;
    fShowSmoke       : boolean;
    fSmokeEmitter    : TEmitter;
    fOnSmokeVanished : TNotifyEvent;
    fActive: boolean;

    procedure doOnAllParticleDied(Sender: TObject);
    procedure DrawShot;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure Draw; override;
    procedure Update(const deltaTime : real); override;
    function IsInsideScreen: boolean;
    procedure StopEmitSmoke;
    procedure StartEmitSmoke;

    property Active    : boolean read fActive write fActive;
    property Direction : TShotDirection read fDirection write fDirection;
    property Speed     : real read fSpeed write fSpeed;
    property ShowSmoke : boolean read fShowSmoke write fShowSmoke;

    property OnSmokeVanished: TNotifyEvent read fOnSmokeVanished write fOnSmokeVanished;
  end;


  { TShotList }

  TShotList = class( TGameObjectList )
  public
    function FilterByDirection( aDireciton: TShotDirection ) : TShotList;
  end;

  { TExplosion }

  TExplosion = class( TGameObject )
  strict private
  const
    LIFE_TIME   = 500;
    START_FADE  = 100;
  var
    fCreatedTicks: UInt32;
    fOpacity: UInt8;
  protected
    procedure InitFields; override;
  public
    procedure Draw; override;
    procedure Update(const deltaTime : real); override;
  end;

  { TExplosionList }

  TExplosionList = class( TGameObjectList )
  public
    procedure Update(const deltaTime : real); override;
    procedure Draw; override;
  end;



implementation

{ TExplosionList }

procedure TExplosionList.Update(const deltaTime: real);
var
  i : integer;
  s : TExplosion;
begin
  for i:= Pred(Self.Count) downto 0 do
  begin
      s := TExplosion(Self.Items[i]);
      s.Update( deltaTime );
      if not s.Visible then
      begin
        Self.Remove( s );
      end;
  end;
end;

procedure TExplosionList.Draw;
var
  i : integer;
  s : TExplosion;
begin
  for i:= Pred(Self.Count) downto 0 do
  begin
      s := TExplosion(Self.Items[i]);
      s.Draw;
  end;
end;



{ TExplosion }

procedure TExplosion.InitFields;
begin
  inherited InitFields;
  fVisible:= true;
  fCreatedTicks := SDL_GetTicks;
  fOpacity:= $FF;
end;

procedure TExplosion.Draw;
var
  destination : TSDL_Rect;
  frame       : TSpriteFrame;
begin
  if ( fSprite.Texture.Data <> nil ) and fVisible then
  begin
    frame := Self.Sprite.CurrentFrame;
    destination := frame.GetPositionedRect(self.Position);

    SDL_SetTextureColorMod( fSprite.Texture.Data,
                                       fOpacity,
                                       fOpacity,
                                       0);
    SDL_SetTextureAlphaMod( fSprite.Texture.Data, fOpacity);
    SDL_RenderCopy( fRenderer, fSprite.Texture.Data,
                    @frame.Rect,
                    @destination) ;

    if fDrawMode = TDrawMode.Debug then
    begin
      SDL_SetRenderDrawColor( fRenderer, 0, 255, 0, 255 );
      SDL_RenderDrawRect( fRenderer, @destination );
    end;
  end;

end;

procedure TExplosion.Update(const deltaTime: real);
var
  elapsed: UInt32;
  opacity : extended;
  fadeTime: integer;
begin
  if fVisible then
  begin
    elapsed := SDL_GetTicks - fCreatedTicks;
    if elapsed > START_FADE then
    begin
      elapsed := elapsed -START_FADE;
      fadeTime:= LIFE_TIME-START_FADE;
      opacity := 255 - ((elapsed  / fadeTime) * 255 );
      opacity:= Round(opacity);
      opacity:= Max(opacity, 0);
      opacity:= Min(255, opacity);

      fOpacity := Trunc(opacity);
      fVisible := elapsed < LIFE_TIME;
    end;
  end;
end;


{ TShotList }


function TShotList.FilterByDirection(aDireciton: TShotDirection): TShotList;
var
  i: integer;
  shot : TShot;
begin
  result := TShotList.Create( false );
  for i:=0 to Pred(Self.Count) do
    begin
      shot := TShot(Self.Items[i]);
    if (shot.Visible) and (shot.Direction = aDireciton) then
       result.Add( Self.Items[i] );
    end;
end;


{ TShot }

constructor TShot.Create;
begin
  inherited;
  fSpeed     := 300.0;
  fDirection := TShotDirection.Up;
  fVisible   := true;
  fShowSmoke := false;
  fSmokeEmitter     := TEmitterFactory.NewSmokeContinuous;
  fSmokeEmitter.OnAllParticleDied := {$IFDEF FPC}@{$ENDIF}doOnAllParticleDied;
  fActive    := True;
end;


destructor TShot.Destroy;
begin
  fSmokeEmitter.Free;
  inherited;
end;

procedure TShot.Draw;
begin
  if fVisible then
     DrawShot;

  if fShowSmoke then
     fSmokeEmitter.Draw;
end;

procedure TShot.DrawShot;
var
  destination : TSDL_Rect;
  frame       : TSpriteFrame;
begin
  if ( fSprite.Texture.Data <> nil )then
  begin
    frame := Self.Sprite.CurrentFrame;
    destination.w := 6;
    destination.h := 12;
    destination.x := trunc(self.Position.X);
    destination.y := trunc(self.Position.Y);
    destination := frame.GetPositionedRect(self.Position);
    case fDirection of
     TShotDirection.Down :
      begin
       SDL_RenderCopy( fRenderer, fSprite.Texture.Data, @frame.Rect, @destination) ;
      end;

     TShotDirection.Up  :
      begin
       SDL_RenderCopyEx( fRenderer, fSprite.Texture.Data, @frame.Rect,
                         @destination, 0, nil, SDL_FLIP_VERTICAL);
      end;
    end;

    if fDrawMode = TDrawMode.Debug then
    begin
      SDL_SetRenderDrawColor( fRenderer, 0, 255, 0, 255 );
      SDL_RenderDrawRect( fRenderer, @destination );
    end;
  end;

end;


procedure TShot.Update(const deltaTime: real);
var
  insideScreen: boolean;
begin
  if fActive then
  begin
    case fDirection of
      TShotDirection.Up   : fPosition.Y := fPosition.Y - (fSpeed * deltaTime);
      TShotDirection.Down : fPosition.Y := fPosition.Y + (fSpeed * deltaTime);
    end;
  end;
  fSmokeEmitter.Bounds.X := Round(fPosition.X);
  fSmokeEmitter.Bounds.W := fSprite.CurrentFrame.Rect.w;
  case fDirection of
    Up   : fSmokeEmitter.Bounds.Y := Round(fPosition.Y + fSprite.CurrentFrame.Rect.h);
    Down : fSmokeEmitter.Bounds.Y := Round(fPosition.Y - fSprite.CurrentFrame.Rect.h);
  end;
  fSmokeEmitter.Update(deltaTime);

  insideScreen := isInsideScreen;
  if fVisible then
     fVisible := insideScreen;
  if (not insideScreen and fSmokeEmitter.Active) then
     StopEmitSmoke;

end;

function TShot.isInsideScreen: boolean;
begin
  result := ( (  Position.Y >= -(fSprite.Texture.H+1)) and (Position.Y < SCREEN_HEIGHT+1) ) and
              ( (Position.X >= -(fSprite.Texture.W+1)) and (Position.X < SCREEN_WIDTH+1) );

end;


procedure TShot.StartEmitSmoke;
begin
  fSmokeEmitter.Start;
end;

procedure TShot.StopEmitSmoke;
begin
  fSmokeEmitter.Stop;
end;

procedure TShot.doOnAllParticleDied(Sender: TObject);
begin
  if (Sender = fSmokeEmitter) and (Assigned(fOnSmokeVanished)) then
    fOnSmokeVanished(Self);
end;

end.
