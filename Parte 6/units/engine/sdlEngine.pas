unit sdlEngine;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  sdl2,
  sdlGameUtils,
  sdl2_image,
  SDL2_mixer,
  sdl2_ttf,

  sdlGameText,
  sdlGameTypes,
  sdlGameTexture,
  sdlGameSound,

  sdlScene,

  sysutils;

const
  ASSETS_DIR  = AnsiString('.\assets\');
  FONTS_DIR   = AnsiString(ASSETS_DIR + 'fonts\');
  SOUND_DIR   = AnsiString(ASSETS_DIR + 'sounds\');
  IMAGE_DIR   = AnsiString(ASSETS_DIR + 'images\');

type

  { TEngine }

  TEngine = class
  strict private
    class var fInstance : TEngine;
    var
     fRunning     : boolean;
     fTitle       : string;
     fActiveScene : TScene;
  private
    fTextures     : TTextureManager;
    fWindow       : PSDL_Window;
    fRenderer     : PSDL_Renderer;
    fText         : TTextManager;
    fFonts        : TFonts;
    fSounds : TSoundManager;
    fFPSCounter   : TFPSCounter;
    fJoystick     : PSDL_Joystick;

    function GetWindow: TSDL_Window;
    procedure OnFPSCounterUpdated(Sender: TFPSCounter; Counted: word);
  protected
    procedure doUpdate(deltaTime: real);
    procedure doRender;
    procedure doHandleEvents;
    procedure doCheckDevices;
    procedure doCheckCollisions;
  public
    constructor Create;
    class function GetInstance: TEngine;

    procedure Initialize(const width: integer; const height: integer; const title: string);
    procedure ToggleFullScreen;
    procedure ScreenShot;

    destructor Destroy; override;

    procedure SetActiveScene(scene: TScene);
    procedure HideCursor;
    procedure ShowCursor;
    procedure Run;

    //instance properties
    property Window: TSDL_Window read GetWindow;
    property Renderer: PSDL_Renderer read fRenderer;
    property Fonts: TFonts read fFonts;
    property Text: TTextManager read fText;
    property Sounds: TSoundManager read fSounds;
    property Textures: TTextureManager read fTextures write fTextures;

  end;



implementation

{ TEngine }

class function TEngine.GetInstance: TEngine;
begin
  if fInstance = nil then
     fInstance := TEngine.Create;
  result := fInstance;
end;

function TEngine.GetWindow: TSDL_Window;
begin
  result := fWindow^;
end;

procedure TEngine.OnFPSCounterUpdated(Sender: TFPSCounter; Counted: word);
var
  title: string;
begin
  Str(Counted, title);
  title := fTitle + ' - FPS: ' + title;
  SDL_SetWindowTitle( fWindow, PAnsiChar(AnsiString(title)) );
end;

procedure TEngine.doUpdate(deltaTime: real);
begin
  if Assigned(fActiveScene.OnUpdate) then
     fActiveScene.OnUpdate(deltaTime);
end;

procedure TEngine.doRender;
begin
  SDL_SetRenderDrawColor( fRenderer, 0, 0, 0, SDL_ALPHA_OPAQUE );
  SDL_RenderClear( fRenderer );


  if Assigned(fActiveScene.OnRender) then
     fActiveScene.OnRender( fRenderer );

  SDL_RenderPresent( fRenderer );
  fFPSCounter.Increment;
end;

procedure TEngine.doHandleEvents;
var
  event : TSDL_Event;
begin
  while SDL_PollEvent( @event ) = 1 do
    case event.type_ of
      SDL_QUITEV  : fRunning := false;

      SDL_KEYDOWN : if Assigned(fActiveScene.OnKeyDown) then fActiveScene.OnKeyDown(event.key.keysym.sym);

      SDL_KEYUP   : if Assigned(fActiveScene.OnKeyUp) then fActiveScene.OnKeyUp(event.key.keysym.sym);

      SDL_JOYAXISMOTION : if Assigned(fActiveScene.OnJoyAxisMotion) then fActiveScene.OnJoyAxisMotion(event.jaxis.axis, event.jaxis.value);

      SDL_JOYBUTTONUP : if Assigned(fActiveScene.OnJoyButtonUp) then fActiveScene.OnJoyButtonUp(event.jbutton.which, event.jbutton.button);

      SDL_JOYBUTTONDOWN : if Assigned(fActiveScene.OnJoyButtonDown) then fActiveScene.OnJoyButtonDown(event.jbutton.which, event.jbutton.button);
    end;
end;

procedure TEngine.doCheckDevices;
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

procedure TEngine.doCheckCollisions;
begin
  if Assigned(fActiveScene.OnCheckCollisions) then
     fActiveScene.OnCheckCollisions;
end;

procedure TEngine.Initialize(const width: integer; const height: integer;
  const title: string);
var
  flags, result: integer;
begin
  if ( SDL_Init( SDL_INIT_VIDEO or SDL_INIT_TIMER or SDL_INIT_JOYSTICK or SDL_INIT_AUDIO  ) <> 0 )then
  	 raise SDLException.Create( SDL_GetError );

  fTitle:= title;
  fWindow := SDL_CreateWindow( PAnsiChar( AnsiString(fTitle) ),
                               SDL_WINDOWPOS_UNDEFINED,
                               SDL_WINDOWPOS_UNDEFINED,
                               width, height,
                               SDL_WINDOW_SHOWN);
  if ( fWindow = nil ) then
     raise SDLException.Create( SDL_GetError );


  fRenderer := SDL_CreateRenderer( fWindow, -1, SDL_RENDERER_ACCELERATED);
  if ( fRenderer = nil ) then
     raise SDLException.Create( SDL_GetError );

  flags  := IMG_INIT_PNG;
  result := IMG_Init( flags );
  if ( ( result and flags ) <> flags ) then
     raise SDLImageException.Create( IMG_GetError );

  result := TTF_Init;
  if ( result <> 0 ) then
    raise SDLTTFException.Create( TTF_GetError );

  result := Mix_OpenAudio(44100 div 2, MIX_DEFAULT_FORMAT, 2, 2048);
  if result < 0 then
     raise SDLMixerException.Create( Mix_GetError );

  fText := TTextManager.Create( fRenderer );

  fFonts := TFonts.Create( fRenderer );
  fFonts.LoadFonts( FONTS_DIR );

  fSounds := TSoundManager.Create;
  fSounds.LoadSounds(SOUND_DIR);

end;

procedure TEngine.ToggleFullScreen;
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

procedure TEngine.ScreenShot;
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

constructor TEngine.Create;
begin
  Randomize;
  fFPSCounter := TFPSCounter.Create;
  fFPSCounter.OnNotify:= {$IFDEF FPC}@{$ENDIF}OnFPSCounterUpdated;
  fTextures := TTextureManager.Create;
  fRunning  := false;
end;

destructor TEngine.Destroy;
begin
  fFPSCounter.Free;
  fText.Free;
  fFonts.Free;
  fSounds.Free;
  SDL_DestroyRenderer(fRenderer);
  SDL_DestroyWindow(fWindow);
  IMG_Quit;
  Mix_Quit;
  SDL_Quit;
  inherited Destroy;
end;

procedure TEngine.SetActiveScene(scene: TScene);
begin
  fActiveScene:= scene;
  scene.Start;
end;

procedure TEngine.HideCursor;
begin
  SDL_ShowCursor(SDL_DISABLE);
end;

procedure TEngine.ShowCursor;
begin
  SDL_ShowCursor(SDL_ENABLE);
end;

procedure TEngine.Run;
var
  deltaTime : real;
  thisTime, lastTime : UInt32;
begin
  if fActiveScene = nil then
     raise EngineException.Create('There is no scene to proccess.');

  deltaTime := 0.0;
  thisTime  := 0;
  lastTime  := 0;
  fRunning  := true;
  while fRunning do
  begin
    thisTime  := SDL_GetTicks;
    deltaTime :=  ( (thisTime - lastTime) / MSecsPerSec);
    lastTime  := thisTime;

    doCheckDevices;
    doHandleEvents;
    doUpdate(deltaTime);
    doCheckCollisions;
    doRender;

    SDL_Delay(1);
  end;
end;

end.
