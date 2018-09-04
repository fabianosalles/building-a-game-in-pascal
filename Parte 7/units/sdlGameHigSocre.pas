unit sdlGameHigSocre;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  sysutils,
  SDL2,
{$IFDEF FPC}
  fgl,
{$ELSE}
   Generics.Collections,
{$ENDIF}
  sdlGameTypes,
  sdlGameObjects;

type
  TScore = class
  private
    fPlayerName: string;
    fScore: integer;
    fDate: TDateTime;
  public
    constructor Create(PlayerName: string; Score: integer; Date: TDateTime);
    property PlayerName: string read fPlayerName;
    property Score: integer read fScore;
    property Date: TDateTime read fDate;
  end;

  TScoreTable = class( TGameObject )
  private
    fWinners: TList<TScore>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Load;
    procedure Save;
  end;

implementation

{ TScoreTable }

constructor TScoreTable.Create;
begin
  fWinners := TList<TScore>.Create;
end;

destructor TScoreTable.Destroy;
begin
  FreeAndNil(fWinners);
  inherited;
end;

procedure TScoreTable.Load;
begin
  //load from a remote service
end;

procedure TScoreTable.Save;
begin
  //save to a remote service
end;

{ TScore }

constructor TScore.Create(PlayerName: string; Score: integer; Date: TDateTime);
begin
  inherited Create;
  fPlayerName := PlayerName;
  fScore := Score;
  fDate := Date;
end;

end.
