unit sdlGameObjects;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  SDL2,

  sdlGameTexture,
  sdlGameTypes,
  sdlEngine,

  sysutils,
  classes,
  {$IFDEF FPC}
  fgl,
  {$ELSE}
  Generics.Collections,
  {$ENDIF}
  math;

type
  { Forwards }

  TSprite       = class;
  TSpriteFrame  = class;
  TGameObject   = class;
  TShot         = class;
  TShotList     = class;
  TBunker       = class;


  { Events }

  TGameObjectNotifyEvent   = procedure(Sender: TGameObject) of object;
  TGameObjectCollisonEvent = procedure(Sender, Suspect: TGameObject; var StopChecking: boolean) of object;


  { TVector }

  TVector = class
  strict private
    fX : real;
    fY : real;
  public
    constructor Create; overload;
    constructor Create(const x, y : real); overload;
    procedure SetX(Value: real);
    procedure SetY(Value: real);

    property X: Real read fX write fX;
    property Y: Real read fY write fY;
  end;

  { TRange }
  {$IFDEF FPC}generic{$ENDIF} TRange<T> = class
  strict private
    fMin : T;
    fMax : T;
  public
    property Min : T read fMin write fMin;
    property Max : T read fMax write fMax;
  end;

  TRangeReal = {$IFDEF FPC}specialize{$ENDIF} TRange<Real>;


  TRect = class
  strict private
    fX : SInt32;
    fY : SInt32;
    fW : SInt32;
    fH : SInt32;
  public
    constructor Create; overload;
    constructor Create(x,y,w,h: SInt32); overload;

    function ToSDLRect : TSDL_Rect;
    procedure Assign(Value: TSDL_Rect);


    property X : SInt32 read fX write fX;
    property Y : SInt32 read fY write fY;
    property W : SInt32 read fW write fW;
    property H : SInt32 read fH write fH;

  end;


  TDrawMode = (
    Debug,
    Normal
  );

  { TSprite }

  TSpriteAnimationType = (
    NoLoop,
    Circular
  );


  TSprite = class
  strict private
  const
    DEFAULT_FRAME_DELAY = 500;
  var
    fFrames        : array of TSpriteFrame;
    fFrameIndex    : integer;
    fTexture       : TTexture;
    fAnimationType : TSpriteAnimationType;
    fTimeSinceIndexChange : real;
    procedure FreeFrames;
    function GetCurrentFrame: TSpriteFrame;
    function GetFrames(index: integer): TSpriteFrame;
  public
    constructor Create;
    destructor Destroy; override;

    procedure InitFrames(const pRows, pColumns: integer);
    procedure Update(const deltaTime: real);
    procedure AdvanceFrames(count: integer);

    property Texture: TTexture read fTexture write fTexture;
    property AnimationType: TSpriteAnimationType read fAnimationType write fAnimationType;
    property CurrentFrame: TSpriteFrame read GetCurrentFrame;
  end;

  { TSpriteFrame }

  TSpriteFrame = class
  public
    Rect      : TSDL_Rect;
    TimeSpan  : Cardinal; //em milisegundos
    function GetPositionedRect( position : TVector ) : TSDL_Rect; inline;
  end;

  {$IFDEF FPC}
  TGGameObjectList = specialize TFPGObjectList<TGameObject>;
  {$ELSE}
  TGGameObjectList = TObjectList<TGameObject>;
  {$ENDIF}


  { TGameObjectList }

  TGameObjectList = class (TGGameObjectList)
  public
    procedure Update(const deltaTime : real ); virtual;
    procedure Draw; virtual;
    procedure SetDrawMode( aDrawMode : TDrawMode);
  end;


  { TGameObject }

  PGameObject = ^TGameObject;
  TGameObject = class
  private
    function GetSpriteRect: TSDL_Rect;
  strict protected
    fRenderer   : PSDL_Renderer;
    fDrawMode   : TDrawMode;
    fOnCollided : TGameObjectCollisonEvent;
    fPosition   : TVector;
  protected
    fSprite     : TSprite;
    procedure InitFields; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Update(const deltaTime : real ); virtual; abstract;
    procedure Draw; virtual; abstract;
    procedure CheckCollisions( Suspects: TGameObjectList); overload;
    procedure CheckCollisions( Suspect: TGameObject ); overload;

    property Position : TVector read fPosition write fPosition;
    property DrawMode: TDrawMode read fDrawMode write fDrawMode;
    property Sprite : TSprite read fSprite;
    property SpriteRect : TSDL_Rect read GetSpriteRect;

    property OnCollided : TGameObjectCollisonEvent read fOnCollided write fOnCollided;
  end;



  { TShot }

  TShotDirection = (
    Up,
    Down
  );


  TShot = class ( TGameObject )
  strict private
    fDirection     : TShotDirection;
    fSpeed         : real;
    fVisible       : boolean;
  public
    constructor Create; override;
    procedure Draw; override;
    procedure Update(const deltaTime : real); override;

    function IsInsideScreen: boolean;

    property Direction : TShotDirection read fDirection write fDirection;
    property Speed     : real read fSpeed write fSpeed;
    property Visible   : boolean read fVisible;
  end;

  { TShotList }

  TShotList = class( TGameObjectList )
  public
    procedure Update(const deltaTime : real); override;
    function FilterByDirection( aDireciton: TShotDirection ) : TShotList;
  end;

  { TExplosion }

  TExplosion = class( TGameObject )
  strict private
  const
    LIFE_TIME   = 500;
    START_FADE  = 100;
  var
    fCreatedTicks: UInt32;
    fVisible : boolean;
    fOpacity: UInt8;
  protected
    procedure InitFields; override;
  public
    procedure Draw; override;
    procedure Update(const deltaTime : real); override;

    property Visible: boolean read fVisible;
  end;

  { TExplosionList }

  TExplosionList = class( TGameObjectList )
  public
    procedure Update(const deltaTime : real); override;
    procedure Draw; override;
  end;

  { TBunker }
  TBunker = class ( TGameObject )
  end;



implementation

{ TVector }

constructor TVector.Create;
begin
  X := 0;
  Y := 0;
end;

constructor TVector.Create(const x, y: real);
begin
  Self.X := x;
  Self.Y := y;
end;

procedure TVector.SetX(Value: real);
begin
  Self.X := Value;
end;

procedure TVector.SetY(Value: real);
begin
  Self.Y := Value;
end;


{ TExplosionList }

procedure TExplosionList.Update(const deltaTime: real);
var
  i : integer;
  s : TExplosion;
begin
  for i:= Pred(Self.Count) downto 0 do
  begin
      s := TExplosion(Self.Items[i]);
      s.Update( deltaTime );
      if not s.Visible then
      begin
        Self.Remove( s );
      end;
  end;
end;

procedure TExplosionList.Draw;
var
  i : integer;
  s : TExplosion;
begin
  for i:= Pred(Self.Count) downto 0 do
  begin
      s := TExplosion(Self.Items[i]);
      s.Draw;
  end;
end;



{ TExplosion }

procedure TExplosion.InitFields;
begin
  inherited InitFields;
  fVisible:= true;
  fCreatedTicks := SDL_GetTicks;
  fOpacity:= $FF;
end;

procedure TExplosion.Draw;
var
  destination : TSDL_Rect;
  frame       : TSpriteFrame;
begin
  if ( fSprite.Texture.Data <> nil ) and fVisible then
  begin
    frame := Self.Sprite.CurrentFrame;
    destination := frame.GetPositionedRect(self.Position);

    SDL_SetTextureColorMod( fSprite.Texture.Data,
                                       fOpacity,
                                       fOpacity,
                                       0);
    SDL_SetTextureAlphaMod( fSprite.Texture.Data, fOpacity);
    SDL_RenderCopy( fRenderer, fSprite.Texture.Data,
                    @frame.Rect,
                    @destination) ;

    if fDrawMode = TDrawMode.Debug then
    begin
      SDL_SetRenderDrawColor( fRenderer, 0, 255, 0, 255 );
      SDL_RenderDrawRect( fRenderer, @destination );
    end;
  end;

end;

procedure TExplosion.Update(const deltaTime: real);
var
  elapsed: UInt32;
  opacity : extended;
  fadeTime: integer;
begin
  if fVisible then
  begin
    elapsed := SDL_GetTicks - fCreatedTicks;
    if elapsed > START_FADE then
    begin
      elapsed := elapsed -START_FADE;
      fadeTime:= LIFE_TIME-START_FADE;
      opacity := 255 - ((elapsed  / fadeTime) * 255 );
      opacity:= Round(opacity);
      opacity:= Max(opacity, 0);
      opacity:= Min(255, opacity);

      fOpacity := Trunc(opacity);
      fVisible := elapsed < LIFE_TIME;
    end;
  end;
end;


{ TGameObjectList }

procedure TGameObjectList.Update(const deltaTime: real);
var
  i: integer;
begin
  for i:=0 to Pred(Self.Count) do
    Self.Items[i].Update( deltaTime );
end;

procedure TGameObjectList.Draw;
var
  i: integer;
begin
  for i:=0 to Pred(Self.Count) do
    Self.Items[i].Draw;
end;

procedure TGameObjectList.SetDrawMode(aDrawMode: TDrawMode);
var
  i: integer;
begin
  for i:=0 to Pred(Self.Count) do
    Self.Items[i].DrawMode := aDrawMode;
end;

{ TShotList }

procedure TShotList.Update(const deltaTime: real);
var
  i : integer;
begin
  inherited Update(deltaTime);
  for i:= Pred(Self.Count) downto 0 do
    if not TShot(Self.Items[i]).Visible then
      Self.Delete(i);
end;

function TShotList.FilterByDirection(aDireciton: TShotDirection): TShotList;
var
  i: integer;
  shot : TShot;
begin
  result := TShotList.Create( false );
  for i:=0 to Pred(Self.Count) do
    begin
      shot := TShot(Self.Items[i]);
    if (shot.Visible) and (shot.Direction = aDireciton) then
       result.Add( Self.Items[i] );
    end;
end;

{ TSpriteFrame }

function TSpriteFrame.GetPositionedRect(position : TVector): TSDL_Rect;
begin
  result.x := round(position.X);
  result.y := round(position.Y);
  result.h := self.Rect.h;
  result.w := self.Rect.w;
end;


{ TGameObject }

function TGameObject.GetSpriteRect: TSDL_Rect;
begin
  result := fSprite.CurrentFrame.GetPositionedRect( self.Position );
end;

procedure TGameObject.InitFields;
begin
  fPosition  := TVector.Create;
  fSprite    := TSprite.Create;
  fDrawMode  := TDrawMode.Normal;
end;

constructor TGameObject.Create;
begin
  fRenderer:= TEngine.GetInstance.Renderer;
  InitFields;
end;

destructor TGameObject.Destroy;
begin
  if Assigned(fSprite) then
     fSprite.Free;
  fPosition.Free;
  inherited Destroy;
end;


procedure TGameObject.CheckCollisions( Suspects: TGameObjectList );
var
  i              : integer;
  myRect         : TSDL_Rect;
  suspectRect    : TSDL_Rect;
  aStopCheckhing : boolean;
begin
  aStopCheckhing  := false;
  myRect := GetSpriteRect;
  for i:= 0 to Pred( Suspects.Count ) do
  begin
    suspectRect := Suspects[i].SpriteRect;
    if ( SDL_HasIntersection(@myRect, @suspectRect) ) = SDL_TRUE then
       if Assigned( fOnCollided ) then
       begin
         fOnCollided( self, Suspects[i], aStopCheckhing );
         if aStopCheckhing then
            break;
       end;
  end;

end;

procedure TGameObject.CheckCollisions(Suspect: TGameObject);
var
  myRect         : TSDL_Rect;
  suspectRect    : TSDL_Rect;
  aStopCheckhing : boolean;
begin
  myRect := GetSpriteRect;
  suspectRect := Suspect.SpriteRect;
    if ( SDL_HasIntersection(@myRect, @suspectRect) ) = SDL_TRUE then
       if Assigned( fOnCollided ) then
          fOnCollided( self, Suspect, aStopCheckhing );
end;



{ TSprite }

function TSprite.GetFrames(index: integer): TSpriteFrame;
begin
  if ( index > Length(fFrames)-1 ) or ( index < 0 ) then
     raise IndexOutOfBoundsException.Create(IntToStr(index));

  result := fFrames[ index ];
end;


function TSprite.GetCurrentFrame: TSpriteFrame;
begin
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

{ TShot }

constructor TShot.Create;
begin
  inherited;
  fSpeed     := 300.0;
  fDirection := TShotDirection.Up;
  fVisible   := true;
end;

procedure TShot.Draw;
var
  destination : TSDL_Rect;
  frame       : TSpriteFrame;
begin
  if ( fSprite.Texture.Data <> nil ) and fVisible then
  begin
    frame := Self.Sprite.CurrentFrame;

    destination.w := 6;
    destination.h := 12;
    destination.x := trunc(self.Position.X);
    destination.y := trunc(self.Position.Y);

    destination := frame.GetPositionedRect(self.Position);

    case fDirection of
     TShotDirection.Down : SDL_RenderCopy( fRenderer, fSprite.Texture.Data,
                                          @frame.Rect,
                                          @destination) ;

     TShotDirection.Up  : SDL_RenderCopyEx( fRenderer, fSprite.Texture.Data,
                                          @frame.Rect, @destination, 0, nil,
                                          SDL_FLIP_VERTICAL);

    end;


    if fDrawMode = TDrawMode.Debug then
    begin
      SDL_SetRenderDrawColor( fRenderer, 0, 255, 0, 255 );
      SDL_RenderDrawRect( fRenderer, @destination );
    end;
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
    fVisible := isInsideScreen;
  end;
end;

function TShot.isInsideScreen: boolean;
begin
  result := ( (  Position.Y >= -(fSprite.Texture.H+1)) and (Position.Y < SCREEN_HEIGHT+1) ) and
              ( (Position.X >= -(fSprite.Texture.W+1)) and (Position.X < SCREEN_WIDTH+1) );

end;






{ TRect }

procedure TRect.Assign(Value: TSDL_Rect);
begin
  fX := Value.x;
  fY := Value.y;
  fW := Value.w;
  fH := Value.h;
end;

constructor TRect.Create;
begin
  fX := 0;
  fY := 0;
  fW := 0;
  fH := 0;
end;

constructor TRect.Create(x, y, w, h: SInt32);
begin
  fX := x;
  fY := y;
  fW := w;
  fH := h;
end;


function TRect.ToSDLRect: TSDL_Rect;
begin
  result.x := x;
  result.y := y;
  result.w := w;
  result.h := h;
end;

end.



