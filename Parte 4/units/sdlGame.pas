unit sdlGame;

{$mode objfpc}{$H+}

interface

uses
  sysutils,
  classes,

  SDL2,
  sdl2_ttf,
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
    fEnemies          : TEnemyList;
    fPlayer	          : TPlayer;
    fJoystick         : PSDL_Joystick;
    fShots            : TShotList;
    fDebugView        : boolean;
    fGameFonts        : TGameFonts;
    fGameText         : TGameTextManager;
    fScore            : integer;

    procedure Quit;
    procedure CheckDevices;
    procedure HandleEvents;
    procedure Render;
    procedure CheckCollision;
    procedure Update(const deltaTime : real);
    procedure LoadTextures;
    procedure FreeTextures;
    procedure SetDebugView(const aValue: boolean);

    procedure ScreenShot;

    procedure CreateGameObjects;
    procedure CreateFonts;
    procedure FreeFonts;
    procedure DrawGameObjects;

    procedure DrawDebugInfo;
    procedure DrawDebgText;
    procedure DrawDebugGrid;
    procedure DrawGUI;

    procedure FreeGameObjects;
    procedure OnFPSCounterUpdated(Sender: TFPSCounter; Counted: word);

    function GetDrawMode: TDrawMode;
    function LoadPNGTexture( const fileName: string ) : TTexture;

    procedure doPlayer_OnShot(Sender: TGameObject);
    procedure doShots_OnCollided(Sender, Suspect: TGameObject; var StopChecking: boolean);
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
  if ( SDL_Init( SDL_INIT_VIDEO or SDL_INIT_TIMER or SDL_INIT_JOYSTICK  ) <> 0 )then
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
    raise SDLTTFException( TTF_GetError );

  LoadTextures;
  CreateFonts;
  CreateGameObjects;
  fGameText := TGameTextManager.Create( fRenderer );
end;

procedure TGame.Quit;
begin
  FreeGameObjects;
  FreeTextures;
  FreeFonts;
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
  DrawDebugInfo;
  DrawGUI;

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
  try
    shotList    := fShots.FilterByDirection( TShotDirection.Up );
    suspectList := fEnemies.FilterByLife( true );
    for i:=0 to Pred(shotList.Count) do
      TShot(shotList[i]).CheckCollisions( suspectList );
  finally
    shotList.Free;
    suspectList.Free;
  end;
end;

procedure TGame.Update(const deltaTime : real ) ;
begin
  fPlayer.Update( deltaTime );
  fEnemies.Update( deltaTime );
  fShots.Update( deltaTime );
end;

procedure TGame.LoadTextures;
begin
  SetLength(fTextures, Ord( High( TSpriteKind ) ) +1 );

  fTextures[ ord(TSpriteKind.EnemyA) ]   := LoadPNGTexture( 'enemy_a.png' );
  fTextures[ ord(TSpriteKind.EnemyB) ]   := LoadPNGTexture( 'enemy_b.png' );
  fTextures[ ord(TSpriteKind.EnemyC) ]   := LoadPNGTexture( 'enemy_c.png' );
  fTextures[ ord(TSpriteKind.EnemyD) ]   := LoadPNGTexture( 'enemy_d.png' );
  fTextures[ ord(TSpriteKind.Player) ]   := LoadPNGTexture( 'player.png' );
  fTextures[ ord(TSpriteKind.Bunker) ]   := LoadPNGTexture( 'bunker.png' );
  fTextures[ ord(TSpriteKind.Garbage)]   := LoadPNGTexture( 'garbage.png' );
  fTextures[ ord(TSpriteKind.Explosion)] := LoadPNGTexture( 'explosion.png' );
  fTextures[ ord(TSpriteKind.ShotA) ]    := LoadPNGTexture( 'shot_a.png' );
  fTextures[ ord(TSpriteKind.Leds) ]     := LoadPNGTexture( 'leds.png' );
end;

procedure TGame.FreeTextures;
var
  i: integer;
begin
  for i:= low(fTextures) to High(fTextures) do
	  SDL_FreeSurface( fTextures[ i ].Data );
  SetLength(fTextures, 0);
end;

procedure TGame.SetDebugView(const aValue: boolean);
begin
  fDebugView := aValue;
  fShots.SetDrawMode(GetDrawMode);
  fEnemies.SetDrawMode(GetDrawMode);
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
    enemy.Position.X := DEBUG_CELL_SIZE + ( i mod 20 ) * DEBUG_CELL_SIZE ;
    enemy.Position.Y := 2 * DEBUG_CELL_SIZE + ( i div 20 ) * DEBUG_CELL_SIZE ;
    enemy.StartMoving;
    fEnemies.Add( enemy );
  end;

  fPlayer := TPlayer.Create( fRenderer );
  fPlayer.Sprite.Texture.Assign( fTextures[ integer(TSpriteKind.Player)] );
  fPlayer.Sprite.InitFrames(1,1);
  fPlayer.OnShotTriggered:= @doPlayer_OnShot;

  fPlayer.Position.X := trunc( SCREEN_HALF_WIDTH - ( fPlayer.Sprite.Texture.W / 2 ));
  fPlayer.Position.Y := (DEBUG_CELL_SIZE * 18) - fPlayer.Sprite.CurrentFrame.Rect.h;

  fShots := TShotList.Create(true);
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
end;


procedure TGame.DrawDebugInfo;
var
  source, dest : TSDL_Rect;
begin
  DrawDebugGrid;

  //desenha o led do sensor do controle
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


  DrawDebgText;
end;

procedure TGame.DrawDebgText;
begin
  fGameText.Draw(Format('SHOTS: %d', [fShots.Count]),
                 SCREEN_WIDTH-80, 20,
                 fGameFonts.DebugNormal);
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
begin
  SDL_SetRenderDrawColor(fRenderer, 255, 255, 0, 255);
  SDL_RenderDrawLine( fRenderer,  0,
                                  round(DEBUG_CELL_SIZE * 1.5),
                                  SCREEN_WIDTH,
                                  round(DEBUG_CELL_SIZE * 1.5));

  fGameText.Draw( Format('SCORE %.6d', [fScore]),  290, 12, fGameFonts.GUI  );
end;

procedure TGame.FreeGameObjects;
begin
  fEnemies.Free;
  fShots.Free;
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

procedure TGame.doPlayer_OnShot(Sender: TGameObject);
var
  player : TPlayer;
  shot : TShot;
begin
  if (Sender is TPlayer) then
  begin
    player  := TPlayer(Sender);
    shot := TShot.Create( fRenderer );
    shot.Sprite.Texture.Assign( fTextures[ Ord(TSpriteKind.ShotA) ] );
    shot.Sprite.InitFrames( 1,1 );
    shot.Position := player.ShotSpawnPoint;
    shot.Position.X -= (shot.Sprite.CurrentFrame.Rect.w / 2);
    shot.OnCollided := @doShots_OnCollided;
    shot.DrawMode  := GetDrawMode;
    fShots.Add( shot );
  end;
end;

procedure TGame.doShots_OnCollided(Sender, Suspect: TGameObject; var StopChecking: boolean);
var
  shot  : TShot;
  enemy : TEnemy;
begin
  if ( Sender is TShot )  then
  begin
    if (Suspect is TEnemy) and (TEnemy(Suspect).HP > 0) then
    begin
      shot  := TShot(Sender);
      enemy := TEnemy(Suspect);
      enemy.Hit( 1 );

      if enemy.Alive then
         Inc(fScore, 10)
      else
         Inc(fScore, 100);

      fShots.Remove( shot );
      StopChecking := true;
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

