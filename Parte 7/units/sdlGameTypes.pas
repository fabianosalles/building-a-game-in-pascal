unit sdlGameTypes;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  SDL2,
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

  EngineException = class( Exception );
  TEvent = procedure of object;
  TNotifyEvent = procedure (sender: TObject) of object;
  TUpdateEvent = procedure (const deltaTime : real) of object;
  TRenderEvent = procedure (renderer : PSDL_Renderer) of object;
  TKeyboardEvent = procedure (key: TSDL_KeyCode) of object;
  TJoyButtonEvent = procedure(joystick: SInt32; button: UInt8) of object;
  TJoyAxisMotionEvent = procedure(axis: UInt8; value: SInt32) of object;


  IUpdatable = interface
    procedure Update(const deltaTime : real);
  end;

  IDrawable = interface
    procedure Draw;
  end;



implementation



end.

