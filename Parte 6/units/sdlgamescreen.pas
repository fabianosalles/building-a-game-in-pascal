unit sdlGameScreen;

{$mode objfpc}{$H+}

interface

uses
  SDL2;

type

  { TGameScreen }

  TGameScreen = class
  strict private
    fRenderer : PSDL_Renderer;
  protected

  public
    constructor Create( aRenderer: PSDL_Renderer );
    procedure Update(const deltaTime : real); virtual; abstract;
    procedure Render; virtual; abstract;

  end;


  TScreenGamePlay = class(TGameScreen)

  end;


  TScreenGameOver = class(TGameScreen)

  end;


  TScreenMainMenu = class(TGameScreen)

  end;

implementation

{ TGameScreen }

constructor TGameScreen.Create(aRenderer: PSDL_Renderer);
begin
  fRenderer:= aRenderer;
end;

end.

