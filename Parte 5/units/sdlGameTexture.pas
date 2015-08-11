unit sdlGameTexture;

interface

uses
  fgl,
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

  TGTextureList = specialize TFPGObjectList<TTexture>;

  { TTextureManager }

  TTextureManager = class
  strict private
    fList : TGTextureList;
    function GetItems(i: integer): TTexture;
    procedure SetItems(i: integer; AValue: TTexture);

    function LoadPNGTexture( const fileName: string ) : TTexture;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Load(const AFileName: string);
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

function TTextureManager.LoadPNGTexture(const fileName: string): TTexture;
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

procedure TTextureManager.Load(const AFileName: string);
var
  texture: TTexture;
begin
  texture := LoadPNGTexture(AFileName);
  fList.Add(texture);
end;


{ TTexture }

procedure TTexture.Assign(pTexure: TTexture);
begin
  self.W    := pTexure.W;
  self.H    := pTexure.H;
  self.Data := pTexure.Data;
end;

end.
