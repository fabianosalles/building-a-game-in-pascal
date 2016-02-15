program space_invaders;

{$APPTYPE CONSOLE}

uses
  sdlEngine,
  siGame,
  scnGamePlay in '..\..\units\scenes\scnGamePlay.pas',
  scnIntro in '..\..\units\scenes\scnIntro.pas',
  scnMainMenu in '..\..\units\scenes\scnMainMenu.pas',
  scnParticles in '..\..\units\scenes\scnParticles.pas',
  sdlGameEnemies in '..\..\units\sdlGameEnemies.pas',
  sdlGameObjects in '..\..\units\sdlGameObjects.pas',
  sdlGamePlayer in '..\..\units\sdlGamePlayer.pas',
  sdlGameSound in '..\..\units\sdlGameSound.pas',
  sdlGameText in '..\..\units\sdlGameText.pas',
  sdlGameTexture in '..\..\units\sdlGameTexture.pas',
  sdlGameTypes in '..\..\units\sdlGameTypes.pas',
  sdlGameUtils in '..\..\units\sdlGameUtils.pas';

var
  Engine: TEngine;
  Game  : TSpaceInvadersGame;

begin
  try
    Engine := TEngine.GetInstance;
    Engine.Initialize(800, 600, 'Delphi Games - Space Invaders');

    Game := TSpaceInvadersGame.Create;
    Engine.SetActiveScene(Game.Scenes.Current);
    Engine.Run;
  finally
    Game.Free;
    Engine.Free;
  end;

end.
