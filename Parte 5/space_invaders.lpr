program space_invaders;

{$mode objfpc}{$H+}

uses
  sdlEngine,
  siGame;

var
  Engine: TEngine;
  Game  : TSIGame;

begin
  try
    Engine := TEngine.GetInstance;
    Engine.Initialize(800, 600, 'Delphi Games - Space Invaders');

    Game := TSIGame.Create;
    Engine.SetActiveScene(Game.Scenes.CurrentScene);
    Engine.Run;
  finally
     Game.Free;
     Engine.Free;
  end;
end.

