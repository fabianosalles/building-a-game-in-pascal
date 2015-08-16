unit siGame;

{$mode objfpc}{$H+}

interface

uses
  sysutils,
  classes,

  sdlGame,
  scnIntro,
  sdlScene,
  scnGamePlay,
  sdlGamePlayer;

type

  { TSpaceInvadersGame }

  TSpaceInvadersGame = class(TGame)
  strict private
  const
    SCENE_INTRO     = 'intro';
    SCENE_GAME_PLAY = 'gamePlay';
    SCENE_MAIN_MENU = 'mainMenu';
  var
    fPlayer : TPlayer;
  private
    procedure CreateScenes;
    procedure doOnSceneQuit(sender : TObject);
  public
    constructor Create;
    destructor Destroy; override;
  end;


implementation

uses
  sdlEngine;


{ TSpaceInvadersGame }

procedure TSpaceInvadersGame.CreateScenes;
var
  gamePlay : TGamePlayScene;
  intro    : TIntroScene;
begin

  gamePlay := TGamePlayScene.Create(fPlayer);
  gamePlay.Name:= SCENE_GAME_PLAY;
  gamePlay.OnQuit := @doOnSceneQuit;
  Scenes.Add(gamePlay);

  intro := TIntroScene.Create;
  intro.Name := SCENE_INTRO;
  intro.OnQuit:= @doOnSceneQuit;
  Scenes.Add(intro);


  Scenes.Current := intro;
end;

procedure TSpaceInvadersGame.doOnSceneQuit(sender: TObject);
var
  next : TScene;
begin
  if ( sender is TIntroScene ) then
  begin
    next := Scenes.ByName(SCENE_GAME_PLAY);
    Scenes.Current := next;
  end;

  if next <> nil then
    TEngine.GetInstance.SetActiveScene(next);

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

