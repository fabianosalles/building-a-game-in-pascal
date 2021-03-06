unit scnGamePlay;

interface

uses
  SDL2,
  generics.collections,
  Math,
  sdlScene,
  sdlGameTypes,
  sdlGamePlayer,
  sdlGameEnemies,
  sdlGameSound,
  sdlGameTexture,
  sdlGameObjects,
  sdlParticles,
  Shots,
  StartField;


type

  TSpriteKind = (
    EnemyA = 0,
    EnemyB,
    EnemyC,
    EnemyD,
    Player,
    Bunker,
    Garbage,
    Explosion,
    ShotA,
    Leds
  );

  { TGamePlayScene }

  TGamePlayScene = class(TScene)
  strict private
  type
    TSceneState = ( Playing, Paused, GameOver );
  var
    fState      : TSceneState;
    fPlayer     : TPlayer;
    fExplosions : TExplosionList;
    fSparks     : TEmitterList;
    fShots      : TShotList;
    fStartField : TStarField;
    fEnemies    : TEnemyList;
    fRenderer   : PSDL_Renderer;
  private
    procedure CreateGameObjects;

    procedure DrawBackGround;
    procedure DrawGameObjects;
    procedure DrawUI;
    procedure doOnReturnPressed;
    procedure doOnShot(Sender: TGameObject);
    procedure doOnShotCollided(Sender, Suspect: TGameObject; var StopChecking: boolean);
    procedure doOnShotSmokeVanished(Sender: TObject);
    procedure doOnListNotify(Sender: TObject; constref Item: TGameObject; Action: TCollectionNotification);
    procedure ClearInvalidShots;
    function SpawnNewSparkAt( enemy : TEnemy ): TEmitter;
  protected
    procedure doLoadTextures; override;
    procedure doOnCheckCollitions; override;

    procedure doOnKeyDown(key: TSDL_KeyCode); override;
    procedure doOnKeyUp(key: TSDL_KeyCode); override;
    procedure doOnRender(renderer: PSDL_Renderer); override;
    procedure doOnUpdate(const deltaTime: real); override;

    procedure doBeforeStart; override;
  public
    constructor Create(APlayer: TPlayer);
    destructor Destroy; override;

    procedure Reset;

    property Player : TPlayer read fPlayer;
  end;


implementation

uses
  sdlEngine,
  sysutils;

{ TGamePlayScene }

procedure TGamePlayScene.CreateGameObjects;
var
  i : integer;
  enemy    : TEnemy;
  textures : TTextureManager;
begin
  textures := TEngine.GetInstance.Textures;
  fEnemies.Clear;
  for i:= 0 to 119 do
  begin
    case i of
      00..39 :
        begin
          enemy := TEnemyC.Create;
          enemy.Sprite.Texture.Assign( textures[ integer(TSpriteKind.EnemyC) ] );
          enemy.Sprite.InitFrames(1, 2);
        end;

      40..79 :
        begin
          enemy := TEnemyB.Create;
          enemy.Sprite.Texture.Assign( textures[ integer(TSpriteKind.EnemyB) ] );
          enemy.Sprite.InitFrames(1, 2);
        end;

      80..119 :
        begin
          enemy := TEnemyA.Create;
          enemy.Sprite.Texture.Assign( textures[ integer(TSpriteKind.EnemyA) ] );
          enemy.Sprite.InitFrames(1, 2);
        end;
    end;
    enemy.OnShot := {$IFDEF FPC}@{$ENDIF}doOnShot;
    fEnemies.Add( enemy );
  end;

  fPlayer.Sprite.Texture.Assign( textures[ integer(TSpriteKind.Player)] );
  fPlayer.Sprite.InitFrames(1,1);
  fPlayer.OnShot  := {$IFDEF FPC}@{$ENDIF}doOnShot;
  fShots          := TShotList.Create(true);
  fShots.OnNotify := {$IFDEF FPC}@{$ENDIF}doOnListNotify;
  fExplosions     := TExplosionList.Create(true);
  fSparks         := TEmitterList.Create(true);
end;

procedure TGamePlayScene.DrawBackGround;
begin
  fStartField.Draw;
end;

procedure TGamePlayScene.DrawGameObjects;
begin
  fPlayer.Draw;
  fEnemies.Draw;
  fShots.Draw;
  fExplosions.Draw;
  fSparks.Draw;
end;

procedure TGamePlayScene.DrawUI;
var
  rect   : TSDL_Rect;
  engine : TEngine;
begin
  engine := TEngine.GetInstance;
  SDL_SetRenderDrawColor(engine.Renderer, 255, 255, 0, 255);
  SDL_RenderDrawLine( engine.Renderer,  0, round(DEBUG_CELL_SIZE * 1.5),
                                           SCREEN_WIDTH, round(DEBUG_CELL_SIZE * 1.5));

  rect.x:= 0;
  rect.y:= 0;
  rect.h:= round(DEBUG_CELL_SIZE * 1.5);
  rect.w:= SCREEN_WIDTH;
  SDL_SetRenderDrawColor(engine.Renderer, 255, 0, 0, 80);
  SDL_RenderFillRect( engine.Renderer, @rect );
  engine.Text.Draw( Format('SCORE %.6d', [fPlayer.Score]),  290, 12, engine.Fonts.GUI  );

  rect.x:= 710;
  rect.y:= 18;
  rect.h:= 2 *fPlayer.Sprite.Texture.H div 3;
  rect.w:= 2 *fPlayer.Sprite.Texture.W div 3;

  SDL_RenderCopy(engine.Renderer,
                   fPlayer.Sprite.Texture.Data,
                   @fPlayer.Sprite.CurrentFrame.Rect,
                   @rect);
   engine.Text.Draw( Format('%.2d', [fPlayer.Lifes]),  738, 12, engine.Fonts.GUI  );
  case fState of
    Paused:
      begin
        //obsfuscates the game stage
        rect.x := 0;
        rect.y := round( 1.5 * DEBUG_CELL_SIZE) +1;
        rect.h := SCREEN_HEIGHT - rect.y;
        rect.w:= SCREEN_WIDTH;
        SDL_SetRenderDrawColor(engine.Renderer, 0, 0, 0, 200);
        SDL_RenderFillRect( engine.Renderer, @rect );

        engine.Text.Draw( '***[ PAUSED ]***' ,  155, SCREEN_HALF_HEIGHT-24, engine.Fonts.GUI64  );
        if SDL_NumJoysticks = 0 then
           engine.Text.Draw( 'press <enter> to resume', 320, SCREEN_HALF_HEIGHT+25, engine.Fonts.DebugNormal  )
        else
           engine.Text.Draw( 'press <start> to resume', 320, SCREEN_HALF_HEIGHT+25, engine.Fonts.DebugNormal  );
      end;
    GameOver :
      begin
        //obsfuscates the game stage
        rect.x := 0;
        rect.y := round( 1.5 * DEBUG_CELL_SIZE) +1;
        rect.h := SCREEN_HEIGHT - rect.y;
        rect.w:= SCREEN_WIDTH;
        SDL_SetRenderDrawColor(engine.Renderer, 50, 0, 0, 200);
        SDL_RenderFillRect( engine.Renderer, @rect );

        engine.Text.DrawModulated( '***[ GAME OVER ]***' ,  105, SCREEN_HALF_HEIGHT-24, engine.Fonts.GUI64, 255,0,0  );
        if SDL_NumJoysticks = 0 then
           engine.Text.Draw( 'press <enter> to start a new game', 285, SCREEN_HALF_HEIGHT+25, engine.Fonts.DebugNormal  )
        else
           engine.Text.Draw( 'press <start> to start a new game', 285, SCREEN_HALF_HEIGHT+25, engine.Fonts.DebugNormal  );
      end;
  end;
end;


procedure TGamePlayScene.doOnReturnPressed;
begin
  case fState of
    Paused:
      begin
        fState := TSceneState.Playing;
        TEngine.GetInstance.Sounds.Play(sndGameResume);
      end;
    Playing:
      begin
        fState := TSceneState.Paused;
        TEngine.GetInstance.Sounds.Play(sndGamePause);
      end;
    GameOver:
      begin
        Reset;
      end;
  end;
end;

procedure TGamePlayScene.doOnShot(Sender: TGameObject);
var
  enemy  : Tenemy;
  shot   : TShot;
  engine : TEngine;
begin
  engine := TEngine.GetInstance;
  shot := TShot.Create;
  shot.Sprite.Texture.Assign(engine.Textures[ Ord(TSpriteKind.ShotA) ] );
  shot.Sprite.InitFrames( 1,1 );
  shot.OnCollided := {$IFDEF FPC}@{$ENDIF}doOnShotCollided;
  shot.OnSmokeVanished := {$IFDEF FPC}@{$ENDIF}doOnShotSmokeVanished;
  if (Sender is TPlayer) then
  begin
    shot.Position.Assign(player.ShotSpawnPoint);
    shot.Position.X :=  shot.Position.X - (shot.Sprite.CurrentFrame.Rect.w / 2);
    shot.ShowSmoke := true;
    shot.StartEmitSmoke;
    engine.Sounds.Play( sndPlayerBullet );
  end
  else
  if (Sender is TEnemy) then
  begin
    enemy := TEnemy(Sender);
    shot.Direction:= TShotDirection.Down;
    shot.Position.Assign(enemy.ShotSpawnPoint);
    shot.Position.X := shot.Position.X - (shot.Sprite.CurrentFrame.Rect.w / 2);
    shot.ShowSmoke := true;
    shot.StartEmitSmoke;
    engine.Sounds.Play(sndEnemyBullet);
  end;
  fShots.Add( shot );
end;

procedure TGamePlayScene.doOnShotCollided(Sender, Suspect: TGameObject;
  var StopChecking: boolean);
var
  shot       : TShot;
  enemy      : TEnemy;
  explostion : TExplosion;
  engine     : TEngine;
  smoke      : TEmitter;
begin
  engine := TEngine.GetInstance;
  if ( Sender is TShot )  then
  begin
    shot  := TShot(Sender);
    if (Suspect is TEnemy) and (TEnemy(Suspect).HP > 0) then
    begin
      enemy := TEnemy(Suspect);
      enemy.Hit( 1 );
      engine.Sounds.Play(sndEnemyHit);
      fSparks.Add(SpawnNewSparkAt(enemy));
      if enemy.Alive then
         fPlayer.Score :=  fPlayer.Score + 10
      else
        begin
         fPlayer.Score :=  fPlayer.Score + 100;
         explostion := TExplosion.Create();
         explostion.Sprite.Texture.Assign(engine.Textures[Ord(TSpriteKind.Explosion)]);
         explostion.Sprite.InitFrames(1,1);
         explostion.Position.Assign(enemy.Position);
         fExplosions.Add(explostion);
        end;
      shot.Visible := false;
      shot.Active  := false;
      shot.StopEmitSmoke;
      StopChecking := true;
      exit;
    end;

   if ( Suspect is TPlayer ) then
   begin
     fPlayer.Hit( 1 );
     explostion := TExplosion.Create;
     explostion.Sprite.Texture.Assign(engine.Textures[Ord(TSpriteKind.Explosion)]);
     explostion.Sprite.InitFrames(1,1);
     explostion.Position.Assign(Suspect.Position);
     fExplosions.Add( explostion );
     engine.Sounds.Play( sndEnemyHit );
     fShots.Remove( shot );
   end;
  end;

end;

procedure TGamePlayScene.doOnShotSmokeVanished(Sender: TObject);
var
  shot : TShot;
begin
  if (Sender is TShot) then
  begin
    shot := TShot(Sender);
    fShots.Remove( shot )
  end;
end;

procedure TGamePlayScene.doOnListNotify(Sender: TObject; constref Item: TGameObject;
  Action: TCollectionNotification);
begin
  if Sender = fShots then
  begin
     case Action of
       cnAdded    : WriteLn('Shot added. Count: ', fShots.Count);
       cnRemoved  : WriteLn('Shot removed. Count: ', fShots.Count);
       cnExtracted: WriteLn('Shot extracted. Count: ', fShots.Count);
     end;
  end;
end;

procedure TGamePlayScene.doLoadTextures;
var
  engine : TEngine;
begin
  engine := TEngine.GetInstance;
  engine.Textures.Clear;
  engine.Textures.Load( 'enemy_a.png' );
  engine.Textures.Load( 'enemy_b.png' );
  engine.Textures.Load( 'enemy_c.png' );
  engine.Textures.Load( 'enemy_d.png' );
  engine.Textures.Load( 'player.png' );
  engine.Textures.Load( 'bunker.png' );
  engine.Textures.Load( 'garbage.png' );
  engine.Textures.Load( 'explosion.png' );
  engine.Textures.Load( 'shot_a.png' );
  engine.Textures.Load( 'leds.png' );
end;


procedure TGamePlayScene.doOnCheckCollitions;
var
  i           : integer;
  shotList    : TShotList;
  suspectList : TEnemyList;
begin
  //check all shots going upwards with all alive enemies
  if (fShots.Count > 0) and ( fEnemies.Count > 0 ) then
  begin
    shotList    := fShots.FilterByDirection( TShotDirection.Up );
    suspectList := fEnemies.FilterByLife( true );
    for i:=0 to Pred(shotList.Count) do
      TShot(shotList[i]).CheckCollisions( suspectList );
    shotList.Free;
    suspectList.Free;
  end;

  //check all shots going downwards against the player
  if (fShots.Count > 0) then
  begin
    shotList := fShots.FilterByDirection( TShotDirection.Down );
    for i:=0 to shotList.Count-1 do
      TShot(shotList[i]).CheckCollisions( fPlayer );

    shotList.Free;
  end;
end;

procedure TGamePlayScene.doOnKeyDown(key: TSDL_KeyCode);
begin
  case key of
    SDLK_LEFT, SDLK_A  : fPlayer.Input[Ord(TPlayerInput.Left)] := true;
    SDLK_RIGHT, SDLK_D : fPlayer.Input[Ord(TPlayerInput.Right)] := true;
    SDLK_SPACE : fPlayer.Input[Ord(TPlayerInput.Shot)] := true;
  end;
end;

procedure TGamePlayScene.doOnKeyUp(key: TSDL_KeyCode);
begin
  case key of
    SDLK_LEFT, SDLK_A : fPlayer.Input[Ord(TPlayerInput.Left)] := false;
    SDLK_RIGHT, SDLK_D: fPlayer.Input[Ord(TPlayerInput.Right)] := false;
    SDLK_SPACE  : fPlayer.Input[Ord(TPlayerInput.Shot)] := false;
    SDLK_RETURN : doOnReturnPressed;
  end;
end;

procedure TGamePlayScene.doOnRender(renderer: PSDL_Renderer);
begin
  fRenderer := renderer;
  DrawBackground;
  DrawGameObjects;
  DrawUI;
end;

procedure TGamePlayScene.doOnUpdate(const deltaTime: real);
begin
  case fState of
    Playing :
      begin
        fPlayer.Update( deltaTime );
        fEnemies.Update( deltaTime );
        fShots.Update( deltaTime );
        fStartField.Update( deltaTime );
        ClearInvalidShots;
        fExplosions.Update( deltaTime );
        fSparks.Update( deltaTime );
        if ( fPlayer.Lifes <=0)  then
        begin
         fState := GameOver;
         TEngine.GetInstance.Sounds.Play( sndGameOver );
        end;
      end;

    Paused  :
      begin

      end;

    GameOver:
      begin

      end;
  end;
end;

procedure TGamePlayScene.doBeforeStart;
begin
  inherited doBeforeStart;
  CreateGameObjects;
  Reset;
end;


procedure TGamePlayScene.ClearInvalidShots;
var
  i    : integer;
  shot : TShot;
begin
  for i := fShots.Count-1 downto 0 do begin
    shot := TShot(fShots[i]);
    case shot.Direction of
      TShotDirection.Up  : ;
      TShotDirection.Down:
        begin
          if not shot.IsInsideScreen then
            fShots.Remove(shot);
        end;
    end;
  end;
end;

constructor TGamePlayScene.Create(APlayer: TPlayer);
begin
  inherited Create;
  fPlayer     := APlayer;
  fExplosions := TExplosionList.Create;
  fShots      := TShotList.Create;
  fEnemies    := TEnemyList.Create;
  fStartField := TStarField.Create;
  TEngine.GetInstance.HideCursor;
end;

destructor TGamePlayScene.Destroy;
begin
  fExplosions.Free;
  fShots.Free;
  fEnemies.Clear;
  fEnemies.Free;
  fStartField.Free;
  inherited Destroy;
end;

procedure TGamePlayScene.Reset;
var
  i: integer;
  enemy : TEnemy;
begin
  fPlayer.Lifes := 3;
  fPlayer.Position.X := trunc( SCREEN_HALF_WIDTH - ( fPlayer.Sprite.Texture.W / 2 ));
  fPlayer.Position.Y := (DEBUG_CELL_SIZE * 18) - fPlayer.Sprite.CurrentFrame.Rect.h;

  for i:=0 to Pred(fEnemies.Count) do
  begin
    enemy := TEnemy(fEnemies.Items[i]);
    enemy.Position.X := DEBUG_CELL_SIZE + ( i mod 20 ) * DEBUG_CELL_SIZE ;
    enemy.Position.Y := 2 * DEBUG_CELL_SIZE + ( i div 20 ) * DEBUG_CELL_SIZE ;
    if enemy is TEnemyA then enemy.HP := 1;
    if enemy is TEnemyB then enemy.HP := 2;
    if enemy is TEnemyC then enemy.HP := 3;
    enemy.StartMoving;
  end;
  fShots.Clear;
  fState := TSceneState.Playing;
end;


function TGamePlayScene.SpawnNewSparkAt(enemy: TEnemy): TEmitter;
begin
  result := TEmitterFactory.NewSmokeOneShot;
  result.Bounds.X  := round((enemy.Position.X));
  result.Bounds.Y  := round(enemy.Position.Y);
  result.Bounds.W  := round(enemy.SpriteRect.w);
  result.Bounds.H  := round(enemy.SpriteRect.h);
  result.Angle.Min := 0;
  result.Angle.Max := 380;
  result.Gravity.X := 0;
  result.Gravity.Y := 5;
  case enemy.HP of
    0 : result.MaxCount  := RandomRange(60, 80);
    1 : result.MaxCount  := RandomRange(8, 20);
    2 : result.MaxCount  := RandomRange(3, 8);
  end;
  if enemy is TEnemyB then
    result.MaxCount := result.MaxCount + 20
  else
  if enemy is TEnemyC then
  begin
    result.MaxCount := result.MaxCount + 50;
    result.Bounds.X := result.Bounds.X - 5;
    result.Bounds.Y := result.Bounds.Y + 5;
    result.Bounds.W := result.Bounds.W + 5;
    result.Bounds.H := result.Bounds.H + 5;
  end;
  result.Color := enemy.ColorModulation;
  result.Start;
end;

end.
