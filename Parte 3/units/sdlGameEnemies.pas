unit sdlGameEnemies;

{$mode objfpc}{$H+}

interface

uses
  classes,
  SDL2,

  sdlGameObjects;

type
  {  Forwards }

  TEnemy     = class;
  TEnemyA    = class;
  TEnemyB    = class;
  TEnemyC    = class;
  TEnemyD    = class;
  TEnemyList = class;


  { TEnemy }

  PEnemy = ^TEnemy;
  TEnemy = class( TGameObject )
  private
    fHP : integer;
    function GetAlive: boolean;
  public
    procedure Update(const deltaTime : real); override;
    procedure Draw; override;
    procedure Hit( aDamage: byte =  1);

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

procedure TEnemy.Update(const deltaTime : real);
begin
  if Assigned( Sprite ) then
     Sprite.Update(deltaTime);
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


end.

