unit scnIntro;

interface

uses
  SDL2,
  sdlScene;

type

  { TIntroScene }

  TIntroScene = class(TScene)
  strict private
    type
      TState = ( stLogoAeonsoft, stOpenSourceTribute, stLogoLazarus, stQuit);
  const
    LOGO_FADEIN  = 2000;
    LOGO_FADEOUT = 2000;
    LOGO_VISIBLE = 2000;
  var
    TEXTURE_LOGO : integer;
    TEXTURE_PAWN : integer;
    TEXTURE_GEAR : integer;

    fAlpha : UInt8;
    fAngle : double;
    fStartTick : UInt32;
    fElapsedMS: real;
    fState : TState;
  protected
    procedure doLoadTextures; override;
    procedure doOnKeyUp(key: Integer); override;
  public
    constructor Create;
    procedure doOnRender(renderer: PSDL_Renderer); override;
    procedure doOnUpdate(const deltaTime: real); override;
  end;

implementation

uses
  sdlEngine,
  sdlGameTexture;


{ TIntroScene }

procedure TIntroScene.doLoadTextures;
var
  engine : TEngine;
begin
  engine := TEngine.GetInstance;
  engine.Textures.Clear;
  TEXTURE_LOGO    := engine.Textures.Load('aeonsoft.png');
  TEXTURE_PAWN    := engine.Textures.Load('paw.png');
  TEXTURE_GEAR    := engine.Textures.Load('gear.png');
end;

constructor TIntroScene.Create;
begin
  inherited Create;
  fStartTick := SDL_GetTicks;
  fElapsedMS := 0.0;
  fState:= stLogoAeonsoft;
end;

procedure TIntroScene.doOnKeyUp(key: Integer);
begin
  inherited;
  if (fState <> stLogoAeonsoft) and (key in [SDLK_ESCAPE, SDLK_RETURN]) then
    doQuit;
end;

procedure TIntroScene.doOnRender(renderer: PSDL_Renderer);
var
  engine : TEngine;
  tex : TTexture;
  p : TSDL_Point;
  source, dest : TSDL_Rect;
begin
  engine := TEngine.GetInstance;
  case fState of
    stLogoAeonsoft: begin
      tex := engine.Textures[TEXTURE_LOGO];
      source.x:= 0;
      source.y:= 0;
      source.w:= tex.W;
      source.h:= tex.H;

      dest.w:= 150;
      dest.h:= 150;
      dest.x:= (TEngine.GetInstance.Window.w - dest.w) div 2;
      dest.y:= (TEngine.GetInstance.Window.h - dest.h) div 2 - 50;

      SDL_SetTextureAlphaMod( tex.Data, fAlpha );
      SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
      SDL_RenderCopy(renderer, tex.Data, @source, @dest);
      engine.Text.Draw('aeonsoft', dest.x - 40, dest.y + dest.h, engine.Fonts.GUI64, fAlpha);
      engine.Text.Draw('presents', dest.x + 49, dest.y + dest.h + 50, engine.Fonts.DebugNormal, fAlpha);
    end;

    stLogoLazarus: begin

      source.x:= 0;
      source.y:= 0;
      tex := engine.Textures[TEXTURE_GEAR];
      source.h:= tex.H;
      source.w:= tex.W;

      dest.h:= source.h;
      dest.w:= source.w;
      dest.x:= (TEngine.GetInstance.Window.w - dest.w) div 2;
      dest.y:= (TEngine.GetInstance.Window.h - dest.h) div 2 - 20;

      p.x:= dest.x;
      p.y:= dest.y;

      SDL_SetTextureAlphaMod( tex.Data, fAlpha );
      SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
      SDL_RenderCopyEx(renderer, tex.Data, @source, @dest, fAngle, nil, SDL_FLIP_NONE);

      tex := engine.Textures[TEXTURE_PAWN];
      source.h:= tex.H;
      source.w:= tex.W;

      dest.h:= source.h;
      dest.w:= source.w;
      dest.x:= (TEngine.GetInstance.Window.w - dest.w) div 2;
      dest.y:= (TEngine.GetInstance.Window.h - dest.h) div 2 -20;


      SDL_SetTextureAlphaMod( tex.Data, fAlpha );
      SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
      SDL_RenderCopy(renderer, tex.Data, @source, @dest);


      SDL_SetTextureAlphaMod( tex.Data, fAlpha );
      SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
      SDL_RenderCopy(renderer, tex.Data, @source, @dest);
      engine.Text.Draw('LAZARUS', dest.x - 80, dest.y + dest.h + 60, engine.Fonts.GUI64, fAlpha);
      engine.Text.Draw('built with', dest.x + 75, dest.y + dest.h + 50, engine.Fonts.DebugNormal, fAlpha);
    end;

   stOpenSourceTribute: begin
      engine.Text.Draw('SPACE INVADRES', 400-230, 280, engine.Fonts.GUI64, fAlpha);
      engine.Text.Draw('an open souce tribute to', 400-230, 270, engine.Fonts.DebugNormal, fAlpha);
   end;

  end;

end;

procedure TIntroScene.doOnUpdate(const deltaTime: real);
begin
  fElapsedMS := fElapsedMS + (deltaTime * 1000);

  case fState of
    stLogoAeonsoft:
      begin
        if fElapsedMS <= LOGO_FADEIN then
          fAlpha:= round((fElapsedMS/LOGO_FADEIN)*255)
        else
          if ( fElapsedMS > LOGO_FADEIN + LOGO_VISIBLE ) then
             if (fElapsedMS-LOGO_FADEIN-LOGO_VISIBLE) > LOGO_FADEOUT then
                 fAlpha:= 0
             else
               fAlpha:= 255 - round(((fElapsedMS-LOGO_FADEIN-LOGO_VISIBLE)/LOGO_FADEOUT * 255));
          if (fElapsedMS >= LOGO_FADEIN + LOGO_FADEOUT + LOGO_VISIBLE) then
          begin
            fAlpha:= 255;
            fElapsedMS := 0;
            fAngle:= 0;
            fState:= stOpenSourceTribute;
          end;
      end;

    stLogoLazarus:
      begin
         fAngle := fAngle + 25 * deltaTime;
          if fElapsedMS <= LOGO_FADEIN then
            fAlpha:= round((fElapsedMS/LOGO_FADEIN)*255)
          else
            if ( fElapsedMS > LOGO_FADEIN + LOGO_VISIBLE ) then
               if (fElapsedMS-LOGO_FADEIN-LOGO_VISIBLE) > LOGO_FADEOUT then
                   fAlpha:= 0
               else
                 fAlpha:= 255 - round(((fElapsedMS-LOGO_FADEIN-LOGO_VISIBLE)/LOGO_FADEOUT * 255));
            if (fElapsedMS >= LOGO_FADEIN + LOGO_FADEOUT + LOGO_VISIBLE) then
            begin
              fAlpha:= 255;
              fElapsedMS := 0;
              fAngle:= 0;
              fState:= stQuit;
              doQuit;
            end;
      end;

    stOpenSourceTribute:
      begin
        if fElapsedMS <= LOGO_FADEIN then
          fAlpha:= round((fElapsedMS/LOGO_FADEIN)*255)
        else
          if ( fElapsedMS > LOGO_FADEIN + LOGO_VISIBLE ) then
             if (fElapsedMS-LOGO_FADEIN-LOGO_VISIBLE) > LOGO_FADEOUT then
                 fAlpha:= 0
             else
               fAlpha:= 255 - round(((fElapsedMS-LOGO_FADEIN-LOGO_VISIBLE)/LOGO_FADEOUT * 255));
          if (fElapsedMS >= LOGO_FADEIN + LOGO_FADEOUT + LOGO_VISIBLE) then
          begin
            fAlpha:= 255;
            fElapsedMS := 0;
            fAngle:= 0;
            fState:= stLogoLazarus;
          end;
      end;

  end;



end;

end.
