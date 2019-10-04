program space_invaders;

{$mode objfpc}{$H+}

uses
    siGame;

var
  Engine: TEngine;
  Game  : TSpaceInvadersGame;

begin
  try
    Engine := TEngine.GetInstance;
    //Engine.Initialize(800, 600, 'Delphi Games - Space Invaders');
    Engine.Initialize(1280, 720, 'Delphi Games - Space Invaders');

    Game := TSpaceInvadersGame.Create;
    Engine.SetActiveScene(Game.Scenes.Current);
    Engine.Run;
  finally
     Game.Free;
     Engine.Free;
  end;
end.

