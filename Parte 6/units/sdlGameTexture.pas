unit sdlGameTexture;

interface

uses
{$IFDEF FPC}
  fgl,
{$ELSE}
  Generics.Collections,
{$ENDIF}
  SDL2,
  sdl2_image;

type

  { TTexture }

  TTexture = class
    W : integer;
    H : integer;
    Data: PSDL_Texture;
    procedure Assign( pTexure: TTexture );
  end;

  {$IFDEF FPC}
  TGTextureList = specialize TFPGObjectList<TTexture>;
  {$ELSE}
  TGTextureList = TObjectList<TTexture>;
  {$ENDIF}

  { TTextureManager }

  TTextureManager = class
  strict private
    fList : TGTextureList;
    function GetItems(i: integer): TTexture;
    procedure SetItems(i: integer; AValue: TTexture);

    function LoadPNGTexture( const fileName: AnsiString ) : TTexture;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Load(const AFileName: string): integer;
    property Items[i: integer] : TTexture read GetItems write SetItems; default;
  end;


implementation

uses
  sdlEngine,
  sdlGameTypes;

{ TTextureManager }

function TTextureManager.GetItems(i: integer): TTexture;
begin
  result := fList.Items[i];
end;

procedure TTextureManager.SetItems(i: integer; AValue: TTexture);
begin
  fList.Items[i] := AValue;
end;

function TTextureManager.LoadPNGTexture(const fileName: AnsiString): TTexture;
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
        result.Data := SDL_CreateTextureFromSurface( TEngine.GetInstance.Renderer, temp );
        if ( result.Data = nil ) then
           raise SDLImageException.Create( IMG_GetError );
      end;
  finally
    SDL_FreeSurface( temp );
  end;

end;

constructor TTextureManager.Create;
begin
  fList := TGTextureList.Create;
end;

destructor TTextureManager.Destroy;
begin
  fList.Free;
  inherited Destroy;
end;

procedure TTextureManager.Clear;
begin
  fList.Clear;
end;

function TTextureManager.Load(const AFileName: string): integer;
var
  texture: TTexture;
begin
  texture := LoadPNGTexture(AFileName);
  result := fList.Add(texture);
end;


{ TTexture }

procedure TTexture.Assign(pTexure: TTexture);
begin
  self.W    := pTexure.W;
  self.H    := pTexure.H;
  self.Data := pTexure.Data;
end;

end.
