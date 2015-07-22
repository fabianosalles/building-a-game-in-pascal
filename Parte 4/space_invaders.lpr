program space_invaders;

{$mode objfpc}{$H+}

uses
  sdlGame, sdlGameObjects, sdlGameUtils;

var
  Game : TGame;

begin
  try
    Game := TGame.Create;
    Game.Initialize;
    Game.Run;
  finally
    Game.Free;
  end;
end.

