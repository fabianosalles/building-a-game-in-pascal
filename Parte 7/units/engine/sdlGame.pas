unit sdlGame;

interface

uses
  sdlScene;

type

  { TGame }

  TGame = class
  strict private
    fSceneManager : TSceneManager;
  public
    constructor Create;
    destructor Destroy; override;

    property Scenes : TSceneManager read fSceneManager write fSceneManager;
  end;

implementation

{ TGame }

constructor TGame.Create;
begin
  fSceneManager := TSceneManager.Create;
end;

destructor TGame.Destroy;
begin
  fSceneManager.Free;
  inherited Destroy;
end;

end.
