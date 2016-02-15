unit sdlGame;

{$mode objfpc}{$H+}

interface

uses
  sysutils,
  classes,

  SDL2,
  sdl2_ttf,
  SDL2_mixer,
  sdl2_image,

  sdlGameEnemies,
  sdlGamePlayer,
  sdlGameObjects,
  sdlGameTypes,
  sdlGameText,
  sdlGameUtils;




type

  TSpriteKind = (
    EnemyA    = 0,
    EnemyB    = 1,
    EnemyC    = 2,
    EnemyD    = 3,
    Player    = 4,
    Bunker    = 5,
    Garbage   = 6,
    Explosion = 7,
    ShotA     = 8,
    Leds      = 9
  );

  TSoundKind = (
    sndEnemyBullet,
    sndEnemyHit,
    sndPlayerBullet,
    sndPlayerHit,
    sndGamePause,
    sndGameResume,
    sndGameOver
  );


  TGameState = (
    Playing,
    Paused,
    GameOver
  );





  { TGame }

  TGame = class
  strict private
  const
    WINDOW_TITLE = 'Delphi Games - Space Invaders';
  var
    fRunning          : boolean;
    fWindow           : PSDL_Window;
    fWindowSurface    : PSDL_Surface;
    fRenderer         : PSDL_Renderer;
    fFrameCounter     : TFPSCounter;
    fTextures         : array of TTexture;
    fSounds           : array of PMix_Chunk;
    fEnemies          : TEnemyList;
    fPlayer	          : TPlayer;
    fJoystick         : PSDL_Joystick;
    fShots            : TShotList;
    fExplosions       : TExplosionList;
    fDebugView        : boolean;
    fGameFonts        : TGameFonts;
    fGameText         : TGameTextManager;
    fScore            : integer;
    fGameState        : TGameState;

    procedure Quit;
    procedure CheckDevices;
    procedure HandleEvents;
    procedure Render;
    procedure CheckCollision;
    procedure Update(const deltaTime : real);
    procedure LoadTextures;
    procedure FreeTextures;
    procedure LoadSounds;
    procedure FreeSounds;
    procedure SetDebugView(const aValue: boolean);
    procedure ToggleFullScreen;

    procedure ScreenShot;

    procedure StartNewGame;
    procedure CreateGameObjects;
    procedure CreateFonts;
    procedure FreeFonts;
    procedure DrawGameObjects;

    procedure DrawDebugInfo;
    procedure DrawDebugGrid;
    procedure DrawGUI;

    procedure FreeGameObjects;
    procedure OnFPSCounterUpdated(Sender: TFPSCounter; Counted: word);

    function GetDrawMode: TDrawMode;
    function LoadPNGTexture( const fileName: string ) : TTexture;

    procedure doOnShot(Sender: TGameObject);
    procedure doOnShotCollided(Sender, Suspect: TGameObject; var StopChecking: boolean);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Initialize;
    procedure Run;
    property Running: boolean read fRunning;
  end;


implementation



procedure TGame.Initialize;
var
  flags, result: integer;
begin
  if ( SDL_Init( SDL_INIT_VIDEO or SDL_INIT_TIMER or SDL_INIT_JOYSTICK or SDL_INIT_AUDIO  ) <> 0 )then
  	 raise SDLException.Create(SDL_GetError);

  fWindow := SDL_CreateWindow( PAnsiChar( WINDOW_TITLE ),
                             SDL_WINDOWPOS_UNDEFINED,
                             SDL_WINDOWPOS_UNDEFINED,
                             SCREEN_WIDTH,
                             SCREEN_HEIGHT,
                             SDL_WINDOW_SHOWN);
  if fWindow = nil then
     raise SDLException.Create(SDL_GetError);

  fWindowSurface := SDL_GetWindowSurface( fWindow );
  if fWindowSurface = nil then
     raise SDLException.Create(SDL_GetError);

  fRenderer := SDL_CreateRenderer(fWindow, -1, SDL_RENDERER_ACCELERATED {or SDL_RENDERER_PRESENTVSYNC});
  if fRenderer = nil then
     raise SDLException.Create(SDL_GetError);

  flags  := IMG_INIT_PNG;
  result := IMG_Init( flags );
  if ( ( result and flags ) <> flags ) then
     raise SDLImageException.Create( IMG_GetError );

  result := TTF_Init;
  if ( result <> 0 ) then
    raise SDLTTFException.Create( TTF_GetError );

  result := Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048);
  if result < 0 then
     raise SDLMixerException.Create( Mix_GetError );

  Randomize;
  LoadTextures;
  LoadSounds;
  CreateFonts;
  CreateGameObjects;
  fGameText := TGameTextManager.Create( fRenderer );
  StartNewGame;
end;

procedure TGame.Quit;
begin
  FreeGameObjects;
  FreeTextures;
  FreeFonts;
  FreeSounds;
  fGameText.Free;
  if fJoystick <> nil then
  begin
    SDL_JoystickClose(fJoystick);
    fJoystick:= nil;
  end;
  fFrameCounter.Free;
  SDL_DestroyRenderer(fRenderer);
  SDL_DestroyWindow(fWindow);
  IMG_Quit;
  Mix_Quit;
  SDL_Quit;
end;

procedure TGame.CheckDevices;
var
  numJoysticks: SInt32;
begin
  numJoysticks:= SDL_NumJoysticks;
  if (numJoysticks > 0) then
  begin
     if (fJoystick = nil) then
     begin
        fJoystick:= SDL_JoystickOpen(0);
        exit;
     end;
  end
  else
    if fJoystick <> nil then
    begin
       SDL_JoystickClose(fJoystick);
       fJoystick := nil;
       exit;
    end;
end;

procedure TGame.HandleEvents;
var
  event : TSDL_Event;
begin
  while SDL_PollEvent( @event ) = 1 do
  begin
    case event.type_ of
      SDL_QUITEV  : fRunning := false;

      SDL_KEYDOWN :
        case event.key.keysym.sym of
          //player controls
          SDLK_LEFT, SDLK_A  : fPlayer.Input[Ord(TPlayerInput.Left)] := true;
          SDLK_RIGHT, SDLK_D : fPlayer.Input[Ord(TPlayerInput.Right)]:= true;
          SDLK_SPACE         : fPlayer.Input[Ord(TPlayerInput.Shot)] := true;

          SDLK_p             : ScreenShot;
          SDLK_g             : SetDebugView( not fDebugView );
          SDLK_ESCAPE        : fRunning := false;
        end;

      SDL_KEYUP :
        case event.key.keysym.sym of
          //player controls
          SDLK_LEFT, SDLK_A  : fPlayer.Input[Ord(TPlayerInput.Left)] := false;
          SDLK_RIGHT, SDLK_D : fPlayer.Input[Ord(TPlayerInput.Right)]:= false;
          SDLK_SPACE : fPlayer.Input[Ord(TPlayerInput.Shot)] := false;

          SDLK_f: ToggleFullScreen;
          SDLK_o:
            begin
              fGameState := TGameState.GameOver;
              Mix_PlayChannel(0, fSounds[ Ord(TSoundKind.sndGameOver) ], 0);
            end;
          SDLK_r: StartNewGame; //reset the game
          SDLK_RETURN :
            begin
              case fGameState of
                TGameState.Paused  :
                  begin
                    fGameState:= TGameState.Playing;
                    Mix_PlayChannel(-1, fSounds[ Ord(TSoundKind.sndGameResume) ], 0);
                  end;
                TGameState.Playing :
                  begin
                    fGameState:= TGameState.Paused;
                    Mix_PlayChannel(-1, fSounds[ Ord(TSoundKind.sndGamePause) ], 0);
                  end;
                TGameState.GameOver: StartNewGame;
              end;
            end;
        end;

      SDL_JOYAXISMOTION :
          case event.jaxis.axis of
            //X axis motion
		         0 : begin
                  fPlayer.Input[Ord(TPlayerInput.Left)] := false;
                  fPlayer.Input[Ord(TPlayerInput.Right)] := false;
                  if event.jaxis.value > 0 then
                     fPlayer.Input[Ord(TPlayerInput.Right)] := true
                  else
                  if event.jaxis.value < 0 then
                     fPlayer.Input[Ord(TPlayerInput.Left)] := true
                  end;
          end;

      SDL_JOYBUTTONUP :
        case  event.jbutton.button of
          0, 1, 2, 3 : fPlayer.Input[Ord(TPlayerInput.Shot)] := false;
          9: // 9 for stard button
             //http://wiki.gp2x.org/articles/s/d/l/SDL_Joystick_mapping.html
          begin
              case fGameState of
                TGameState.Paused  :
                  begin
                    fGameState:= TGameState.Playing;
                    Mix_PlayChannel(-1, fSounds[ Ord(TSoundKind.sndGameResume) ], 0);
                  end;
                TGameState.Playing :
                  begin
                    fGameState:= TGameState.Paused;
                    Mix_PlayChannel(-1, fSounds[ Ord(TSoundKind.sndGamePause) ], 0);
                  end;
                TGameState.GameOver: StartNewGame;
              end;
            end;

        end;

      SDL_JOYBUTTONDOWN :
        case  event.jbutton.button of
          0, 1, 2, 3 : fPlayer.Input[Ord(TPlayerInput.Shot)] := true;
        end;
    end;
  end;
end;

procedure TGame.Render;
begin
  SDL_SetRenderDrawColor( fRenderer, 0, 0, 0, SDL_ALPHA_OPAQUE );
  SDL_RenderClear( fRenderer );

  DrawGameObjects;
  DrawGUI;
  DrawDebugInfo;

  SDL_RenderPresent( fRenderer );
  fFrameCounter.Increment;
end;

procedure TGame.CheckCollision;
var
  i           : integer;
  shotList    : TShotList;
  suspectList : TEnemyList;
begin
  //check all shots going upwards with all alive enemies
  if (fShots.Count > 0) and ( fEnemies.Count > 0 ) then
  begin
    shotList    := fShots.FilterByDirection( TShotDirection.Up );
    suspectList := fEnemies.FilterByLife( true );
    for i:=0 to Pred(shotList.Count) do
      TShot(shotList[i]).CheckCollisions( suspectList );
    shotList.Free;
    suspectList.Free;
  end;

  //check all shots going downwards against the player
  if (fShots.Count > 0) then
  begin
    shotList := fShots.FilterByDirection( TShotDirection.Down );
    for i:=0 to shotList.Count-1 do
      TShot(shotList[i]).CheckCollisions( fPlayer );

    shotList.Free;
  end;
end;

procedure TGame.Update(const deltaTime : real ) ;
begin
  case fGameState of
    TGameState.Playing :
      begin
        fPlayer.Update( deltaTime );
        fEnemies.Update( deltaTime );
        fShots.Update( deltaTime );
        fExplosions.Update( deltaTime );
        if ( fPlayer.Lifes <=0)  then
        begin
         fGameState := TGameState.GameOver;
         Mix_PlayChannel(-1, fSounds[ Ord(TSoundKind.sndGameOver) ], 0);
        end;
      end;
    TGameState.Paused  :
      begin

      end;

    TGameState.GameOver:
      begin

      end;
  end;
end;

procedure TGame.LoadTextures;
begin
  SetLength(fTextures, Ord( High( TSpriteKind ) ) +1 );

  fTextures[ Ord(TSpriteKind.EnemyA) ]   := LoadPNGTexture( 'enemy_a.png' );
  fTextures[ Ord(TSpriteKind.EnemyB) ]   := LoadPNGTexture( 'enemy_b.png' );
  fTextures[ Ord(TSpriteKind.EnemyC) ]   := LoadPNGTexture( 'enemy_c.png' );
  fTextures[ Ord(TSpriteKind.EnemyD) ]   := LoadPNGTexture( 'enemy_d.png' );
  fTextures[ Ord(TSpriteKind.Player) ]   := LoadPNGTexture( 'player.png' );
  fTextures[ Ord(TSpriteKind.Bunker) ]   := LoadPNGTexture( 'bunker.png' );
  fTextures[ Ord(TSpriteKind.Garbage)]   := LoadPNGTexture( 'garbage.png' );
  fTextures[ Ord(TSpriteKind.Explosion)] := LoadPNGTexture( 'explosion.png' );
  fTextures[ Ord(TSpriteKind.ShotA) ]    := LoadPNGTexture( 'shot_a.png' );
  fTextures[ Ord(TSpriteKind.Leds) ]     := LoadPNGTexture( 'leds.png' );
end;

procedure TGame.FreeTextures;
var
  i: integer;
begin
  for i:= low(fTextures) to High(fTextures) do
	  SDL_FreeSurface( fTextures[ i ].Data );
  SetLength(fTextures, 0);
end;

procedure TGame.LoadSounds;
const
  SOUND_DIR = '.\assets\sounds\';
begin
  SetLength(fSounds, Ord(High( TSoundKind))+1);

  fSounds[ Ord(TSoundKind.sndEnemyBullet) ]  := Mix_LoadWAV(SOUND_DIR + 'EnemyBullet.wav');
  fSounds[ Ord(TSoundKind.sndEnemyHit) ]     := Mix_LoadWAV(SOUND_DIR + 'EnemyHit.wav');
  fSounds[ Ord(TSoundKind.sndPlayerBullet) ] := Mix_LoadWAV(SOUND_DIR + 'PlayerBullet.wav');
  fSounds[ Ord(TSoundKind.sndPlayerHit) ]    := Mix_LoadWAV(SOUND_DIR + 'PlayerHit.wav');
  fSounds[ Ord(TSoundKind.sndGamePause) ]    := Mix_LoadWAV(SOUND_DIR + 'GamePause.wav');
  fSounds[ Ord(TSoundKind.sndGameResume) ]   := Mix_LoadWAV(SOUND_DIR + 'GameResume.wav');
  fSounds[ Ord(TSoundKind.sndGameOver) ]     := Mix_LoadWAV(SOUND_DIR + 'GameOver.wav');
end;

procedure TGame.FreeSounds;
var
  i : integer;
begin
  for i:=Low(fSounds) to High(fSounds) do
    Mix_FreeChunk(fSounds[i]);
end;

procedure TGame.SetDebugView(const aValue: boolean);
begin
  fDebugView := aValue;
  fShots.SetDrawMode(GetDrawMode);
  fEnemies.SetDrawMode(GetDrawMode);
end;

procedure TGame.ToggleFullScreen;
var
  flags : UInt32;
begin
  flags:= SDL_GetWindowFlags(fWindow);
  if ((flags and SDL_WINDOW_FULLSCREEN) = 0) then
  begin
     SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'best');
     SDL_RenderSetLogicalSize(fRenderer, SCREEN_WIDTH, SCREEN_HEIGHT);
     SDL_SetWindowFullscreen(fWindow, SDL_WINDOW_FULLSCREEN_DESKTOP)

  end
  else
     SDL_SetWindowFullscreen(fWindow, 0);
end;

procedure TGame.ScreenShot;
const
  SCREENSHOT_DIR     = '.\screenshots\';
  SCREENSHOT_PREFIX  = 'shot';

  function GetNewFileName: string;
  var
    i: integer;
  begin
    i:= 0;
    result := Format('%s-%.3d.bmp', [SCREENSHOT_DIR + SCREENSHOT_PREFIX, i]);
    while FileExists(result) do
    begin
      result := Format('%s-%.3d.bmp', [SCREENSHOT_DIR + SCREENSHOT_PREFIX, i]);
      Inc(i);
    end;
  end;

var
  surface : PSDL_Surface;
begin
  surface:= nil;
  try
    surface:= SDL_CreateRGBSurface(0, SCREEN_WIDTH, SCREEN_HEIGHT, 32,
                                      $00FF0000, $0000FF00, $000000FF, $FF000000);
    SDL_RenderReadPixels( fRenderer, nil, SDL_PIXELFORMAT_ARGB8888, surface^.pixels, surface^.pitch );
    ForceDirectories(SCREENSHOT_DIR);
    SDL_SaveBMP(surface, GetNewFileName);
  finally
    SDL_FreeSurface( surface );
  end;
end;

procedure TGame.StartNewGame;
var
  i: integer;
  enemy : TEnemy;
begin
  fScore        := 0;
  fPlayer.Lifes := 3;
  fPlayer.Position.X := trunc( SCREEN_HALF_WIDTH - ( fPlayer.Sprite.Texture.W / 2 ));
  fPlayer.Position.Y := (DEBUG_CELL_SIZE * 18) - fPlayer.Sprite.CurrentFrame.Rect.h;

  for i:=0 to Pred(fEnemies.Count) do
  begin
    enemy := TEnemy(fEnemies.Items[i]);
    enemy.Position.X := DEBUG_CELL_SIZE + ( i mod 20 ) * DEBUG_CELL_SIZE ;
    enemy.Position.Y := 2 * DEBUG_CELL_SIZE + ( i div 20 ) * DEBUG_CELL_SIZE ;
    if enemy is TEnemyA then enemy.HP := 1;
    if enemy is TEnemyB then enemy.HP := 2;
    if enemy is TEnemyC then enemy.HP := 3;
    enemy.StartMoving;
  end;
  fShots.Clear;
  fGameState:= TGameState.Playing;
end;

procedure TGame.CreateGameObjects;
var
  i : integer;
  enemy  : TEnemy;
begin
  for i:= 0 to 119 do
  begin
    case i of
      00..39 :
        begin
          enemy := TEnemyC.Create( fRenderer );
          enemy.Sprite.Texture.Assign( fTextures[ integer(TSpriteKind.EnemyC) ] );
          enemy.Sprite.InitFrames(1, 2);
        end;

      40..79 :
        begin
          enemy := TEnemyB.Create( fRenderer );
          enemy.Sprite.Texture.Assign( fTextures[ integer(TSpriteKind.EnemyB) ] );
          enemy.Sprite.InitFrames(1, 2);
        end;

      80..119 :
        begin
          enemy := TEnemyA.Create( fRenderer );
          enemy.Sprite.Texture.Assign( fTextures[ integer(TSpriteKind.EnemyA) ] );
          enemy.Sprite.InitFrames(1, 2);
        end;
    end;
    enemy.OnShot := @doOnShot;
    fEnemies.Add( enemy );
  end;

  fPlayer := TPlayer.Create( fRenderer );
  fPlayer.Sprite.Texture.Assign( fTextures[ integer(TSpriteKind.Player)] );
  fPlayer.Sprite.InitFrames(1,1);
  fPlayer.OnShot:= @doOnShot;

  fShots      := TShotList.Create(true);
  fExplosions := TExplosionList.Create(true);
end;

  procedure TGame.CreateFonts;
  const
    FONTS_DIR = '.\assets\fonts\';
  begin
    fGameFonts := TGameFonts.Create( fRenderer );
    fGameFonts.LoadFonts( FONTS_DIR );
  end;

procedure TGame.FreeFonts;
begin
  fGameFonts.Free;
end;

procedure TGame.DrawGameObjects;
begin
  fPlayer.Draw;
  fEnemies.Draw;
  fShots.Draw;
  fExplosions.Draw;
end;


procedure TGame.DrawDebugInfo;
var
  source, dest : TSDL_Rect;
begin
  DrawDebugGrid;

  //draw upper left joystick sensor
  dest.x := 10;
  dest.y := DEBUG_CELL_SIZE div 2;
  dest.w := 16;
  dest.h := 16;

  source.y := 0;
  source.w := 16;
  source.h := 16;
  if SDL_NumJoysticks > 0 then
  begin
    source.x := 0;
    fGameText.Draw('GAME CONTROLLER FOUND', 32, 19, fGameFonts.DebugNormal);
  end
  else
  begin
    source.x := 16;
    fGameText.Draw('GAME CONTROLLER NOT FOUND', 32, 19, fGameFonts.DebugError);
  end;
  SDL_RenderCopy( fRenderer, fTextures[Ord(TSpriteKind.Leds)].Data, @source, @dest);
end;



procedure TGame.DrawDebugGrid;

  procedure HighlightSecions;
  var
    lPlayerBoundary : TSDL_Rect;
    lEnemyBoundary  : TSDL_Rect;
  begin
    lPlayerBoundary.x := DEBUG_CELL_SIZE;
    lPlayerBoundary.y := DEBUG_CELL_SIZE * 17;
    lPlayerBoundary.w := SCREEN_WIDTH - (2 * DEBUG_CELL_SIZE);
    lPlayerBoundary.h := DEBUG_CELL_SIZE;

    lEnemyBoundary.x := DEBUG_CELL_SIZE;
    lEnemyBoundary.y := DEBUG_CELL_SIZE + DEBUG_CELL_SIZE;
    lEnemyBoundary.w := SCREEN_WIDTH - (2 * DEBUG_CELL_SIZE);
    lEnemyBoundary.h := DEBUG_CELL_SIZE * 14;

    SDL_SetRenderDrawBlendMode(fRenderer, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(fRenderer, 255, 0, 0, 50);
    SDL_RenderFillRect( fRenderer, @lPlayerBoundary );
    SDL_RenderFillRect( fRenderer, @lEnemyBoundary );
  end;

var
  i, x, y : integer;
begin
  if fDebugView then
  begin
    HighlightSecions;

    SDL_SetRenderDrawBlendMode(fRenderer, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(fRenderer, 255, 0, 0, 130);

    //draw horizontal lines
    for i:=0 to DEBUG_CELL_COUNT_H do
    begin
      y := i*DEBUG_CELL_SIZE;
      SDL_RenderDrawLine(fRenderer, 0, y, SCREEN_WIDTH, y);
    end;

    //draw vertical lines
    for i:=0 to DEBUG_CELL_COUNT_V-1 do
    begin
      x := i* DEBUG_CELL_SIZE;
      SDL_RenderDrawLine(fRenderer, x, 0, x, SCREEN_HEIGHT);
    end;

    //draw center lines in green
    SDL_SetRenderDrawColor(fRenderer, 0, 200, 0, 130);
    SDL_RenderDrawLine( fRenderer,  SCREEN_HALF_WIDTH, 0, SCREEN_HALF_WIDTH, SCREEN_HEIGHT);
    SDL_RenderDrawLine( fRenderer,  0, SCREEN_HALF_HEIGHT, SCREEN_WIDTH, SCREEN_HALF_HEIGHT);
  end;
end;

procedure TGame.DrawGUI;
var
  rect  : TSDL_Rect;
begin
  SDL_SetRenderDrawColor(fRenderer, 255, 255, 0, 255);
  SDL_RenderDrawLine( fRenderer,  0,
                                  round(DEBUG_CELL_SIZE * 1.5),
                                  SCREEN_WIDTH,
                                  round(DEBUG_CELL_SIZE * 1.5));

  rect.x:= 0;
  rect.y:= 0;
  rect.h:= round(DEBUG_CELL_SIZE * 1.5);
  rect.w:= SCREEN_WIDTH;
  SDL_SetRenderDrawColor(fRenderer, 255, 0, 0, 80);
  SDL_RenderFillRect( fRenderer, @rect );
  fGameText.Draw( Format('SCORE %.6d', [fScore]),  290, 12, fGameFonts.GUI  );

  rect.x:= 710;
  rect.y:= 18;
  rect.h:= 2 *fPlayer.Sprite.Texture.H div 3;
  rect.w:= 2 *fPlayer.Sprite.Texture.W div 3;

  SDL_RenderCopy(fRenderer,
                   fPlayer.Sprite.Texture.Data,
                   @fPlayer.Sprite.CurrentFrame.Rect,
                   @rect);
   fGameText.Draw( Format('%.2d', [fPlayer.Lifes]),  738, 12, fGameFonts.GUI  );
  case fGameState of
    TGameState.Paused   :
      begin
        //obsfuscates the game stage
        rect.x := 0;
        rect.y := round( 1.5 * DEBUG_CELL_SIZE) +1;
        rect.h := SCREEN_HEIGHT - rect.y;
        rect.w:= SCREEN_WIDTH;
        SDL_SetRenderDrawColor(fRenderer, 0, 0, 0, 200);
        SDL_RenderFillRect( fRenderer, @rect );

        fGameText.Draw( '***[ PAUSED ]***' ,  155, SCREEN_HALF_HEIGHT-24, fGameFonts.GUI64  );
        if SDL_NumJoysticks = 0 then
           fGameText.Draw( 'press <enter> to resume', 320, SCREEN_HALF_HEIGHT+25, fGameFonts.DebugNormal  )
        else
           fGameText.Draw( 'press <start> to resume', 320, SCREEN_HALF_HEIGHT+25, fGameFonts.DebugNormal  );
      end;
    TGameState.GameOver :
      begin
        //obsfuscates the game stage
        rect.x := 0;
        rect.y := round( 1.5 * DEBUG_CELL_SIZE) +1;
        rect.h := SCREEN_HEIGHT - rect.y;
        rect.w:= SCREEN_WIDTH;
        SDL_SetRenderDrawColor(fRenderer, 50, 0, 0, 200);
        SDL_RenderFillRect( fRenderer, @rect );

        fGameText.DrawModulated( '***[ GAME OVER ]***' ,  105, SCREEN_HALF_HEIGHT-24, fGameFonts.GUI64, 255,0,0  );
        if SDL_NumJoysticks = 0 then
           fGameText.Draw( 'press <enter> to start a new game', 285, SCREEN_HALF_HEIGHT+25, fGameFonts.DebugNormal  )
        else
           fGameText.Draw( 'press <start> to start a new game', 285, SCREEN_HALF_HEIGHT+25, fGameFonts.DebugNormal  );

      end;
  end;


end;

procedure TGame.FreeGameObjects;
begin
  fEnemies.Free;
  fShots.Free;
  fExplosions.Free;;
end;

procedure TGame.OnFPSCounterUpdated(Sender: TFPSCounter; Counted: word);
var
  title: string;
begin
  Str(Counted, title);
  title := WINDOW_TITLE + ' - FPS: ' + title;
  SDL_SetWindowTitle( fWindow, PAnsiChar(title) );
end;

function TGame.GetDrawMode: TDrawMode;
begin
  if (fDebugView) then
     result := TDrawMode.Debug
  else
     result := TDrawMode.Normal;
end;

function TGame.LoadPNGTexture( const fileName: string ): TTexture;
const
  IMAGE_DIR = '.\assets\images\';
var
  temp : PSDL_Surface;
begin
  result := TTexture.Create;
  result.W := 0;
  result.H := 0;
  result.Data := nil;
  try
    temp := IMG_Load( PAnsiChar( IMAGE_DIR + fileName ) );
    if ( temp = nil ) then
       raise SDLException.Create( SDL_GetError )
    else
      begin
        result.W := temp^.w;
        result.H := temp^.h;
        result.Data := SDL_CreateTextureFromSurface( fRenderer, temp );
        if ( result.Data = nil ) then
           raise SDLImageException.Create( IMG_GetError );
      end;
  finally
    SDL_FreeSurface( temp );
  end;
end;

procedure TGame.doOnShot(Sender: TGameObject);

  procedure CreateShot(Position: TPoint; Direction: TShotDirection);
  var
    shot   : TShot;
  begin
    shot := TShot.Create( fRenderer );
    shot.Sprite.Texture.Assign( fTextures[ Ord(TSpriteKind.ShotA) ] );
    shot.Sprite.InitFrames( 1,1 );
    shot.Position := Position;
    shot.Position.X -= (shot.Sprite.CurrentFrame.Rect.w / 2);
    shot.OnCollided := @doOnShotCollided;
    shot.DrawMode   := GetDrawMode;
    shot.Direction:= Direction;
    fShots.Add( shot );
  end;

begin
  if (Sender is TPlayer) then
  begin
    CreateShot(TPlayer(Sender).ShotSpawnPoint, TShotDirection.Up);
    Mix_Volume(1, 30);
    Mix_PlayChannel(1, fSounds[ Ord(TSoundKind.sndPlayerBullet) ], 0);
  end
  else
  if (Sender is TEnemy) then
  begin
    CreateShot(TEnemy(Sender).ShotSpawnPoint, TShotDirection.Down);
    Mix_PlayChannel(1, fSounds[ Ord(TSoundKind.sndEnemyBullet) ], 0);
  end;
end;

procedure TGame.doOnShotCollided(Sender, Suspect: TGameObject; var StopChecking: boolean);
var
  shot       : TShot;
  enemy      : TEnemy;

  procedure CreateExplosion(Position: TPoint);
  var
    explostion : TExplosion;
  begin
    explostion := TExplosion.Create(fRenderer);
    explostion.Sprite.Texture.Assign(fTextures[Ord(TSpriteKind.Explosion)]);
    explostion.Sprite.InitFrames(1,1);
    explostion.Position := Position;
    fExplosions.Add(explostion);
  end;

begin
  if ( Sender is TShot )  then
  begin
    shot  := TShot(Sender);
    if (Suspect is TEnemy) and (TEnemy(Suspect).HP > 0) then
    begin
      enemy := TEnemy(Suspect);
      enemy.Hit( 1 );
      Mix_PlayChannel(-1, fSounds[ Ord(TSoundKind.sndEnemyHit) ], 0);

      if enemy.Alive then
         Inc(fScore, 10)
      else
        begin
         Inc(fScore, 100);
         CreateExplosion(enemy.Position);
        end;
      fShots.Remove( shot );
      StopChecking := true;
      exit;
    end;

   if ( Suspect is TPlayer ) then
   begin
     fPlayer.Hit( 1 );
     CreateExplosion(TPlayer(Suspect).Position);
     Mix_PlayChannel(-1, fSounds[ Ord(TSoundKind.sndEnemyHit) ], 0);
     fShots.Remove( shot );
   end;
  end;

end;

constructor TGame.Create;
begin
  fRunning      := false;
  fJoystick     := nil;
  fDebugView    := false;
  fEnemies      := TEnemyList.Create;
  fFrameCounter := TFPSCounter.Create;
  fScore        := 0;
  fFrameCounter.OnNotify:= @OnFPSCounterUpdated;
end;

destructor TGame.Destroy;
begin
  Quit;
  inherited;
end;

procedure TGame.Run;
var
  deltaTime : real;
  thisTime, lastTime : UInt32;
begin
  deltaTime := 0.0;
  thisTime  := 0;
  lastTime  := 0;
  fRunning  := true;
  while fRunning do
  begin
    thisTime  := SDL_GetTicks;
    deltaTime := real((thisTime - lastTime) / MSecsPerSec);
    lastTime  := thisTime;

    CheckDevices;
    HandleEvents;
    Update( deltaTime );
    CheckCollision;
    Render;

    SDL_Delay(1);
  end;
end;

end.

