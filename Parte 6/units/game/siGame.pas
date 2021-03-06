unit siGame;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}


interface

uses
  sysutils,
  classes,

  sdlGame,
  scnIntro,
  sdlScene,
  scnMainMenu,
  scnGamePlay,
  scnParticles,
  sdlGamePlayer;

type

  { TSpaceInvadersGame }

  TSpaceInvadersGame = class(TGame)
  strict private
  const
    SCENE_INTRO         = 'intro';
    SCENE_GAME_PLAY     = 'gamePlay';
    SCENE_MAIN_MENU     = 'mainMenu';
    SCENE_MAIN_PARTICLE = 'particle';
  var
    fSceneInto: integer;
    fSceneGamePLay: integer;
    fSceneMainMenu: integer;
    fSceneParticle: integer;
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
  gamePlay  : TGamePlayScene;
  menu      : TMainMenuScene;
  intro     : TIntroScene;
  particles : TParticleScene;
begin
  gamePlay := TGamePlayScene.Create(fPlayer);

  gamePlay.Name:= SCENE_GAME_PLAY;
  Scenes.Add(gamePlay);

  intro := TIntroScene.Create;
  intro.Name := SCENE_INTRO;
  Scenes.Add(intro);


  menu := TMainMenuScene.Create;
  menu.Name:= SCENE_MAIN_MENU;
  Scenes.Add(menu);


  particles := TParticleScene.Create;
  particles.Name := SCENE_MAIN_PARTICLE;
  Scenes.Add(particles);

  {$IFDEF FPC}
  gamePlay.OnQuit  := @doOnSceneQuit;
  intro.OnQuit     := @doOnSceneQuit;
  menu.OnQuit      := @doOnSceneQuit;
  particles.OnQuit := @doOnSceneQuit;
  {$ELSE}
  gamePlay.OnQuit  := doOnSceneQuit;
  intro.OnQuit     := doOnSceneQuit;
  menu.OnQuit      := doOnSceneQuit;
  particles.OnQuit := doOnSceneQuit;
  {$ENDIF}

  Scenes.Current := gamePlay;
  //Scenes.Current := particles;
end;

procedure TSpaceInvadersGame.doOnSceneQuit(sender: TObject);
var
  next : TScene;
begin
  if ( sender is TIntroScene ) then
  begin
    TIntroScene(sender).Stop;
    next := Scenes.ByName(SCENE_MAIN_MENU);
    Scenes.Current := next;
  end;

  if ( sender is TMainMenuScene ) then
  begin
     TMainMenuScene(sender).Stop;
     next := Scenes.ByName(SCENE_GAME_PLAY);
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

