program space_invaders;

{$mode objfpc}{$H+}

uses
  sdlGame;

var
  Game : TGame;

begin
  Game := TGame.Create;
  try
    Game.Initialize;
    Game.Run;
  finally
    Game.Free;
  end;
end.

