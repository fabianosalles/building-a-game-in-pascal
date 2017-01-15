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
      sndGameOver,
      sndNewGame,
      sndMenu
    );


  {$IFDEF FPC}
  TGSoundList = specialize TFPGList<PMix_Chunk>;
  {$ELSE}
  TGSoundList = TList<PMix_Chunk>;
  {$ENDIF}


  {$IFDEF FPC}
  TGMusicList = specialize TFPGList<PMix_Music>;
  {$ELSE}
  TGMusicList = TList<PMix_Music>;
  {$ENDIF}

  { TSoundManager }

  TSoundManager = class
  strict private
    fPath  : string;
    fChunks: TGSoundList;
    fMusics: TGMusicList;
  public
    constructor Create;
    destructor Destroy; override;

    function LoadMusic(const name: string): integer;
    procedure FreeMusic(music: integer);

    //load the defaults music
    //TODO: change to a more generic approach
    procedure LoadSounds;
    procedure PlayMusic( music, loops: integer );
    procedure StopMusic( music: integer );
    procedure Play( sound: TSound ); overload;
    procedure Play( sound: TSound; volume : Double); overload;

    property Path: string read fPath write fPath;
  end;


implementation

{ TSoundManager }

constructor TSoundManager.Create;
begin
  fChunks := TGSoundList.Create;
  fMusics := TGMusicList.Create;
end;

destructor TSoundManager.Destroy;
var
  i: integer;
begin
  for i:= 0 to Pred(fChunks.Count) do
    Mix_FreeChunk(fChunks[i]);
  fChunks.Free;

  for i := 0 to Pred(fMusics.Count) do
    Mix_FreeMusic(fMusics[i]);
  fMusics.Free;

  inherited Destroy;
end;

procedure TSoundManager.FreeMusic(music: integer);
begin
  if (fMusics.Count < music) then begin
    Mix_FreeMusic(fMusics[music]);
    fMusics.Delete(music);
  end;
end;

function TSoundManager.LoadMusic(const name: string): integer;
var
 music: PMix_Music;
begin
  result := -1;
  music := Mix_LoadMUS(PAnsiChar(AnsiString(fPath + name)));
  if (music <> nil) then
  begin
    fMusics.Add(music);
    result := fMusics.Count-1;
  end;
  {$IFDEF CONSOLE}
  if (music = nil) then
    Writeln('Mix_LoadMUS: ', Mix_GetError);
  {$ENDIF}
end;

procedure TSoundManager.LoadSounds;
var
  sound : TSound;
begin
  for sound := low(TSound) to High(TSound) do
  case sound of
    sndEnemyBullet  : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(fPath + 'EnemyBullet.wav'))));
    sndEnemyHit     : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(fPath + 'EnemyHit.wav'))));
    sndPlayerBullet : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(fPath + 'PlayerBullet.wav'))));
    sndPlayerHit    : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(fPath + 'PlayerHit.wav'))));
    sndGamePause    : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(fPath + 'GamePause.wav'))));
    sndGameResume   : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(fPath + 'GameResume.wav'))));
    sndGameOver     : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(fPath + 'GameOver.wav'))));
    sndNewGame      : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(fPath + 'NewGame.wav'))));
    sndMenu         : fChunks.Add(Mix_LoadWAV(PAnsiChar(AnsiString(fPath + 'MenuNavigate.wav'))));
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

procedure TSoundManager.PlayMusic(music, loops: integer);
var
  e : integer;
begin
  e := Mix_PlayMusic(fMusics[music], loops);
  {$IFDEF CONSOLE}
  if (e<0) then
    WriteLn('Mix_PlayMusic: ', Mix_GetError);
  {$ENDIF}
end;

procedure TSoundManager.StopMusic( music: integer );
begin
    Mix_PlayMusic(fMusics[music], -1);
    Mix_PauseMusic;
end;

end.
