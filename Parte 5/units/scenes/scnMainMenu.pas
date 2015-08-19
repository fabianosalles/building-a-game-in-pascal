unit scnMainMenu;

interface

uses
  SDL2,
  sdlScene;

type

  TMenuItem = (miNewGame, miHighScore, miCredits);

  { TMenu }

  TMenu = class
  private
    const
      YOFFSET = 35;
  public
    x, y: integer;
    selected : TMenuItem;
    constructor Create;
    procedure Draw;
    procedure SelectNext(const amount: integer);
  end;


  { TMainMenuScene }

  TMainMenuScene = class(TScene)
  private
  const
    FADE_IN   = 2000;
    FADE_OUT  = 2000;
    FADE_DELAY = 2000;
  var
    TEXTURE_FPINVADERS : integer;
    TEXTURE_ENEMY      : integer;

    fMenu  : TMenu;
    fAlpha : UInt8;
  protected
    procedure doOnKeyUp(key: TSDL_KeyCode); override;
    procedure doLoadTextures; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure doOnRender(renderer: PSDL_Renderer); override;
    procedure doOnUpdate(const deltaTime: real); override;
  end;

implementation

uses
  sdlEngine,
  sdlGameSound;

{ TMenu }

constructor TMenu.Create;
begin
  x := 540;
  y := 400;
end;

procedure TMenu.Draw;
var
  engine : TEngine;

  function getAlpha(item : TMenuItem) :UInt8;
  begin
    if self.selected = item then
       result := 255
    else
       result := 40;
  end;

begin
  engine := TEngine.GetInstance;

  engine.Text.Draw('new game', x, y, engine.Fonts.MainMenu, getAlpha(miNewGame));

  engine.Text.Draw('high score', x, y + YOFFSET, engine.Fonts.MainMenu, getAlpha(miHighScore));

  engine.Text.Draw('credits', x, y + 2 * YOFFSET, engine.Fonts.MainMenu, getAlpha(miCredits));
end;

procedure TMenu.SelectNext(const amount: integer);
begin
  selected:= TMenuItem(Ord(selected) + amount);
  if Ord(selected) < 0 then
     selected:= TMenuItem(0);
  if selected > High(TMenuItem) then
     selected := TMenuItem(High(TMenuItem));
end;


{ TMainMenuScene }

procedure TMainMenuScene.doOnKeyUp(key: TSDL_KeyCode);
begin
  inherited doOnKeyUp(key);
  case key of
    SDLK_UP   :
      begin
        TEngine.GetInstance.Sounds.Play(sndPlayerBullet);
        fMenu.SelectNext(-1);
      end;

    SDLK_DOWN :
      begin
        TEngine.GetInstance.Sounds.Play(sndPlayerBullet);
        fMenu.SelectNext(+1);
      end;
    SDLK_RETURN:
      begin
        TEngine.GetInstance.Sounds.Play(sndEnemyHit);
        doQuit;
      end;
  end;
end;

procedure TMainMenuScene.doLoadTextures;
var
  engine : TEngine;
begin
  engine := TEngine.GetInstance;
  engine.Textures.Clear;
  TEXTURE_FPINVADERS  := engine.Textures.Load('fpinvaders.png');
  TEXTURE_ENEMY       := engine.Textures.Load('enemy_a.png');
end;

constructor TMainMenuScene.Create;
begin
  inherited;
  fMenu := TMenu.Create;
  fAlpha:= 0;
end;

destructor TMainMenuScene.Destroy;
begin
  fMenu.Free;
  inherited Destroy;
end;

procedure TMainMenuScene.doOnRender(renderer: PSDL_Renderer);
var
  src, dest : TSDL_Rect;
  engie: TEngine;
begin
  engie := TEngine.GetInstance;

  //background
  src.x := engie.Textures[TEXTURE_ENEMY].W div 2;
  src.y := 0;
  src.w := engie.Textures[TEXTURE_ENEMY].W div 2;
  src.h := engie.Textures[TEXTURE_ENEMY].H;

  dest.x := -100;
  dest.y := 0;
  dest.h := 610;
  dest.w := round(dest.h * 0.95);

  SDL_SetTextureBlendMode(engie.Textures[TEXTURE_ENEMY].Data, SDL_BLENDMODE_BLEND);
  SDL_SetTextureAlphaMod(engie.Textures[TEXTURE_ENEMY].Data, 5);
  SDL_RenderCopy(engie.Renderer, engie.Textures[TEXTURE_ENEMY].Data, @src, @dest);


  //game logo
  dest.x := 160;
  dest.y := 140;
  dest.h := round(engie.Textures[TEXTURE_FPINVADERS].H * 1.2);
  dest.w := round(engie.Textures[TEXTURE_FPINVADERS].W * 1.2);
  SDL_RenderCopy(engie.Renderer, engie.Textures[TEXTURE_FPINVADERS].Data, nil, @dest);

  fMenu.Draw;
end;

procedure TMainMenuScene.doOnUpdate(const deltaTime: real);
begin
  inherited doOnUpdate(deltaTime);
end;

end.
