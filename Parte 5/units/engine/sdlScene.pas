unit sdlScene;

interface

uses
  fgl,
  SDL2,
  sdlGameTypes;

type
  PScene = ^TScene;

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
    fOnQuit: TNotifyEvent;
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

    procedure doLoadTextures; virtual;
    procedure doFreeTextures; virtual;
    procedure doBeforeStart; virtual;
    procedure doQuit;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start;
    procedure Stop;

    property Name: string read fName write fName;

    property OnRender: TRenderEvent read fOnRender write fOnRender;
    property OnUpdate: TUpdateEvent read fOnUpdate write fOnUpdate;
    property OnKeyDown: TKeyboardEvent read fOnKeyDown write fOnKeyDown;
    property OnKeyUp: TKeyboardEvent read fOnKeyUp write fOnKeyUp;
    property OnJoyButtonUp: TJoyButtonEvent read fOnJoyButtonUp write fOnJoyButtonUp;
    property OnJoyButtonDown: TJoyButtonEvent read fTJoyButtonEvent write fTJoyButtonEvent;
    property OnJoyAxisMotion: TJoyAxisMotionEvent read fOnJoyAxisMotion write fOnJoyAxisMotion;
    property OnCheckCollisions: TEvent read fOnCheckCollisions write fOnCheckCollisions;

    property OnQuit: TNotifyEvent read fOnQuit write fOnQuit;
  end;


  TGSceneList = specialize TFPGObjectList<TScene>;
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
begin

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
  fOnRender          := @doOnRender;
  fOnUpdate          := @doOnUpdate;
  fOnKeyUp           := @doOnKeyUp;
  fOnKeyDown         := @doOnKeyDown;
  fOnJoyButtonDown   := @doOnJoyButtonDown;
  fOnJoyButtonUp     := @doOnJoyButtonUp;
  fOnJoyAxisMotion   := @doOnJoyAxisMotion;
  fOnCheckCollisions := @doOnCheckCollitions;
end;

procedure TScene.doLoadTextures;
begin

end;

procedure TScene.doFreeTextures;
begin
  TEngine.GetInstance.Textures.Clear;
end;

procedure TScene.doBeforeStart;
begin
  doLoadTextures;
end;

procedure TScene.doQuit;
begin
  fQuitting:= true;
  if Assigned(fOnQuit) then
     fOnQuit(self);
end;

constructor TScene.Create;
begin
  fQuitting:= false;
  WireUpEvents;
end;

destructor TScene.Destroy;
begin
  doFreeTextures;
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
