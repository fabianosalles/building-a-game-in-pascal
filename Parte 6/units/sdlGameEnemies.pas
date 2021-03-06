﻿unit sdlGameEnemies;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}


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
  const
     SHOT_DELAY = 2500; //minimun interval between shots
  var
    fLastShotIteration : UInt32;
    fSpeed: real;
    fOldMoveDirection : TEnemyMoveDirection;
    fMoveDirection : TEnemyMoveDirection;
    fMovementOrigin: TVector;
    fOnShot : TGameObjectNotifyEvent;
    fColorModulation : TSDL_Color;
  private
    fCanShot: boolean;
    fHP : integer;
    function GetAlive: boolean;
    function GetShotSpawnPoint: TVector;
  protected
    procedure InitFields; override;
    function GetColorModulation: TSDL_Color; virtual;
  public
    destructor Destroy; override;
    procedure Update(const deltaTime : real); override;
    procedure Draw; override;
    procedure Hit( aDamage: byte =  1);
    procedure StartMoving;

    property Speed: real read fSpeed write fSpeed;
    property HP : integer read fHP write fHP;
    property Alive: boolean read GetAlive;
    property CanShot: boolean read fCanShot write fCanShot;
    property ShotSpawnPoint : TVector read GetShotSpawnPoint;
    property ColorModulation : TSDL_Color read GetColorModulation;

    property OnShot : TGameObjectNotifyEvent read fOnShot write fOnShot;
  end;


  { TEnemyList }

  TEnemyList = class(TGameObjectList)
  public
    procedure Update(const deltaTime: real); override;
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
    function GetColorModulation: TSDL_Color; override;
  end;


  { TEnemyC }

  TEnemyC = class( TEnemy )
  protected
    procedure InitFields; override;
    function GetColorModulation: TSDL_Color; override;
  end;


  { TEnemyD }

  TEnemyD = class( TEnemy )
  protected
    procedure InitFields; override;
  end;



implementation

{ TEnemyList }

procedure TEnemyList.Update(const deltaTime: real);
var
  i: integer;
  enemy : TEnemy;
  linha: integer;
begin
  inherited Update(deltaTime);

  //só pode atirar se não houver nenhum outro inimigo na linha de tiro
  for i:=0 to Pred(Self.Count) do
  begin
    enemy:= TEnemy(Self.Items[i]);
    linha := i div 20;
    enemy.CanShot := linha = 5;
    if linha < 5 then
       case linha of
         0: enemy.CanShot := (not TEnemy(Self.Items[i+20]).Alive) and
                             (not TEnemy(Self.Items[i+40]).Alive) and
                             (not TEnemy(Self.Items[i+60]).Alive) and
                             (not TEnemy(Self.Items[i+80]).Alive) and
                             (not TEnemy(Self.Items[i+100]).Alive);

         1: enemy.CanShot := (not TEnemy(Self.Items[i+20]).Alive) and
                             (not TEnemy(Self.Items[i+40]).Alive) and
                             (not TEnemy(Self.Items[i+60]).Alive) and
                             (not TEnemy(Self.Items[i+80]).Alive);

         2: enemy.CanShot := (not TEnemy(Self.Items[i+20]).Alive) and
                             (not TEnemy(Self.Items[i+40]).Alive) and
                             (not TEnemy(Self.Items[i+60]).Alive);

         3: enemy.CanShot := (not TEnemy(Self.Items[i+20]).Alive) and
                             (not TEnemy(Self.Items[i+40]).Alive);

         4: enemy.CanShot := (not TEnemy(Self.Items[i+20]).Alive) ;
       end;

  end;

end;

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

function TEnemyC.GetColorModulation: TSDL_Color;
begin
  result.g := 0;
  result.b := 0;
  case HP of
    2 : result.r := 200;
    1,0 : result.r := 255;
    else
      result := inherited GetColorModulation;
  end;
end;

procedure TEnemyC.InitFields;
begin
  inherited InitFields;
  fHP:= 3;
end;

{ TEnemyB }

function TEnemyB.GetColorModulation: TSDL_Color;
begin
  result.g := 0;
  result.b := 0;
  case HP of
    1,0 : result.r := 200;
    else
      result := inherited GetColorModulation;
  end;
end;

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

function TEnemy.GetColorModulation: TSDL_Color;
begin
  result.r := 255;
  result.g := 255;
  result.b := 255;
  result.a := 255;
end;

function TEnemy.GetShotSpawnPoint: TVector;
begin
  result := TVector.Create;
  result.X := fPosition.X + ( Sprite.CurrentFrame.Rect.w / 2 );
  result.Y := fPosition.Y-2;
end;

procedure TEnemy.InitFields;
begin
  inherited InitFields;
  fSpeed  := 10;
  fMoveDirection     := TEnemyMoveDirection.None;
  fOldMoveDirection  := TEnemyMoveDirection.None;
  fMovementOrigin    := TVector.Create;
  fMovementOrigin.Assign(fPosition);
  fLastShotIteration := 0;
  fCanShot           := false;
end;

procedure TEnemy.Update(const deltaTime : real);
const
  OFFSET_X = 3 * DEBUG_CELL_SIZE;
  OFFSET_Y = 16;
var
  currTicks : UInt32;
  deltaX : real;
  limitX : real;
  deltaY : real;
  limitY : real;


  procedure CalcXParams( aDirection : TEnemyMoveDirection );
  begin
    deltaX := Abs(Position.X - fMovementOrigin.X);
    case aDirection of
      TEnemyMoveDirection.Right : limitX := fMovementOrigin.X + OFFSET_X;
      TEnemyMoveDirection.Left  : limitX := fMovementOrigin.X - OFFSET_X;
    end;
  end;


  procedure CalcYParams;
  begin
    deltaY := Abs(Position.Y - fMovementOrigin.Y);
    limitY := fMovementOrigin.Y + OFFSET_Y;
  end;


  procedure ChangeDirection( aDirection : TEnemyMoveDirection );
  begin
    fOldMoveDirection := fMoveDirection;
    fMoveDirection:= aDirection;
  end;

begin
  if Assigned( Sprite ) then
     Sprite.Update(deltaTime);

  if fCanShot and Alive then
  begin
    currTicks:= SDL_GetTicks;
    if (currTicks - fLastShotIteration >= SHOT_DELAY) then
    begin
      if Random(100) <= 10 then
      begin
        if Assigned(fOnShot) then
           fOnShot(Self);
      end;
      fLastShotIteration:= currTicks;
    end;
  end;


  if ( fMoveDirection <> TEnemyMoveDirection.None ) then
    begin

      case fMoveDirection of

        TEnemyMoveDirection.Left  :
          begin
             CalcXParams( TEnemyMoveDirection.Left );
             Position.X := Position.X - ( fSpeed * deltaTime );
             if ( Position.X < limitX ) then
                Position.X := limitX;

             if ( deltaX = OFFSET_X ) then
             begin
               fMovementOrigin.Assign(fPosition);
               ChangeDirection( TEnemyMoveDirection.Down );
             end;
          end;

        TEnemyMoveDirection.Right :
          begin
             CalcXParams( TEnemyMoveDirection.Right );
             Position.X := Position.X + ( fSpeed * deltaTime );
             if ( Position.X > limitX ) then
                Position.X := limitX;

             if ( deltaX = OFFSET_X ) then
             begin
               fMovementOrigin.Assign(Position);
               ChangeDirection( TEnemyMoveDirection.Down );
             end;

          end;

        TEnemyMoveDirection.Down  :
          begin
             CalcYParams;
             Position.Y := Position.Y + ( fSpeed * deltaTime );
             if ( Position.Y > limitY ) then
                Position.Y := limitY;

             if ( deltaY = OFFSET_Y ) then
             begin
               fMovementOrigin.Assign(fPosition);
               if ( fOldMoveDirection = TEnemyMoveDirection.Left ) then
                  ChangeDirection( TEnemyMoveDirection.Right )
               else
                  ChangeDirection( TEnemyMoveDirection.Left );
             end;
          end;
      end;

    end;

end;


destructor TEnemy.Destroy;
begin
  fMovementOrigin.Free;
  inherited;
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
    SDL_SetTextureColorMod( fSprite.Texture.Data,
      Self.ColorModulation.r,
      Self.ColorModulation.g,
      Self.ColorModulation.b);
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
  fHP := fHP - aDamage;
end;

procedure TEnemy.StartMoving;
begin
  fMovementOrigin.Assign(fPosition);
  fMoveDirection  := TEnemyMoveDirection.Right;
end;


end.

