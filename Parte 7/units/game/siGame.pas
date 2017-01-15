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
    fSceneInto     : integer;
    fSceneGamePLay : integer;
    fSceneMainMenu : integer;
    fSceneParticle : integer;
    fPlayer : TPlayer;
  private
    procedure CreateScenes;
    procedure Stop;
    procedure doOnSceneQuit(sender: TScene; quitType: TQuitType; exitCode: integer);
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

  {$IFDEF DEBUG}
  Scenes.Current := menu;
//  Scenes.Current := gamePlay;
  //Scenes.Current := particles;
  {$ELSE}
  Scenes.Current := intro;
  {$ENDIF}

end;

procedure TSpaceInvadersGame.doOnSceneQuit(sender: TScene; quitType: TQuitType; exitCode: integer);
var
  next : TScene;
begin

  case quitType of
    qtQuitCurrentScene :
      begin
        if ( sender is TIntroScene ) then
        begin
          TIntroScene(sender).Stop;
          next := Scenes.ByName(SCENE_MAIN_MENU);
        end;

        if ( sender is TMainMenuScene ) then
        begin
           TMainMenuScene(sender).Stop;
           case exitCode of
             0,1 : next := Scenes.ByName(SCENE_GAME_PLAY);
             //1 : next := Scenes.ByName(SCENE_GAME_PLAY); //high score
           end;
        end;

        if ( sender is TGamePlayScene) then
        begin
          case scnGamePlay.TMenuOption(exitCode) of
            scnGamePlay.TMenuOption.moQuit: next := Scenes.ByName(SCENE_MAIN_MENU);
          end;
        end;

        if next <> nil then
        begin
          Scenes.Current := next;
          TEngine.GetInstance.SetActiveScene(next);
          next.Start;
        end;

      end;

    qtQuitGame:
      begin
        sender.Stop;
        Scenes.Current.Stop;
        Self.Stop;
      end;
  end;
end;

procedure TSpaceInvadersGame.Stop;
begin
  TEngine.GetInstance.Stop;
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

