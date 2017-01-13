program space_invaders;

(*
{$IFDEF DEBUG}
  {$APPTYPE CONSOLE}
  {$DEFINE CONSOLE}
{$ELSE}
  {$APPTYPE GUI}
{$ENDIF}
*)

{$APPTYPE GUI}

uses
  sdlGameEnemies in '..\..\units\sdlGameEnemies.pas',
  sdlGamePlayer in '..\..\units\sdlGamePlayer.pas',
  sdlGameSound in '..\..\units\sdlGameSound.pas',
  sdlGameText in '..\..\units\sdlGameText.pas',
  sdlGameTexture in '..\..\units\sdlGameTexture.pas',
  sdlGameTypes in '..\..\units\sdlGameTypes.pas',
  sdlGameUtils in '..\..\units\sdlGameUtils.pas',
  sdlGame in '..\..\units\engine\sdlGame.pas',
  sdlParticles in '..\..\units\engine\sdlParticles.pas',
  sdlScene in '..\..\units\engine\sdlScene.pas',
  Shots in '..\..\units\game\objects\Shots.pas',
  sdlGameObjects in '..\..\units\engine\sdlGameObjects.pas',
  scnGamePlay in '..\..\units\game\scenes\scnGamePlay.pas',
  scnIntro in '..\..\units\game\scenes\scnIntro.pas',
  scnMainMenu in '..\..\units\game\scenes\scnMainMenu.pas',
  scnParticles in '..\..\units\game\scenes\scnParticles.pas',
  sdlEngine in '..\..\units\engine\sdlEngine.pas',
  siGame in '..\..\units\game\siGame.pas',
  StartField in '..\..\units\game\objects\StartField.pas';

var
  Engine: TEngine;
  Game  : TSpaceInvadersGame;

begin
  try
    Engine := TEngine.GetInstance;
    Engine.Initialize(800, 600, 'Open Space Invaders');

    Game := TSpaceInvadersGame.Create;
    Engine.SetActiveScene(Game.Scenes.Current);
    Engine.Run;
  finally
    Game.Free;
    Engine.Free;
  end;

end.
