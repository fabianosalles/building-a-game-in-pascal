unit scnParticles;

interface

uses
  SDL2,
  sdlScene,
  sdlParticles;

type
  TParticleScene = class(TScene)
  private
    fEmmiters : TEmitterList;
    procedure SpawnNewEmitter(kind: TEmitterKind);
    procedure doOnAllParticleDied(Sender: TObject);
  protected
    procedure doOnRender(renderer: Pointer); override;
    procedure doOnUpdate(const deltaTime: Real); override;
    procedure doOnKeyUp(key: Integer); override;
  public
    constructor Create;
    destructor Destroy;
  end;

implementation

{ TParticleScene }

constructor TParticleScene.Create;
var
 i: integer;
begin
  inherited;
  fEmmiters := TEmitterList.Create;

  SpawnNewEmitter(ekContinuous);
  fEmmiters[0].Bounds.X := 100;
  fEmmiters[0].Bounds.Y := 100;
  fEmmiters[0].EmissionRate := 100;

  SpawnNewEmitter(ekContinuous);
  fEmmiters[1].Bounds.X := 200;
  fEmmiters[1].Bounds.Y := 100;
  fEmmiters[1].EmissionRate := 50;

  SpawnNewEmitter(ekContinuous);
  fEmmiters[2].Bounds.X := 300;
  fEmmiters[2].Bounds.Y := 100;
  fEmmiters[2].EmissionRate := 30;


  SpawnNewEmitter(ekContinuous);
  fEmmiters[3].Bounds.X := 400;
  fEmmiters[3].Bounds.Y := 100;
  fEmmiters[3].EmissionRate := 10;

  SpawnNewEmitter(ekOneShot);
  fEmmiters[4].Bounds.X  := 500;
  fEmmiters[4].Bounds.Y  := 100;
  fEmmiters[4].MaxCount  := 20;
  fEmmiters[4].Angle.Min := 0;
  fEmmiters[4].Angle.Max := 380;
  fEmmiters[4].Gravity.X := 0;
  fEmmiters[4].Gravity.Y := 0;


  SpawnNewEmitter(ekOneShot);
  fEmmiters[5].Bounds.X  := 600;
  fEmmiters[5].Bounds.Y  := 100;
  fEmmiters[5].MaxCount  := 40;
  fEmmiters[5].Angle.Min := 0;
  fEmmiters[5].Angle.Max := 380;
  fEmmiters[5].Gravity.X := 0;
  fEmmiters[5].Gravity.Y := 0;

  fEmmiters.Start;

end;

destructor TParticleScene.Destroy;
begin
  fEmmiters.Free;
end;

procedure TParticleScene.doOnAllParticleDied(Sender: TObject);
var
  emitter : TEmitter;
begin
  if Sender is TEmitter then begin
    emitter := TEmitter(Sender);
    emitter.Stop;
    emitter.Start;
  end;
end;

procedure TParticleScene.doOnKeyUp(key: Integer);
begin
  inherited;
  case key of
    SDLK_1: SpawnNewEmitter(ekOneShot);
    SDLK_2: SpawnNewEmitter(ekContinuous);
  end;

end;

procedure TParticleScene.doOnRender(renderer: Pointer);
var
  i: integer;
begin
  inherited;
  fEmmiters.Draw;
end;

procedure TParticleScene.doOnUpdate(const deltaTime: Real);
var
  i: integer;
begin
  inherited;
  fEmmiters.Update(deltaTime);
end;

procedure TParticleScene.SpawnNewEmitter(kind: TEmitterKind);
var
  emitter : TEmitter;
begin
  case kind of
    ekContinuous:
      begin
        emitter := TEmitterFactory.NewSmokeContinuous;
      end;
    ekOneShot:
      begin
        emitter := TEmitterFactory.NewSmokeOneShot;
      end;
  end;
  emitter.OnAllParticleDied := {$IFDEF FPC}@{$ENDIF}doOnAllParticleDied;
  fEmmiters.Add(emitter);
end;

end.
