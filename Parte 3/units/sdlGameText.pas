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
    function IndexOf(const aText: string; aFont: TGameFont): integer; overload;
    function Add(const aText: string; aFont: TGameFont): integer;

    property Items[index: integer]: TGameFontTexture read GetItems; default;
    property Count : integer read fCount;
  end;


  { TGameFonts }

  TGameFonts = class
  strict private
    fDebugNormal : TGameFont;
    fDebugError  : TGameFont;
    fGUI         : TGameFont;
    fRenderer    : PSDL_Renderer;
  public
    constructor Create( const aRenderer: PSDL_Renderer );
    destructor Destroy; override;
    procedure LoadFonts(const aFontsDirectory: string);

    property DebugNormal : TGameFont read fDebugNormal;
    property DebugError : TGameFont read fDebugError;
    property GUI: TGameFont read fGUI write fGUI;
  end;


  { TGameTextManager }

  TGameTextManager = class
  strict private
    fRenderer  : PSDL_Renderer;
    fTextures  : TGameFontTextureList;
  public
    constructor Create( const aRenderer: PSDL_Renderer );
    destructor Destroy; override;
    procedure Draw( const aText : string; x, y : integer; aFont : TGameFont );
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

function TGameFontTextureList.IndexOf(const aText: string; aFont: TGameFont): integer;
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
  result := IndexOf( aText, aFont );
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

{ TGameTextManager }

constructor TGameTextManager.Create(const aRenderer: PSDL_Renderer);
begin
  fRenderer := aRenderer;
  fTextures := TGameFontTextureList.Create( aRenderer );
end;

destructor TGameTextManager.Destroy;
begin
  fTextures.Free;;
  inherited Destroy;
end;

procedure TGameTextManager.Draw(const aText: string; x, y: integer; aFont: TGameFont);
var
  i : integer;
  lSource, lDest : TSDL_Rect;
begin
  i := fTextures.IndexOf(aText, aFont);
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

{ TGameFonts }

constructor TGameFonts.Create( const aRenderer: PSDL_Renderer );
begin
  fRenderer    := aRenderer;
end;

destructor TGameFonts.Destroy;
begin
  fRenderer := nil;
  TTF_CloseFont( fDebugNormal.Font );
  TTF_CloseFont( fDebugError.Font );
  TTF_CloseFont( fGUI.Font );
  inherited;
end;

procedure TGameFonts.LoadFonts(const aFontsDirectory: string);
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
  fGUI.Color.r := $FF;
  fGUI.Color.g := $FF;
  fGUI.Color.b := 0;
  fGUI.Color.a := $FF;

  if fGUI.Font = nil then
     raise GameFontException.Create( TTF_GetError );

end;


end.

