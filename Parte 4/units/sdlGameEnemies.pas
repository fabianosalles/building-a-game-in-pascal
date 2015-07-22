unit sdlGameEnemies;

{$mode objfpc}{$H+}

interface

uses
  classes,
  SDL2,

  sdlGameObjects,
  sdlGameTypes;

type
  {  Forwards }

  TEnemy     = class;
  TEnemyA    = class;
  TEnemyB    = class;
  TEnemyC    = class;
  TEnemyD    = class;
  TEnemyList = class;


  { TEnemy }

  TEnemyMoveDirection = (
    None,
    Right,
    Left,
    Down
  );


  PEnemy = ^TEnemy;
  TEnemy = class( TGameObject )
  strict private
    fSpeed: real;
    fOldMoveDirection : TEnemyMoveDirection;
    fMoveDirection : TEnemyMoveDirection;
    fMovementOrigin: TPoint;
  private
    fHP : integer;
    function GetAlive: boolean;
  protected
    procedure InitFields; override;
  public
    procedure Update(const deltaTime : real); override;
    procedure Draw; override;
    procedure Hit( aDamage: byte =  1);
    procedure StartMoving;

    property Speed: real read fSpeed write fSpeed;
    property HP : integer read fHP;
    property Alive: boolean read GetAlive;
  end;


  { TEnemyList }

  TEnemyList = class(TGameObjectList)
  public
    function FilterByLife( aAlive: boolean ): TEnemyList;
  end;


  { TEnemyA }

  TEnemyA = class( TEnemy )
  protected
    procedure InitFields; override;
  end;

  { TEnemyB }

  TEnemyB = class( TEnemy )
  protected
    procedure InitFields; override;
  end;


  { TEnemyC }

  TEnemyC = class( TEnemy )
  protected
    procedure InitFields; override;
  end;


  { TEnemyD }

  TEnemyD = class( TEnemy )
  protected
    procedure InitFields; override;
  end;



implementation

{ TEnemyList }


function TEnemyList.FilterByLife(aAlive: boolean): TEnemyList;
var
  i : integer;
  enemy : TEnemy;
begin
  result := TEnemyList.Create( false );
  for i:=0 to Pred( Self.Count ) do
  begin
    enemy := TEnemy(Self.Items[i]);
    if aAlive then
      if enemy.HP > 0 then
         result.Add( enemy )
    else
      if enemy.HP <= 0 then
         result.Add( enemy );
  end;
end;

{ TEnemyC }

procedure TEnemyC.InitFields;
begin
  inherited InitFields;
  fHP:= 3;
end;

{ TEnemyB }

procedure TEnemyB.InitFields;
begin
  inherited InitFields;
  fHP:= 2;
end;

{ TEnemyA }

procedure TEnemyA.InitFields;
begin
  inherited InitFields;
  fHP := 1;
end;

{ TEnemyD }

procedure TEnemyD.InitFields;
begin
  inherited InitFields;
  fHP:= 4;
end;

{ TEnemy }

function TEnemy.GetAlive: boolean;
begin
  result := fHP > 0;
end;

procedure TEnemy.InitFields;
begin
  inherited InitFields;
  fSpeed  := 10;
  fMoveDirection:= TEnemyMoveDirection.None;
  fOldMoveDirection:= TEnemyMoveDirection.None;
  fMovementOrigin := Position;
end;

procedure TEnemy.Update(const deltaTime : real);
const
  OFFSET_X = 3 * DEBUG_CELL_SIZE;
  OFFSET_Y = 16;
var
  deltaX : real;
  limitX : real;
  deltaY : real;
  limitY : real;

  procedure CalcXParams( aDirection : TEnemyMoveDirection ); inline;
  begin
    deltaX := Abs(Position.X - fMovementOrigin.X);
    case aDirection of
      TEnemyMoveDirection.Right : limitX := fMovementOrigin.X + OFFSET_X;
      TEnemyMoveDirection.Left  : limitX := fMovementOrigin.X - OFFSET_X;
    end;
  end;

  procedure CalcYParams; inline;
  begin
    deltaY := Abs(Position.Y - fMovementOrigin.Y);
    limitY := fMovementOrigin.Y + OFFSET_Y;
  end;

  procedure ChangeDirection( aDirection : TEnemyMoveDirection ); inline;
  begin
    fOldMoveDirection := fMoveDirection;
    fMoveDirection:= aDirection;
  end;

begin
  if Assigned( Sprite ) then
     Sprite.Update(deltaTime);

  if ( fMoveDirection <> TEnemyMoveDirection.None ) then
    begin

      case fMoveDirection of

        TEnemyMoveDirection.Left  :
          begin
             CalcXParams( TEnemyMoveDirection.Left );
             Position.X -= fSpeed * deltaTime;
             if ( Position.X < limitX ) then
                Position.X := limitX;

             if ( deltaX = OFFSET_X ) then
             begin
               fMovementOrigin := Position;
               ChangeDirection( TEnemyMoveDirection.Down );
             end;
          end;

        TEnemyMoveDirection.Right :
          begin
             CalcXParams( TEnemyMoveDirection.Right );
             Position.X += fSpeed * deltaTime;

             if ( Position.X > limitX ) then
                Position.X := limitX;

             if ( deltaX = OFFSET_X ) then
             begin
               fMovementOrigin := Position;
               ChangeDirection( TEnemyMoveDirection.Down );
             end;

          end;

        TEnemyMoveDirection.Down  :
          begin
             CalcYParams;
             Position.Y += fSpeed * deltaTime;

             if ( Position.Y > limitY ) then
                Position.Y := limitY;

             if ( deltaY = OFFSET_Y ) then
             begin
               fMovementOrigin := Position;
               if ( fOldMoveDirection = TEnemyMoveDirection.Left ) then
                  ChangeDirection( TEnemyMoveDirection.Right )
               else
                  ChangeDirection( TEnemyMoveDirection.Left );
             end;
          end;
      end;

    end;

end;


procedure TEnemy.Draw;
var
  source, destination : TSDL_Rect;
begin
  source      := Sprite.CurrentFrame.Rect;
  destination := Sprite.CurrentFrame.GetPositionedRect(self.Position);

  SDL_SetTextureColorMod( fSprite.Texture.Data, 255, 255, 255);
  if ( HP > 0 ) and ( fSprite.Texture.Data <> nil ) then
  begin
    if self is TEnemyB then
      case HP of
        1 : SDL_SetTextureColorMod( fSprite.Texture.Data, 255, 0, 0);
      end;

    if self is TEnemyC then
    case HP of
      2 : SDL_SetTextureColorMod( fSprite.Texture.Data, 255, 0, 0);
      1 : SDL_SetTextureColorMod( fSprite.Texture.Data, 200, 0, 0);
    end;
    SDL_RenderCopy( fRenderer, fSprite.Texture.Data, @source, @destination) ;

    if fDrawMode = TDrawMode.Debug then
    begin
        SDL_SetRenderDrawColor( fRenderer, 0, 255, 0, 255 );
        SDL_RenderDrawRect( fRenderer, @destination );
    end;
  end;

end;

procedure TEnemy.Hit(aDamage: byte);
begin
  fHP -= aDamage;
end;

procedure TEnemy.StartMoving;
begin
  fMovementOrigin := Position;
  fMoveDirection  := TEnemyMoveDirection.Right;
end;


end.

