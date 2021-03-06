unit sdlGame;

{$mode objfpc}{$H+}

interface

uses
  sysutils,
  SDL2,
  sdl2_image;

type
  SDLException = class( Exception );
  SDLImageException = class( SDLException );

  TSpriteKind = (
    EnemyA,
    EnemyB,
    EnemyC,
    EnemyD,
    Player,
    Bunker,
    Garbage,
    Explosion,
    ShotA
  );

  TPoint = record
    X : integer;
    Y : integer;
  end;

  { TGameObject }

  TGameObject = class
  protected
    fTexture  : PSDL_Texture;
    fRenderer : PSDL_Renderer;
  public
    Position : TPoint;
    constructor Create( const aRenderer: PSDL_Renderer );
    procedure Draw; virtual; abstract;
    procedure SetTexture( pTexture: PSDL_Texture );
  end;

  { TEnemy }

  TEnemy = class( TGameObject )
  public
    HP      : integer;
  end;

  { TEnemyA }

  TEnemyA = class( TEnemy )
  public
    procedure Draw; override;
  end;

  { TGame }

  TGame = class
  private
    fRunning        : boolean;
    fWindow         : PSDL_Window;
    fWindowSurface  : PSDL_Surface;
    fRenderer       : PSDL_Renderer;
    fSprites        : array of PSDL_Surface;
    fEnemies        : array [0..19] of TEnemy;

    procedure Quit;
    procedure HandleEvents;
    procedure Render;
    procedure LoadSprites;
    procedure FreeSprites;

    procedure CreateEnemies;
    procedure DrawEnemies;
    procedure FreeEnemies;

    function LoadPNG( const fileName: string ) : PSDL_Texture;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Initialize;
    procedure Run;
    property Running: boolean read fRunning;
  end;


implementation

{ TEnemyA }

procedure TEnemyA.Draw;
var
  source, destination : TSDL_Rect;
begin
  if ( HP > 0 ) and ( fTexture <> nil ) then
  begin
    source.x := 0;
    source.y := 0;
    source.w  := 16;
    source.h  := 16;

    destination.x := self.Position.X;
    destination.y := self.Position.Y;
    destination.w := 16;
    destination.h := 16;

    SDL_RenderCopy( fRenderer, fTexture, @source, @destination);
  end;
end;


{ TGameObject }

constructor TGameObject.Create(const aRenderer: PSDL_Renderer);
begin
  Position.X := 0;
  Position.Y := 0;
  fRenderer:= aRenderer;
end;

procedure TGameObject.SetTexture( pTexture: PSDL_Texture );
begin
  fTexture:= pTexture;
end;


procedure TGame.Initialize;
var
  flags, result: integer;
begin
  if ( SDL_Init( SDL_INIT_VIDEO ) <> 0 )then
  	 raise SDLException.Create(SDL_GetError);

  fWindow := SDL_CreateWindow( PAnsiChar( 'Delphi Games - Space Invaders' ),
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

  LoadSprites;
  CreateEnemies;
end;

procedure TGame.Quit;
begin
  FreeSprites;
  FreeEnemies;
  SDL_DestroyRenderer(fRenderer);
  SDL_DestroyWindow(fWindow);
  IMG_Quit;
  SDL_Quit;
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
        case
          event.key.keysym.sym of
              SDLK_ESCAPE: fRunning := false;
        end;
    end;
  end;
end;

procedure TGame.Render;
begin
  SDL_SetRenderDrawColor( fRenderer, 0, 0, 0, SDL_ALPHA_OPAQUE );
  SDL_RenderClear( fRenderer );

  DrawEnemies;

  SDL_RenderPresent( fRenderer );
end;

procedure TGame.LoadSprites;
begin
  SetLength(fSprites, Ord( High( TSpriteKind ) ) +1 );
  fSprites[ integer(TSpriteKind.EnemyA) ]   := LoadPNG( 'enemy_a.png' );
  fSprites[ integer(TSpriteKind.EnemyB) ]   := LoadPNG( 'enemy_b.png' );
  fSprites[ integer(TSpriteKind.EnemyC) ]   := LoadPNG( 'enemy_c.png' );
  fSprites[ integer(TSpriteKind.EnemyD) ]   := LoadPNG( 'enemy_d.png' );
  fSprites[ integer(TSpriteKind.Player) ]   := LoadPNG( 'player.png' );
  fSprites[ integer(TSpriteKind.Bunker) ]   := LoadPNG( 'bunker.png' );
  fSprites[ integer(TSpriteKind.Garbage)]   := LoadPNG( 'garbage.png' );
  fSprites[ integer(TSpriteKind.Explosion)] := LoadPNG( 'explosion.png' );
  fSprites[ integer(TSpriteKind.ShotA) ]    := LoadPNG( 'shot_a.png' );
end;

procedure TGame.FreeSprites;
var
  i: integer;
begin
  for i:= 0 to Length( fSprites )-1 do
  begin
	SDL_FreeSurface( fSprites[ i ] );
    fSprites[ i ] := nil;
  end;
end;

procedure TGame.CreateEnemies;
var
  i : integer;
  enemy : TEnemy;
begin
  for i:= 0 to High( fEnemies ) do begin
    enemy := TEnemyA.Create( fRenderer );
    enemy.HP:= 1;
    enemy.Position.X := 32 + (i * 32);
    enemy.Position.Y := 100;
    enemy.SetTexture( fSprites[ Ord(TSpriteKind.EnemyA) ] );
    fEnemies[ i ] := enemy;
  end;
end;

procedure TGame.DrawEnemies;
var
  i: integer;
begin
  for i:= 0 to High( fEnemies ) do
    fEnemies[ i ].Draw;
end;

procedure TGame.FreeEnemies;
var
  i: integer;
begin
  for i:= 0 to High( fEnemies ) do
    fEnemies[ i ].Free;
end;

function TGame.LoadPNG( const fileName: string ): PSDL_Texture;
const
  IMAGE_DIR = '.\assets\images\';
var
  temp : PSDL_Surface;
begin
  result := nil;
  try
    temp := IMG_Load( PAnsiChar( IMAGE_DIR + fileName ) );
    if ( temp = nil ) then
       raise SDLException.Create( SDL_GetError )
    else
      begin
        result := SDL_CreateTextureFromSurface( fRenderer, temp );
        if ( result = nil ) then
           raise SDLImageException.Create( IMG_GetError );
      end;
  finally
    SDL_FreeSurface( temp );
  end;
end;

constructor TGame.Create;
begin
  fRunning:= false;
end;

destructor TGame.Destroy;
begin
  Quit;
  inherited;
end;

procedure TGame.Run;
begin
  fRunning:= true;
  while fRunning do
  begin
    HandleEvents;
    Render;
  end;
end;

end.

