unit sdlGamePlayer;

{$mode objfpc}{$H+}

interface

uses
  sysutils,

  SDL2,

  sdlGameTypes,
  sdlGameObjects;

type

  { TPlayer }

  TPlayerInput = (
    Left,
    Right,
    Shot
  );



  TPlayer = class( TGameObject )
  private
    fLifes: integer;
  const
    DEFAULT_SPEED    = 200.0;
    DEFAULT_COOLDOWN = 300;
  var
    fSpeed           : real;
    fCooldown        : integer;
    fCooldownCounter : integer;
    fShotSpawnPoint  : TPoint;
    fInput           : array[0..2] of boolean;
    fOnShot : TGameObjectNotifyEvent;
    function GetInput(index: integer): boolean;
    function GetShotSpawnPoint: TPoint;
    procedure SetInput(index: integer; AValue: boolean);
  public
    constructor Create(const aRenderer: PSDL_Renderer); override;
    procedure Draw; override;
    procedure Update(const deltaTime : real); override;

    property Input[index: integer] : boolean read GetInput write SetInput;
    property Speed : real read fSpeed write fSpeed;  //em pixels por segund
    property Cooldown: integer read fCooldown write fCooldown;
    property CooldownCounter: integer read fCooldownCounter;
    property ShotSpawnPoint : TPoint read GetShotSpawnPoint;
    property Lifes: integer read fLifes write fLifes;
    procedure Hit( aDamage: byte );

    property OnShot : TGameObjectNotifyEvent read fOnShot write fOnShot;
  end;



implementation

{ TPlayer }

function TPlayer.GetInput(index: integer): boolean;
begin
  if index > Length(fInput)-1 then
    raise IndexOutOfBoundsException.CreateFmt('TPlayer.GetInput(%d)', [index]);
  result := fInput[index];
end;

function TPlayer.GetShotSpawnPoint: TPoint;
var
  pos : TPoint;
begin
  pos := Self.Position;

  fShotSpawnPoint.X := pos.X + ( Sprite.CurrentFrame.Rect.w / 2 );
  fShotSpawnPoint.Y := pos.Y-2;
  result := fShotSpawnPoint;
end;

procedure TPlayer.SetInput(index: integer; AValue: boolean);
begin
  if index > Length(fInput)-1 then
    raise IndexOutOfBoundsException.CreateFmt('TPlayer.SetInput(%d)', [index]);
  fInput[index] := AValue;
end;

constructor TPlayer.Create(const aRenderer: PSDL_Renderer);
var
  i : integer;
begin
  inherited Create(aRenderer);
  fSpeed    := DEFAULT_SPEED;
  fCooldown := DEFAULT_COOLDOWN;
  fCooldownCounter:= 0;
  fLifes := 3;
  for i :=0 to High(fInput) do
     fInput[i] := false;
end;


procedure TPlayer.Draw;
var
  source, destination : TSDL_Rect;
begin
  if ( fSprite.Texture.Data <> nil ) then
  begin
    source := Sprite.CurrentFrame.Rect;

    destination.x := trunc(self.Position.X);
    destination.y := trunc(self.Position.Y);
    destination.w := 26;
    destination.h := 16;

    SDL_RenderCopy( fRenderer, fSprite.Texture.Data, @source, @destination) ;
  end;
end;

procedure TPlayer.Update(const deltaTime: real);
begin
  if fInput[Ord(TPlayerInput.Left)] then
  begin
     Position.X:= Position.X - ( fSpeed * deltaTime );
     if Position.X < DEBUG_CELL_SIZE then
        Position.X:= DEBUG_CELL_SIZE;
  end;

  if fInput[Ord(TPlayerInput.Right)] then
  begin
     Position.X:= Position.X + ( fSpeed * deltaTime );
     if Position.X > ((DEBUG_CELL_SIZE * 24) - Self.Sprite.CurrentFrame.Rect.w)  then
        Position.X:= ((DEBUG_CELL_SIZE * 24) - Self.Sprite.CurrentFrame.Rect.w);
  end;

  if fCooldownCounter > 0 then
     Dec(fCooldownCounter, trunc(deltaTime * MSecsPerSec));

  if ( (fInput[Ord(TPlayerInput.Shot)]) and ( fCooldownCounter <= 0) ) then
  begin
    if Assigned(fOnShot) then
       fOnShot(self);
    fCooldownCounter := fCooldown;
    fInput[Ord(TPlayerInput.Shot)] := false;
  end;

end;

procedure TPlayer.Hit(aDamage: byte);
begin
  fLifes -= aDamage;
  if fLifes < 0 then
     fLifes :=0;
end;


end.

