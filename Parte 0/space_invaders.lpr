program space_invaders;

uses
  SDL2;

begin
  if SDL_Init(SDL_INIT_VIDEO) = 0 then
  begin
    SDL_Delay(2000);
    SDL_Quit;
  end;
end.

