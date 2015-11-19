unit siGame;

{$mode objfpc}{$H+}

interface

uses
  sysutils,
  classes,

  sdlGame,
  scnIntro,
  sdlScene,
  scnMainMenu,
  scnGamePlay,
  sdlGamePlayer;

type

  { TSpaceInvadersGame }

  TSpaceInvadersGame = class(TGame)
  strict private
    fSceneInto: integer;
    fSceneGamePLay: integer;
    fSceneMainMenu: integer;

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
  menu     : TMainMenuScene;
  intro    : TIntroScene;
begin
  gamePlay := TGamePlayScene.Create(fPlayer);
  gamePlay.OnQuit := @doOnSceneQuit;
  fSceneGamePLay:= Scenes.Add(gamePlay);


  intro := TIntroScene.Create;
  intro.OnQuit:= @doOnSceneQuit;
  fSceneInto:= Scenes.Add(intro);

  menu := TMainMenuScene.Create;
  menu.OnQuit:= @doOnSceneQuit;
  fSceneMainMenu:= Scenes.Add(menu);

  Scenes.Current := intro;
 // Scenes.Current := menu;
end;

procedure TSpaceInvadersGame.doOnSceneQuit(sender: TObject);
var
  next : TScene;
begin
  if ( sender is TIntroScene ) then
  begin
    TIntroScene(sender).Stop;
    next := Scenes[fSceneMainMenu];
    Scenes.Current := next;
  end;

  if ( sender is TMainMenuScene ) then
  begin
     TMainMenuScene(sender).Stop;
     next := Scenes[fSceneGamePLay];
     Scenes.Current := next;
  end;

  if next <> nil then
  begin
    TEngine.GetInstance.SetActiveScene(next);
    next.Start;
  end;

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

