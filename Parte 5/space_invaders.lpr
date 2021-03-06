program space_invaders;

{$mode objfpc}{$H+}

uses
  sdlEngine,
  siGame, sdlParticles;

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

