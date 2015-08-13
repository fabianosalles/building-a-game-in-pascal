unit siGame;

{$mode objfpc}{$H+}

interface

uses
  sysutils,
  classes,

  sdlGame,
  scnGamePlay,
  sdlGamePlayer;

type

  { TSpaceInvadersGame }

  TSpaceInvadersGame = class(TGame)
  strict private
    fPlayer : TPlayer;
  private
    procedure CreateScenes;
  public
    constructor Create;
    destructor Destroy; override;
  end;


implementation


{ TSpaceInvadersGame }

procedure TSpaceInvadersGame.CreateScenes;
var
  mainScene : TGamePlayScene;
begin
  mainScene := TGamePlayScene.Create(fPlayer);
  Scenes.Add(mainScene);
  Scenes.Current := mainScene;
end;

constructor TSpaceInvadersGame.Create;
begin
  inherited;
  fPlayer := TPlayer.Create;
  CreateScenes;
end;

destructor TSpaceInvadersGame.Destroy;
begin
  fPlayer.Free;
  inherited Destroy;
end;

end.

