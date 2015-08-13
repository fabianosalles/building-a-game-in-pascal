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
    fOnRender: TRenderEvent;
    fOnUpdate: TUpdateEvent;
    fOnKeyUp: TKeyboardEvent;
    fOnKeyDown: TKeyboardEvent;
    fOnJoyButtonUp: TJoyButtonEvent;
    fOnJoyButtonDown: TJoyButtonEvent;
    fOnJoyAxisMotion: TJoyAxisMotionEvent;
    fOnCheckCollisions: TEvent;
    fTJoyButtonEvent: TJoyButtonEvent;
  protected

    procedure doOnRender(renderer : PSDL_Renderer); virtual;
    procedure doOnUpdate(const deltaTime : real); virtual;
    procedure doOnKeyUp(key: TSDL_KeyCode); virtual;
    procedure doOnKeyDown(key: TSDL_KeyCode); virtual;
    procedure doOnJoyButtonUp(joystick: SInt32; button: UInt8); virtual;
    procedure doOnJoyButtonDown(joystick: SInt32; button: UInt8); virtual;
    procedure doOnJoyAxisMotion(axis: UInt8; value: SInt32); virtual;
    procedure doOnCheckCollitions; virtual;
    procedure WireUpEvents;

    procedure doLoadTextures; virtual abstract;
    procedure doFreeTextures; virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;

    property OnRender: TRenderEvent read fOnRender write fOnRender;
    property OnUpdate: TUpdateEvent read fOnUpdate write fOnUpdate;
    property OnKeyDown: TKeyboardEvent read fOnKeyDown write fOnKeyDown;
    property OnKeyUp: TKeyboardEvent read fOnKeyUp write fOnKeyUp;
    property OnJoyButtonUp: TJoyButtonEvent read fOnJoyButtonUp write fOnJoyButtonUp;
    property OnJoyButtonDown: TJoyButtonEvent read fTJoyButtonEvent write fTJoyButtonEvent;
    property OnJoyAxisMotion: TJoyAxisMotionEvent read fOnJoyAxisMotion write fOnJoyAxisMotion;
    property OnCheckCollisions: TEvent read fOnCheckCollisions write fOnCheckCollisions;
  end;


  TGSceneList = specialize TFPGObjectList<TScene>;

  { TSceneManager }

  TSceneManager = class
  strict private
    fCurrentScene: integer;
    fScenes: TGSceneList;
    function GetCurrentScene: TScene;
    procedure SetCurrentScene(AValue: TScene);
  public
    function Add(scene: TScene): integer;
    constructor Create;
    destructor Destroy; override;


    property Current: TScene read GetCurrentScene write SetCurrentScene;
  end;

implementation

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

constructor TScene.Create;
begin
  WireUpEvents;
  doLoadTextures;
end;

destructor TScene.Destroy;
begin
  doFreeTextures;
  inherited Destroy;
end;

{ TSceneManager }

function TSceneManager.GetCurrentScene: TScene;
begin
  result := fScenes[fCurrentScene];
end;

procedure TSceneManager.SetCurrentScene(AValue: TScene);
begin
  fCurrentScene:= fScenes.IndexOf(AValue);
end;

function TSceneManager.Add(scene: TScene): integer;
begin
  result := fScenes.Add(scene);
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
