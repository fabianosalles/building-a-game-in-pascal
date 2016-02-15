unit sdlGameSound;

interface

uses

{$IFDEF FPC}
  fgl,
{$ELSE}
  Generics.Collections,
{$ENDIF}
  SDL2_mixer;

type

  TSound = (
      sndEnemyBullet,
      sndEnemyHit,
      sndPlayerBullet,
      sndPlayerHit,
      sndGamePause,
      sndGameResume,
      sndGameOver
    );


  {$IFDEF FPC}
  TGSoundList = specialize TFPGList<PMix_Chunk>;
  {$ELSE}
  TGSoundList = TList<PMix_Chunk>;
  {$ENDIF}

  { TSoundManager }

  TSoundManager = class
  strict private
    fChunks: TGSoundList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadSounds(const path: string);
    procedure Play( sound: TSound ); overload;
    procedure Play( sound: TSound; volume : Double); overload;
  end;


implementation

{ TSoundManager }

constructor TSoundManager.Create;
begin
  fChunks := TGSoundList.Create;
end;

destructor TSoundManager.Destroy;
var
  i: integer;
begin
  for i:= 0 to Pred(fChunks.Count) do
    Mix_FreeChunk(fChunks[i]);
  fChunks.Free;
  inherited Destroy;
end;

procedure TSoundManager.LoadSounds(const path: string);
var
  sound : TSound;
begin
  for sound := low(TSound) to High(TSound) do
  case sound of

    sndEnemyBullet  : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(path + 'EnemyBullet.wav'))));
    sndEnemyHit     : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(path + 'EnemyHit.wav'))));
    sndPlayerBullet : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(path + 'PlayerBullet.wav'))));
    sndPlayerHit    : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(path + 'PlayerHit.wav'))));
    sndGamePause    : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(path + 'GamePause.wav'))));
    sndGameResume   : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(path + 'GameResume.wav'))));
    sndGameOver     : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(path + 'GameOver.wav'))));
  end;
end;

procedure TSoundManager.Play(sound: TSound);
begin
  Mix_PlayChannel(-1, fChunks.Items[Ord(sound)], 0);
end;

procedure TSoundManager.Play(sound: TSound; volume: Double);
const
  MAX_VOLUME = 128;
var
  lVolume : integer;
begin
  lVolume := round((volume * MAX_VOLUME) / 100);
  if lVolume > MAX_VOLUME then
     lVolume:= MAX_VOLUME;
  Mix_VolumeChunk(fChunks[Ord(sound)], lVolume);
  Play(sound);
end;

end.
