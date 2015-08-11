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

  { TSIGame }

  TSIGame = class(TGame)
  strict private
    fPlayer : TPlayer;
  private
    procedure CreateScenes;
  public
    constructor Create;
    destructor Destroy; override;

  end;


implementation


{ TSIGame }

procedure TSIGame.CreateScenes;
var
  mainScene : TGamePlayScene;
begin
  mainScene := TGamePlayScene.Create(fPlayer);
  Scenes.Add(mainScene);
  Scenes.CurrentScene := mainScene;
end;

constructor TSIGame.Create;
begin
  inherited;
  fPlayer := TPlayer.Create;
  CreateScenes;
end;

destructor TSIGame.Destroy;
begin
  fPlayer.Free;
  inherited Destroy;
end;

end.

