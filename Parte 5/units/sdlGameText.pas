unit sdlGameText;

{$mode objfpc}{$H+}

interface

uses
 sysutils,
 SDL2,
 sdl2_ttf;

type

  GameFontException = class( Exception );

  { TGameFont }

  TGameFont = record
    FileName : string;
    Size     : byte;
    Color    : TSDL_Color;
    Font     : PTTF_Font;
  end;


  { TGameFontTexture }

  PGameFontTexture = ^TGameFontTexture;
  TGameFontTexture = record
    Text     : string;
    Font     : TGameFont;
    Textture : PSDL_Texture;
    Width    : integer;
    Hight    : integer;
  end;

  { TGameFontTextureList }

  TGameFontTextureList = class
  private
    fCount    : integer;
    fList     : array of TGameFontTexture;
    fRenderer : PSDL_Renderer;
    function GetItems(index: integer): TGameFontTexture;
  public
    constructor Create( const aRenderer: PSDL_Renderer; const capacity: integer = 512 );
    destructor Destroy; override;
    function IndexOf(const aText: string): integer; overload;
    function Add(const aText: string; aFont: TGameFont): integer;

    property Items[index: integer]: TGameFontTexture read GetItems; default;
    property Count : integer read fCount;
  end;


  { TFonts }

  TFonts = class
  strict private
    fDebugNormal : TGameFont;
    fDebugError  : TGameFont;
    fGUI         : TGameFont;
    fGUI64       : TGameFont;
    fMainMenu    : TGameFont;
    fRenderer    : PSDL_Renderer;
  public
    constructor Create( const aRenderer: PSDL_Renderer );
    destructor Destroy; override;
    procedure LoadFonts(const aFontsDirectory: string);

    property DebugNormal : TGameFont read fDebugNormal;
    property DebugError : TGameFont read fDebugError;
    property GUI: TGameFont read fGUI write fGUI;
    property GUI64 : TGameFont read fGUI64 write fGUI64;
    property MainMenu : TGameFont read fMainMenu write fMainMenu;
  end;


  { TTextManager }

  TTextManager = class
  strict private
    fRenderer  : PSDL_Renderer;
    fTextures  : TGameFontTextureList;
  public
    constructor Create( const aRenderer: PSDL_Renderer );
    destructor Destroy; override;
    procedure Draw( const aText : string; x, y : integer; aFont : TGameFont );
    procedure Draw( const aText : string; x, y : integer; aFont : TGameFont; alpha: UInt8 );
    procedure DrawModulated( const aText : string; x, y : integer; aFont : TGameFont; mr, mg, mb : UInt8 );
  end;

implementation

{ TGameFontTextureList }

function TGameFontTextureList.GetItems(index: integer): TGameFontTexture;
begin
  result := fList[ index ];
end;

constructor TGameFontTextureList.Create(const aRenderer: PSDL_Renderer; const capacity: integer);
begin
  SetLength(fList, capacity);
  fCount := 0;
  fRenderer := aRenderer;
end;

destructor TGameFontTextureList.Destroy;
var
  i: integer;
begin
  for i:=0 to fCount do
    SDL_DestroyTexture( fList[i].Textture );
  SetLength(fList, 0);
  inherited Destroy;
end;

function TGameFontTextureList.IndexOf(const aText: string): integer;
var
  i : integer;
begin
  i:= 0;
  result := -1;
  while ( i < fCount ) do
  begin
    if SameText(aText, fList[i].Text) then
    begin
      result := i;
      break;
    end;
    Inc( i );
  end;
end;

function TGameFontTextureList.Add(const aText: string; aFont: TGameFont): integer;
var
  lSurface    : PSDL_Surface;
begin
  result := IndexOf( aText );
  if (result < 0) then
  begin
    if ( fCount >= Length(fList)) then
       raise GameFontException.CreateFmt( 'Could not create texture for the text : %s', [aText] );

    lSurface := TTF_RenderText_Blended( aFont.Font, PAnsiChar(aText), aFont.Color);

    fList[fCount].Textture := SDL_CreateTextureFromSurface( fRenderer, lSurface );
    if fList[fCount].Textture = nil then
       raise GameFontException.Create( SDL_GetError );
    fList[fCount].Text := aText;
    fList[fCount].Font := aFont;
    fList[fCount].Width := lSurface^.w;
    fList[fCount].Hight := lSurface^.h;

    SDL_FreeSurface( lSurface );

    inc(fCount);
    result := fCount-1;
  end;
end;

{ TTextManager }

constructor TTextManager.Create(const aRenderer: PSDL_Renderer);
begin
  fRenderer := aRenderer;
  fTextures := TGameFontTextureList.Create( aRenderer );
end;

destructor TTextManager.Destroy;
begin
  fTextures.Free;;
  inherited Destroy;
end;

procedure TTextManager.Draw(const aText: string; x, y: integer; aFont: TGameFont);
var
  i : integer;
  lSource, lDest : TSDL_Rect;
begin
  i := fTextures.IndexOf(aText);
  if ( i < 0 ) then
     i := fTextures.Add(aText, aFont);

  lSource.x := 0;
  lSource.y := 0;
  lSource.w := fTextures[i].Width;
  lSource.h := fTextures[i].Hight;

  lDest.x := x;
  lDest.y := y;
  lDest.w := lSource.w;
  lDest.h := lSource.h;

  SDL_SetRenderDrawBlendMode( fRenderer, SDL_BLENDMODE_BLEND );
  SDL_RenderCopy( fRenderer, fTextures[i].Textture, @lSource, @lDest );
end;

procedure TTextManager.Draw(const aText: string; x, y: integer;
  aFont: TGameFont; alpha: UInt8);
var
  i : integer;
  lSource, lDest : TSDL_Rect;
begin
  i := fTextures.IndexOf(aText);
  if ( i < 0 ) then
     i := fTextures.Add(aText, aFont);

  lSource.x := 0;
  lSource.y := 0;
  lSource.w := fTextures[i].Width;
  lSource.h := fTextures[i].Hight;

  lDest.x := x;
  lDest.y := y;
  lDest.w := lSource.w;
  lDest.h := lSource.h;

  SDL_SetRenderDrawBlendMode( fRenderer, SDL_BLENDMODE_BLEND );
  SDL_SetTextureAlphaMod( fTextures[i].Textture, alpha );
  SDL_RenderCopy( fRenderer, fTextures[i].Textture, @lSource, @lDest );
end;

procedure TTextManager.DrawModulated(const aText: string; x, y: integer;
  aFont: TGameFont; mr, mg, mb: UInt8);
var
  i : integer;
  lSource, lDest : TSDL_Rect;
begin
  i := fTextures.IndexOf(aText);
  if ( i < 0 ) then
     i := fTextures.Add(aText, aFont);

  lSource.x := 0;
  lSource.y := 0;
  lSource.w := fTextures[i].Width;
  lSource.h := fTextures[i].Hight;

  lDest.x := x;
  lDest.y := y;
  lDest.w := lSource.w;
  lDest.h := lSource.h;

  SDL_SetRenderDrawBlendMode( fRenderer, SDL_BLENDMODE_BLEND );
  SDL_SetTextureColorMod(fTextures[i].Textture, mr, mg, mb);
  SDL_RenderCopy( fRenderer, fTextures[i].Textture, @lSource, @lDest );
end;

{ TFonts }

constructor TFonts.Create( const aRenderer: PSDL_Renderer );
begin
  fRenderer    := aRenderer;
end;

destructor TFonts.Destroy;
begin
  fRenderer := nil;
  TTF_CloseFont( fDebugNormal.Font );
  TTF_CloseFont( fDebugError.Font );
  TTF_CloseFont( fGUI.Font );
  inherited;
end;

procedure TFonts.LoadFonts(const aFontsDirectory: string);
begin
  fDebugNormal.Color.r := 255;
  fDebugNormal.Color.g := 255;
  fDebugNormal.Color.b := 255;
  fDebugNormal.Color.a := 255;

  fDebugNormal.FileName := aFontsDirectory + 'Consolas.ttf';
  fDebugNormal.Size     := 12;
  fDebugNormal.Font     := TTF_OpenFont( PAnsiChar(fDebugNormal.FileName), fDebugNormal.Size);
  if fDebugNormal.Font = nil then
     raise GameFontException.Create( TTF_GetError );

  fDebugError.Color.r := 255;
  fDebugError.Color.g := 0;
  fDebugError.Color.b := 0;
  fDebugError.Color.a := 255;

  fDebugError.FileName := aFontsDirectory + 'Consolas.ttf';
  fDebugError.Size     := 12;
  fDebugError.Font     := TTF_OpenFont( PAnsiChar(fDebugError.FileName), fDebugError.Size);
  if fDebugError.Font = nil then
     raise GameFontException.Create( TTF_GetError );

  fGUI.FileName := aFontsDirectory + 'Arcade.ttf';
  fGUI.Size     := 32;
  fGUI.Font     := TTF_OpenFont( PAnsiChar(fGUI.FileName), fGUI.Size);
  fGUI.Color.r  := $FF;
  fGUI.Color.g  := $FF;
  fGUI.Color.b  := 0;
  fGUI.Color.a  := $FF;

  if fGUI.Font = nil then
     raise GameFontException.Create( TTF_GetError );

  fGUI64.FileName := aFontsDirectory + 'Arcade.ttf';
  fGUI64.Size     := 64;
  fGUI64.Font     := TTF_OpenFont( PAnsiChar(fGUI64.FileName), fGUI64.Size);
  fGUI64.Color.r  := $FF;
  fGUI64.Color.g  := $FF;
  fGUI64.Color.b  := $FF;
  fGUI64.Color.a  := $FF;

  if fGUI64.Font = nil then
     raise GameFontException.Create( TTF_GetError );

  fMainMenu.FileName := aFontsDirectory + 'Arcade.ttf';
  fMainMenu.Size     := 28;
  fMainMenu.Font     := TTF_OpenFont( PAnsiChar(fGUI.FileName), fGUI.Size);
  fMainMenu.Color.r  := $FF;
  fMainMenu.Color.g  := $FF;
  fMainMenu.Color.b  := $FF;
  fMainMenu.Color.a  := $FF;
  if  fMainMenu.Font = nil then
     raise GameFontException.Create( TTF_GetError );


end;


end.

