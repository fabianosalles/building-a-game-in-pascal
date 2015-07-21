unit sdlGame;

{$mode objfpc}{$H+}

interface

uses
  sysutils,  classes,
  SDL2,
  sdl2_image;

type
  SDLException = class( Exception );
  SDLImageException = class( SDLException );
  IndexOutOfBoundsException = class( Exception );

  TFPSCounter = class;
  TGameObject = class;

  TFPSCounterEvent = procedure(Sender: TFPSCounter; Counted: word) of object;
  TGameObjectNotifyEvent = procedure(Sender: TGameObject) of object;

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

  TPoint = record
    X : real;
    Y : real;
  end;

  TTexture = class
    W : integer;
    H : integer;
    Data: PSDL_Texture;
    procedure Assign( pTexure: TTexture );
  end;

  { TGameObject }

  TGameObject = class
  strict protected
    fRenderer : PSDL_Renderer;
  public
    Position : TPoint;
    constructor Create( const aRenderer: PSDL_Renderer ); virtual;
    procedure Update(const deltaTime : real ); virtual; abstract;
    procedure Draw; virtual; abstract;
  end;

  TSpriteFrame = class
  public
    Rect      : TSDL_Rect;
    TimeSpan  : Cardinal; //em milisegundos
  end;

  TSpriteAnimationType = (
    NoLoop,
    Circular
  );

  { TSprite }

  TSprite = class
  strict private
  const
    DEFAULT_FRAME_DELAY = 500;
  var
    fTexture             : TTexture;
	fFrames              : array of TSpriteFrame;
    fFrameIndex          : integer;
    fAnimationType       : TSpriteAnimationType;
    fTimeSinceIndexChange : real;

    function GetCurrentFrame: TSpriteFrame;
    function GetFrameIndex: integer;
    function GetFrames(index: integer): TSpriteFrame;
    procedure FreeFrames;
	procedure AdvanceFrames(count: integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure InitFrames( const pRows, pColumns : integer );
    procedure Update(const deltaTime : real);

    property Texture: TTexture read fTexture write fTexture;
    property FrameIndex: integer read GetFrameIndex;
    property Frames[index: integer] : TSpriteFrame read GetFrames;
    property CurrentFrame : TSpriteFrame read GetCurrentFrame;
    property AnimationType : TSpriteAnimationType read fAnimationType write fAnimationType;
  end;

  { TPlayer }

  TPlayerInput = (
    Left,
    Right,
    Shot
  );

  { TShot }

  TShotDirection = (
    Up,
    Down
  );

  TShot = class ( TGameObject )
  private
    fDirection : TShotDirection;
    fSpeed : real;
	fVisible : boolean;
    fSprite : TSprite;
  public
    constructor Create(const aRenderer: PSDL_Renderer); override;
    destructor Destroy; override;
    procedure Draw; override;
    procedure Update(const deltaTime : real); override;

    property Sprite    : TSprite read fSprite write fSprite;
    property Direction : TShotDirection read fDirection write fDirection;
  	property Speed     : real read fSpeed write fSpeed;
    property Visible   : boolean read fVisible write fVisible;
  end;

  { TShotList }

  TShotList = class
  strict private
  const
    MAX_SHOTS = 64;
  var
    fShots : array[0..MAX_SHOTS-1] of TShot;
    function GetItems(index: integer): TShot;
  public
    constructor Create(const aRenderer: PSDL_Renderer; aTexture: TTexture);
    destructor Destroy; override;

    procedure Update(const deltaTime : real);
    procedure Draw;
    function NextIndexAvailable: integer;

    property Items[index: integer]: TShot read GetItems; default;
  end;

  TPlayer = class( TGameObject )
  private
  const
    DEFAULT_SPEED    = 200.0;
    DEFAULT_COOLDOWN = 500;
  var
    fSpeed    : real;
    fSprite   : TSprite;
    fCooldown : integer;
    fCooldownCounter : integer;
    fInput    : array[0..2] of boolean;
    fOnShotTriggered : TGameObjectNotifyEvent;
    function GetInput(index: integer): boolean;
    procedure SetInput(index: integer; AValue: boolean);
  public
    constructor Create(const aRenderer: PSDL_Renderer); override;
    destructor Destroy; override;
    procedure Draw; override;
    procedure Update(const deltaTime : real); override;

    property Input[index: integer] : boolean read GetInput write SetInput;
    property Sprite: TSprite read fSprite;
    property Speed : real read fSpeed write fSpeed;  //em pixels por segund
    property Cooldown: integer read fCooldown write fCooldown;
    property CooldownCounter: integer read fCooldownCounter;

    property OnShotTriggered : TGameObjectNotifyEvent read fOnShotTriggered write fOnShotTriggered;
  end;

  { TEnemy }

  TEnemy = class( TGameObject )
  private
    fSprite : TSprite;
  public
    HP : integer;
	constructor Create( const aRenderer: PSDL_Renderer ); override;
    destructor Destroy; override;
    procedure Update(const deltaTime : real); override;

    property Sprite: TSprite read fSprite;
  end;

  { TEnemyA }

  TEnemyA = class( TEnemy )
  public
    procedure Draw; override;
  end;

  { TFPSCounter }

  TFPSCounter = class
  strict private
    fCount     : integer;
    fLastTicks : UInt32;
    fOnNotify  : TFPSCounterEvent;
  public
    constructor Create;
    procedure Reset;
    procedure Increment;
    property Count: integer read fCount;

    property OnNotify: TFPSCounterEvent read fOnNotify write fOnNotify;
  end;


  { TGame }

  TGame = class
  strict private
  const
    WINDOW_TITLE = 'Delphi Games - Space Invaders';
  var
    fRunning        : boolean;
    fWindow         : PSDL_Window;
    fWindowSurface  : PSDL_Surface;
    fRenderer       : PSDL_Renderer;
    fFrameCounter   : TFPSCounter;
    fTextures       : array of TTexture;
    fEnemies        : array [0..19] of TEnemy;
    fPlayer			: TPlayer;
    fJoystick       : PSDL_Joystick;
    fShots          : TShotList;

    procedure Quit;
    procedure CheckDevices;
    procedure HandleEvents;
    procedure Render;
    procedure Update(const deltaTime : real);
    procedure LoadTextures;
    procedure FreeTextures;

    procedure CreateGameObjects;
    procedure DrawGameObjects;
    procedure DrawDebugInfo;
    procedure FreeGameObjects;
	procedure OnFPSCounterUpdated(Sender: TFPSCounter; Counted: word);

    function LoadPNGTexture( const fileName: string ) : TTexture;

    procedure doPlayer_OnShotTriggered(Sender: TGameObject);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Initialize;
    procedure Run;
    property Running: boolean read fRunning;
  end;


implementation

{ TShotList }

function TShotList.GetItems(index: integer): TShot;
begin
  if index > High(fShots) then
    raise IndexOutOfBoundsException.CreateFmt('TShotList.GetItems(%d)', [index]);
  result := fShots[index];
end;

constructor TShotList.Create(const aRenderer: PSDL_Renderer; aTexture: TTexture);
var
  i : integer;
begin
  for i:= 0 to MAX_SHOTS-1 do
  begin
     fShots[i] := TShot.Create( aRenderer );
     fShots[i].Visible:= false;
     fShots[i].Position.X := - 100;
     fShots[i].Position.Y := - 100;
     fShots[i].Speed := 250; //pixels por segundo
     fShots[i].Sprite.Texture.Assign(aTexture);
     fShots[i].Sprite.InitFrames(1,1);
  end;
end;

destructor TShotList.Destroy;
var
  i: integer;
begin
  for i:= 0 to MAX_SHOTS-1 do;
    fShots[i].Free;
end;

procedure TShotList.Update(const deltaTime: real);
var
  i: integer;
begin
  for i:= 0 to MAX_SHOTS-1 do
    fShots[i].Update(deltaTime);
  inherited;
end;

procedure TShotList.Draw;
var
  i: integer;
begin
  for i:= 0 to MAX_SHOTS-1 do
    fShots[i].Draw;
end;

function TShotList.NextIndexAvailable: integer;
var
  i: integer;
begin
  result := -1;
  for i:= 0 to MAX_SHOTS-1 do
    if not fShots[i].Visible then
    begin
      result := i;
      break;
    end;
end;

{ TShot }

constructor TShot.Create(const aRenderer: PSDL_Renderer);
begin
  inherited Create(aRenderer);
  fSpeed     := 300.0;
  fDirection := TShotDirection.Up;
  fVisible   := true;
  fSprite    := TSprite.Create;
end;

destructor TShot.Destroy;
begin
  fSprite.Free;
  inherited Destroy;
end;

procedure TShot.Draw;
var
  source, destination : TSDL_Rect;
begin
  if ( fSprite.Texture.Data <> nil ) and fVisible then
  begin
    source.x := 0;
    source.y := 0;
    source.w := 6;
    source.h := 12;

    destination.x := Round(self.Position.X);
    destination.y := Round(self.Position.Y);
    destination.w := 6;
    destination.h := 12;

    SDL_RenderCopy( fRenderer, fSprite.Texture.Data, @source, @destination) ;
  end;

end;

procedure TShot.Update(const deltaTime: real);
begin
  if fVisible then
  begin
    case fDirection of
      TShotDirection.Up   : Position.Y := Position.Y - (fSpeed * deltaTime );
      TShotDirection.Down : Position.Y := Position.Y + (fSpeed * deltaTime );
    end;
    fVisible := ( (Position.Y >= -(fSprite.Texture.H+1)) and (Position.Y < 600+1) ) and
                ( (Position.X >= -(fSprite.Texture.W+1)) and (Position.X < 800+1) );
  end;
end;

{ TPlayer }

function TPlayer.GetInput(index: integer): boolean;
begin
  if index > Length(fInput)-1 then
    raise IndexOutOfBoundsException.CreateFmt('TPlayer.GetInput(%d)', [index]);
  result := fInput[index];
end;

procedure TPlayer.SetInput(index: integer; AValue: boolean);
begin
  if index > Length(fInput)-1 then
    raise IndexOutOfBoundsException.CreateFmt('TPlayer.SetInput(%d)', [index]);
  fInput[index] := AValue;
end;

constructor TPlayer.Create(const aRenderer: PSDL_Renderer);
var
  i : integer;
begin
  inherited Create(aRenderer);
  fSprite   := TSprite.Create;
  fSpeed    := DEFAULT_SPEED;
  fCooldown := DEFAULT_COOLDOWN;
  fCooldownCounter:= 0;

  for i :=0 to High(fInput) do
     fInput[i] := false;
end;

destructor TPlayer.Destroy;
begin
  fSprite.Free;
  inherited Destroy;
end;

procedure TPlayer.Draw;
var
  source, destination : TSDL_Rect;
begin
  if ( fSprite.Texture.Data <> nil ) then
  begin
    source := Sprite.CurrentFrame.Rect;

    destination.x := Round(self.Position.X);
    destination.y := Round(self.Position.Y);
    destination.w := 26;
    destination.h := 16;

    SDL_RenderCopy( fRenderer, fSprite.Texture.Data, @source, @destination) ;
  end;
end;

procedure TPlayer.Update(const deltaTime: real);
begin
  if fInput[Ord(TPlayerInput.Left)] then
     Position.X:= Position.X - ( fSpeed * deltaTime );

  if fInput[Ord(TPlayerInput.Right)] then
     Position.X:= Position.X + ( fSpeed * deltaTime );

  if fCooldownCounter > 0 then
     dec(fCooldownCounter, round(deltaTime * MSecsPerSec));

  if ( (fInput[Ord(TPlayerInput.Shot)]) and ( fCooldownCounter <= 0) ) then
  begin
    if Assigned(fOnShotTriggered) then
       fOnShotTriggered(self);
    fCooldownCounter := fCooldown;
    fInput[Ord(TPlayerInput.Shot)] := false;
  end;

end;



{ TFPSCounter }

constructor TFPSCounter.Create;
begin
  Reset;
end;

procedure TFPSCounter.Reset;
begin
  fCount:= 0;
  fLastTicks:= SDL_GetTicks;
end;

procedure TFPSCounter.Increment;
var
  lCurrentTicks, lElapsed: UInt32;
begin
  Inc(fCount);
  lCurrentTicks := SDL_GetTicks;
  lElapsed := ( lCurrentTicks - fLastTicks );
  if ( lElapsed > 1000 ) then
  begin
    fLastTicks:= lCurrentTicks;
    if Assigned(fOnNotify) then
       fOnNotify(self, fCount);
    fCount:= 0;
  end;
end;

{ TTexture }

procedure TTexture.Assign(pTexure: TTexture);
begin
  self.W    := pTexure.W;
  self.H    := pTexure.H;
  self.Data := pTexure.Data;
end;

{ TEnemy }

constructor TEnemy.Create(const aRenderer: PSDL_Renderer);
begin
  inherited Create(aRenderer);
  fSprite        := TSprite.Create;
end;

destructor TEnemy.Destroy;
begin
  fSprite.Free;
  inherited Destroy;
end;

procedure TEnemy.Update(const deltaTime : real);
begin
  Sprite.Update(deltaTime);
end;


{ TSprite }

function TSprite.GetFrames(index: integer): TSpriteFrame;
begin
  if ( index > Length(fFrames)-1 ) or ( index < 0 ) then
     raise IndexOutOfBoundsException.Create(IntToStr(index));

  result := fFrames[ index ];
end;

function TSprite.GetFrameIndex: integer;
begin
  result := fFrameIndex;
end;

function TSprite.GetCurrentFrame: TSpriteFrame;
begin
  if ( (fFrameIndex < 0) or (fFrameIndex > High(fFrames)) ) then
    raise IndexOutOfBoundsException.Create('GetCurrentFrame');
  result := fFrames[fFrameIndex];
end;

procedure TSprite.FreeFrames;
var
  i: integer;
begin
  for i:= 0 to Length(fFrames)-1 do
    fFrames[i].Free;
  SetLength(fFrames, 0);
end;

constructor TSprite.Create;
begin
  fTexture    := TTexture.Create;
  fFrameIndex := 0;
  fAnimationType:= TSpriteAnimationType.Circular;
  fTimeSinceIndexChange := 0.0;
end;


destructor TSprite.Destroy;
begin
  FreeFrames;
  fTexture.Free;
end;

procedure TSprite.InitFrames(const pRows, pColumns: integer);
var
  lRow, lColumn, frameW, frameH, spriteCount, i : integer;
begin
  spriteCount := pRows * pColumns;
  frameW := fTexture.W div pColumns;
  frameH := fTexture.H div pRows;

  FreeFrames;
  SetLength(fFrames, spriteCount);

  i:= 0;
  for lRow := 0 to pRows-1 do
    for lColumn :=0 to pColumns-1 do
    begin
      fFrames[ i ] := TSpriteFrame.Create;
      fFrames[ i ].TimeSpan   := DEFAULT_FRAME_DELAY;
      fFrames[ i ].Rect.w := frameW;
      fFrames[ i ].Rect.h := frameH;
      fFrames[ i ].Rect.x := lColumn * frameW;
      fFrames[ i ].Rect.y := lRow * frameH;
      inc( i );
    end;
  fFrameIndex := 0;
  inherited;
end;

procedure TSprite.Update(const deltaTime: real);
var
  frameCount : UInt32;
  elapsedMS  : UInt32;
begin
  elapsedMS := trunc(( fTimeSinceIndexChange + deltaTime ) * MSecsPerSec );
  if ( elapsedMS >= fFrames[ fFrameIndex ].TimeSpan ) then
  begin
    frameCount := elapsedMS div fFrames[ fFrameIndex ].TimeSpan;
    AdvanceFrames( frameCount );
    fTimeSinceIndexChange := 0;
  end
  else
    fTimeSinceIndexChange := fTimeSinceIndexChange + deltaTime;
end;

procedure TSprite.AdvanceFrames(count: integer);
var
  framesLength : integer;
begin
  framesLength := Length(fFrames);
  case fAnimationType of
   TSpriteAnimationType.NoLoop:
     begin
       inc(fFrameIndex, count);
       if fFrameIndex > framesLength-1 then
          fFrameIndex := framesLength-1
       else
         if (fFrameIndex < 0) then
             fFrameIndex:= 0;
     end;

   TSpriteAnimationType.Circular :
     begin
       fFrameIndex := (fFrameIndex + count) mod framesLength;
     end;
  end;

end;


{ TEnemyA }

procedure TEnemyA.Draw;
var
  source, destination : TSDL_Rect;
begin
  if ( HP > 0 ) and ( fSprite.Texture.Data <> nil ) then
  begin
    source := Sprite.CurrentFrame.Rect;

    destination.x := Round(self.Position.X);
    destination.y := Round(self.Position.Y);
    destination.w := 16;
    destination.h := 16;

    SDL_RenderCopy( fRenderer, fSprite.Texture.Data, @source, @destination) ;
  end;
end;


{ TGameObject }

constructor TGameObject.Create(const aRenderer: PSDL_Renderer);
begin
  Position.X := 0;
  Position.Y := 0;
  fRenderer:= aRenderer;
end;



procedure TGame.Initialize;
var
  flags, result: integer;
begin
  if ( SDL_Init( SDL_INIT_VIDEO or SDL_INIT_TIMER or SDL_INIT_JOYSTICK ) <> 0 )then
  	 raise SDLException.Create(SDL_GetError);

  fWindow := SDL_CreateWindow( PAnsiChar( WINDOW_TITLE ),
                             SDL_WINDOWPOS_UNDEFINED,
                             SDL_WINDOWPOS_UNDEFINED,
                             800,
                             600,
                             SDL_WINDOW_SHOWN);
  if fWindow = nil then
     raise SDLException.Create(SDL_GetError);

  fWindowSurface := SDL_GetWindowSurface( fWindow );
  if fWindowSurface = nil then
     raise SDLException.Create(SDL_GetError);

  fRenderer := SDL_CreateRenderer(fWindow, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
  if fRenderer = nil then
     raise SDLException.Create(SDL_GetError);

  flags  := IMG_INIT_PNG;
  result := IMG_Init( flags );
  if ( ( result and flags ) <> flags ) then
     raise SDLImageException.Create( IMG_GetError );

  LoadTextures;
  CreateGameObjects;
end;

procedure TGame.Quit;
begin
  FreeGameObjects;
  FreeTextures;
  if fJoystick <> nil then
  begin
    SDL_JoystickClose(fJoystick);
    fJoystick:= nil;
  end;
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
          SDLK_ESCAPE: fRunning := false;

          SDLK_LEFT, SDLK_A  :
            fPlayer.Input[Ord(TPlayerInput.Left)] := true;

          SDLK_RIGHT, SDLK_D :
            fPlayer.Input[Ord(TPlayerInput.Right)]:= true;

          SDLK_SPACE : fPlayer.Input[Ord(TPlayerInput.Shot)] := true;
        end;

      SDL_KEYUP :
        case event.key.keysym.sym of
          SDLK_LEFT, SDLK_A  :
            fPlayer.Input[Ord(TPlayerInput.Left)] := false;

          SDLK_RIGHT, SDLK_D :
            fPlayer.Input[Ord(TPlayerInput.Right)]:= false;

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
            {
            //Y axis motion
            1 : begin
                  //não nos interessa neste game
                end;
            }
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

  SDL_RenderPresent( fRenderer );
  fFrameCounter.Increment;
end;

procedure TGame.Update(const deltaTime : real ) ;
var
  i: integer;
begin
  fPlayer.Update( deltaTime );
  for i:= 0 to High(fEnemies) do
      fEnemies[i].Update(deltaTime);
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

procedure TGame.CreateGameObjects;
var
  i : integer;
  enemy  : TEnemy;
begin
  for i:= 0 to High( fEnemies ) do begin
    enemy := TEnemyA.Create( fRenderer );
    enemy.HP:= 1;
    enemy.Position.X := 32 + (i * 32);
    enemy.Position.Y := 100;
    enemy.Sprite.Texture.Assign( fTextures[ integer(TSpriteKind.EnemyA) ] );
    enemy.Sprite.InitFrames(1, 2);
    fEnemies[ i ] := enemy;
  end;

  fPlayer := TPlayer.Create( fRenderer );
  fPlayer.Position.X := 400;
  fPlayer.Position.Y := 550;
  fPlayer.Sprite.Texture.Assign( fTextures[ integer(TSpriteKind.Player)] );
  fPlayer.Sprite.InitFrames(1,1);
  fPlayer.OnShotTriggered:= @doPlayer_OnShotTriggered;

  fShots := TShotList.Create( fRenderer, fTextures[ Ord(TSpriteKind.ShotA) ] );
end;

procedure TGame.DrawGameObjects;
var
  i: integer;
begin
  fPlayer.Draw;
  for i:= 0 to High( fEnemies ) do
    fEnemies[ i ].Draw;

  fShots.Draw;
end;

procedure TGame.DrawDebugInfo;
var
  source, dest : TSDL_Rect;
begin
  //desenha o led do sensor do controle
  source.y := 0;
  source.w := 16;
  source.h := 16;

  if SDL_NumJoysticks > 0 then
    source.x := 0
  else
    source.x := 16;

  dest.x := 10;
  dest.y := 10;
  dest.w := 16;
  dest.h := 16;

  SDL_RenderCopy( fRenderer, fTextures[Ord(TSpriteKind.Leds)].Data, @source, @dest);

end;

procedure TGame.FreeGameObjects;
var
  i: integer;
begin
  for i:= 0 to High( fEnemies ) do
    fEnemies[i].Free;
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

procedure TGame.doPlayer_OnShotTriggered(Sender: TGameObject);
var
  i : integer;
  p : TPlayer;
  shot : TShot;
begin
  Assert(Sender is TPlayer);

  i := fShots.NextIndexAvailable;
  if ( i >=0  ) then
  begin
    p := TPlayer(Sender);
    shot := fShots[i];
    shot.Position.X := p.Position.X + (p.Sprite.CurrentFrame.Rect.w div 2);
    shot.Position.Y := p.Position.Y;
    shot.Visible:= true;
  end;
end;

constructor TGame.Create;
begin
  fRunning  := false;
  fJoystick := nil;
  fFrameCounter := TFPSCounter.Create;
  fFrameCounter.OnNotify:= @OnFPSCounterUpdated;
end;

destructor TGame.Destroy;
begin
  Quit;
  fFrameCounter.Free;
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
    Render;

	SDL_Delay(1);
  end;
end;

end.

