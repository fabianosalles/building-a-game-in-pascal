unit scnMainMenu;

interface

uses
  SDL2,
  sdlScene,
  StartField;

type

  TMenuOption = (moNewGame, moHighScore, moExit);

  { TMenu }

  TMenu = class
  private
    const
      YOFFSET = 30;
  public
    x, y: integer;
    selected : TMenuOption;
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
    TEXTURE_LOGO : integer;
    TEXTURE_PAWN : integer;
    TEXTURE_GEAR : integer;

    fAngle : double;
    fMenu  : TMenu;
    fAlpha : UInt8;
    fStars : TStarField;
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
  y := 450;
  selected := moNewGame;
end;

procedure TMenu.Draw;
var
  engine : TEngine;

  function getAlpha(item : TMenuOption) :UInt8;
  begin
    if self.selected = item then
       result := 255
    else
       result := 40;
  end;

begin
  engine := TEngine.GetInstance;
  engine.Text.Draw('new game',   x, y, engine.Fonts.MainMenu, getAlpha(moNewGame));
  engine.Text.Draw('high score', x, y + YOFFSET, engine.Fonts.MainMenu, getAlpha(moHighScore));
  engine.Text.Draw('exit',    x, y + 2 * YOFFSET, engine.Fonts.MainMenu, getAlpha(moExit));
end;

procedure TMenu.SelectNext(const amount: integer);
begin
  selected:= TMenuOption(Ord(selected) + amount);
  if Ord(selected) < 0 then
     selected:= TMenuOption(0);
  if selected > High(TMenuOption) then
     selected := TMenuOption(High(TMenuOption));
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
        case fMenu.selected of
          moNewGame   : doQuit(qtQuitCurrentScene, 0);
          moHighScore : doQuit(qtQuitCurrentScene, 1);
          moExit      : doQuit(qtQuitGame, 0);
        end;
      end;
  end;
end;

procedure TMainMenuScene.doLoadTextures;
var
  engine : TEngine;
begin
  engine := TEngine.GetInstance;
  engine.Textures.Clear;

  TEXTURE_LOGO    := engine.Textures.Load('aeonsoft-small.png');
  TEXTURE_PAWN    := engine.Textures.Load('paw-small.png');
  TEXTURE_GEAR    := engine.Textures.Load('gear-small.png');
end;

constructor TMainMenuScene.Create;
begin
  inherited;
  fMenu := TMenu.Create;
  fAlpha:= 0;
  fStars := TStarField.Create(400);;
end;

destructor TMainMenuScene.Destroy;
begin
  fMenu.Free;
  fStars.Free;
  inherited Destroy;
end;

procedure TMainMenuScene.doOnRender(renderer: PSDL_Renderer);
const
  DIVIDER_Y = 388;
var
  src, dest : TSDL_Rect;
  engine: TEngine;
begin
  engine := TEngine.GetInstance;
  renderer := engine.Renderer;

  fStars.Draw;
  fMenu.Draw;

  //divider line
  SDL_SetRenderDrawColor(renderer, $FF, $FF, $FF, $FF);
  SDL_RenderDrawLine(renderer, 0, DIVIDER_Y, engine.Window.w, DIVIDER_Y);


  engine.Text.Draw('open', 280, 307, engine.Fonts.GUILarge, $FF);
  engine.Text.Draw('SPACE-INVADERS', 280, 347, engine.Fonts.GUILarge, $FF);
  engine.Text.Draw('Aeonsoft 2017 - An open source tribute to Taito''s classic', 280, 395, engine.Fonts.DebugNormal, 80);

  src.x := 0;
  src.y := 0;
  SDL_SetTextureBlendMode(engine.Textures[TEXTURE_LOGO].Data, SDL_BLENDMODE_BLEND);
  SDL_SetTextureAlphaMod(engine.Textures[TEXTURE_LOGO].Data, $FF);

  //gear
  src.w := engine.Textures[TEXTURE_GEAR].W;
  src.h := engine.Textures[TEXTURE_GEAR].H;
  dest.x := 164;
  dest.y := 294;
  dest.h := 102;
  dest.w := 90;
  SDL_RenderCopyEx(renderer, engine.Textures[TEXTURE_GEAR].Data,
      @src, @dest, fAngle, nil, SDL_FLIP_NONE);

  //pawn
  src.w := engine.Textures[TEXTURE_PAWN].W;
  src.h := engine.Textures[TEXTURE_PAWN].H;

  dest.x := dest.x+25;
  dest.y := dest.y+31;
  dest.h := 38;
  dest.w := 40;
  SDL_RenderCopy(renderer, engine.Textures[TEXTURE_PAWN].Data, @src, @dest);


  //logo
  src.w := engine.Textures[TEXTURE_LOGO].W;
  src.h := engine.Textures[TEXTURE_LOGO].H;

  dest.x := 225;
  dest.y := 368;
  dest.h := 40;
  dest.w := 40;
  SDL_RenderCopy(renderer, engine.Textures[TEXTURE_LOGO].Data, @src, @dest);

end;

procedure TMainMenuScene.doOnUpdate(const deltaTime: real);
begin
  inherited doOnUpdate(deltaTime);
  fAngle := fAngle + 25 * deltaTime;
  fStars.Update(deltaTime);
end;

end.
