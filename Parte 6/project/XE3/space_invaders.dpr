program space_invaders;

{$APPTYPE CONSOLE}

uses
  sdlEngine,
  siGame,
  scnGamePlay in '..\..\units\scenes\scnGamePlay.pas',
  scnIntro in '..\..\units\scenes\scnIntro.pas',
  scnMainMenu in '..\..\units\scenes\scnMainMenu.pas';

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
