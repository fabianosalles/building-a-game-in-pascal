unit sdlGameTypes;

{$mode objfpc}{$H+}

interface

uses
  sysutils;

const
  SCREEN_WIDTH       = 800;
  SCREEN_HEIGHT      = 600;
  SCREEN_HALF_WIDTH  = SCREEN_WIDTH div 2;
  SCREEN_HALF_HEIGHT = SCREEN_HEIGHT div 2;
  DEBUG_CELL_SIZE    = 32;
  DEBUG_CELL_COUNT_V = (SCREEN_WIDTH div DEBUG_CELL_SIZE);
  DEBUG_CELL_COUNT_H = (SCREEN_HEIGHT div DEBUG_CELL_SIZE);



type

  SDLException = class( Exception );
  SDLImageException = class( SDLException );
  SDLTTFException = class( SDLException );
  SDLMixerException = class( SDLException );
  IndexOutOfBoundsException = class( Exception );


implementation



end.

