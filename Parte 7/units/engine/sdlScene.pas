unit sdlScene;

interface

uses
{$IFDEF FPC}
  fgl,
{$ELSE}
   Generics.Collections,
{$ENDIF}
  SDL2,
  sdlGameTypes;

type
  PScene = ^TScene;
  TScene = class;
  TQuitType = (
    qtQuitCurrentScene,
    qtQuitGame
  );
  TSceneQuitEvent = procedure(sender: TScene; quitType: TQuitType; exitCode: integer) of object;
  TSceneMethod = procedure of object;
  TMethodSchedule = record
    when    : UInt32;
    method  : TSceneMethod;
  end;
  TProcSchedlue = TList<TMethodSchedule>;

  { TScene }

  TScene = class
  strict private
    fName: string;
    fOnRender: TRenderEvent;
    fOnUpdate: TUpdateEvent;
    fOnKeyUp: TKeyboardEvent;
    fOnKeyDown: TKeyboardEvent;
    fOnJoyButtonUp: TJoyButtonEvent;
    fOnJoyButtonDown: TJoyButtonEvent;
    fOnJoyAxisMotion: TJoyAxisMotionEvent;
    fOnCheckCollisions: TEvent;
    fTJoyButtonEvent: TJoyButtonEvent;
    fOnQuit: TSceneQuitEvent;
    fMethods : TProcSchedlue;
  protected
    fQuitting : boolean;

    procedure doOnRender(renderer : PSDL_Renderer); virtual;
    procedure doOnUpdate(const deltaTime : real); virtual;
    procedure doOnKeyUp(key: TSDL_KeyCode); virtual;
    procedure doOnKeyDown(key: TSDL_KeyCode); virtual;
    procedure doOnJoyButtonUp(joystick: SInt32; button: UInt8); virtual;
    procedure doOnJoyButtonDown(joystick: SInt32; button: UInt8); virtual;
    procedure doOnJoyAxisMotion(axis: UInt8; value: SInt32); virtual;
    procedure doOnCheckCollitions; virtual;
    procedure WireUpEvents;

    procedure doLoadSounds; virtual;
    procedure doFreeSounds; virtual;
    procedure doLoadTextures; virtual;
    procedure doFreeTextures; virtual;
    procedure doBeforeStart; virtual;
    procedure doBeforeQuit; virtual;
    procedure doQuit(quitType: TQuitType; exitCode: integer); overload;
    procedure doQuit; overload;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Start;
    procedure Stop;
    procedure ExecuteDelayed(const delay: UInt32; method: TSceneMethod);

    property Name: string read fName write fName;

    property OnRender: TRenderEvent read fOnRender write fOnRender;
    property OnUpdate: TUpdateEvent read fOnUpdate write fOnUpdate;
    property OnKeyDown: TKeyboardEvent read fOnKeyDown write fOnKeyDown;
    property OnKeyUp: TKeyboardEvent read fOnKeyUp write fOnKeyUp;
    property OnJoyButtonUp: TJoyButtonEvent read fOnJoyButtonUp write fOnJoyButtonUp;
    property OnJoyButtonDown: TJoyButtonEvent read fTJoyButtonEvent write fTJoyButtonEvent;
    property OnJoyAxisMotion: TJoyAxisMotionEvent read fOnJoyAxisMotion write fOnJoyAxisMotion;
    property OnCheckCollisions: TEvent read fOnCheckCollisions write fOnCheckCollisions;

    property OnQuit: TSceneQuitEvent read fOnQuit write fOnQuit;
  end;


  {$IFDEF FPC}
  TGSceneList = specialize TFPGObjectList<TScene>;
  {$ELSE}
  TGSceneList = TObjectList<TScene>;
  {$ENDIF}

  { TSceneManager }

  TSceneManager = class
  strict private
    fCurrentScene: integer;
    fScenes: TGSceneList;
    function GetCurrentScene: TScene;
    function GetScene(index: integer): TScene;
    procedure SetCurrentScene(AValue: TScene);
  public
    function Add(scene: TScene): integer;
    function ByName(const name: string): TScene;
    constructor Create;
    destructor Destroy; override;

    property Items[index:integer]:TScene read GetScene; default;
    property Current: TScene read GetCurrentScene write SetCurrentScene;
  end;

implementation

uses
  sdlEngine;

{ TScene }

procedure TScene.doOnRender(renderer : PSDL_Renderer);
begin

end;

procedure TScene.doOnUpdate(const deltaTime: real);
var
  x, i : UInt32;
begin
  if (fMethods.Count > 0) then begin
    x := SDL_GetTicks;
    for i := fMethods.Count-1 downto 0 do
      if fMethods[i].when <= x then
      begin
        fMethods[i].method();
        fMethods.Delete(i);
      end;
  end;
end;

procedure TScene.doQuit;
begin
  fQuitting:= true;
  doBeforeQuit;

  if Assigned(fOnQuit) then
     fOnQuit(self, qtQuitCurrentScene, 0);
end;

procedure TScene.ExecuteDelayed(const delay: UInt32; method: TSceneMethod);
var
  schedule : TMethodSchedule;
begin
  schedule.when := SDL_GetTicks + delay;
  schedule.method := method;
  fMethods.Add(schedule);
end;

procedure TScene.doOnKeyUp(key: TSDL_KeyCode);
begin

end;

procedure TScene.doOnKeyDown(key: TSDL_KeyCode);
begin

end;

procedure TScene.doOnJoyButtonUp(joystick: SInt32; button: UInt8);
begin

end;

procedure TScene.doOnJoyButtonDown(joystick: SInt32; button: UInt8);
begin

end;

procedure TScene.doOnJoyAxisMotion(axis: UInt8; value: SInt32);
begin

end;

procedure TScene.doOnCheckCollitions;
begin

end;

procedure TScene.WireUpEvents;
begin
{$IFDEF FPC}
  fOnRender          := @doOnRender;
  fOnUpdate          := @doOnUpdate;
  fOnKeyUp           := @doOnKeyUp;
  fOnKeyDown         := @doOnKeyDown;
  fOnJoyButtonDown   := @doOnJoyButtonDown;
  fOnJoyButtonUp     := @doOnJoyButtonUp;
  fOnJoyAxisMotion   := @doOnJoyAxisMotion;
  fOnCheckCollisions := @doOnCheckCollitions;
  fOnUpdate          := @doOnUpdate;
{$ELSE}
  fOnRender          := doOnRender;
  fOnUpdate          := doOnUpdate;
  fOnKeyUp           := doOnKeyUp;
  fOnKeyDown         := doOnKeyDown;
  fOnJoyButtonDown   := doOnJoyButtonDown;
  fOnJoyButtonUp     := doOnJoyButtonUp;
  fOnJoyAxisMotion   := doOnJoyAxisMotion;
  fOnCheckCollisions := doOnCheckCollitions;
  fOnUpdate          := doOnUpdate;
{$ENDIF}
end;

procedure TScene.doLoadSounds;
begin

end;

procedure TScene.doLoadTextures;
begin

end;

procedure TScene.doFreeSounds;
begin

end;

procedure TScene.doFreeTextures;
begin
  TEngine.GetInstance.Textures.Clear;
end;

procedure TScene.doBeforeQuit;
begin

end;

procedure TScene.doBeforeStart;
begin
  doLoadTextures;
  doLoadSounds;
end;

procedure TScene.doQuit(quitType: TQuitType; exitCode: integer);
begin
  fQuitting:= true;
  doBeforeQuit;
  if Assigned(fOnQuit) then
     fOnQuit(self, quitType, exitCode);
end;

constructor TScene.Create;
begin
  fQuitting:= false;
  fMethods := TProcSchedlue.Create;
  WireUpEvents;
end;

destructor TScene.Destroy;
begin
  doFreeTextures;
  doFreeSounds;
  fMethods.Clear;
  fMethods.free;
  inherited;
end;

procedure TScene.Start;
begin
  doBeforeStart;
end;

procedure TScene.Stop;
begin

end;

{ TSceneManager }

function TSceneManager.GetCurrentScene: TScene;
begin
  result := fScenes[fCurrentScene];
end;

function TSceneManager.GetScene(index: integer): TScene;
begin
  result := fScenes[index];
end;

procedure TSceneManager.SetCurrentScene(AValue: TScene);
begin
  fCurrentScene:= fScenes.IndexOf(AValue);
end;

function TSceneManager.Add(scene: TScene): integer;
begin
  result := fScenes.Add(scene);
end;

function TSceneManager.ByName(const name: string): TScene;
var
  i : integer;
begin
  result := nil;
  for i:=0 to Pred(fScenes.Count) do
   if fScenes[i].Name = name then
      begin
        result := fScenes[i];
        break;
      end;
end;

constructor TSceneManager.Create;
begin
  fScenes := TGSceneList.Create;
end;

destructor TSceneManager.Destroy;
begin
  fScenes.Free;
  inherited Destroy;
end;

end.
