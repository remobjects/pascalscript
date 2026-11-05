
unit uPSR_graphics;
{$I PascalScript.inc}
interface
uses
  uPSRuntime, uPSUtils;



procedure RIRegisterTGRAPHICSOBJECT(Cl: TPSRuntimeClassImporter);
procedure RIRegisterTFont(Cl: TPSRuntimeClassImporter);
procedure RIRegisterTPEN(Cl: TPSRuntimeClassImporter);
procedure RIRegisterTBRUSH(Cl: TPSRuntimeClassImporter);
procedure RIRegisterTCanvas(cl: TPSRuntimeClassImporter);
procedure RIRegisterTGraphic(CL: TPSRuntimeClassImporter);
procedure RIRegisterTBitmap(CL: TPSRuntimeClassImporter; Streams: Boolean);
procedure RIRegisterTPicture(CL: TPSRuntimeClassImporter);

procedure RIRegister_Graphics(Cl: TPSRuntimeClassImporter; Streams: Boolean);

implementation
{$IFNDEF FPC}
uses
  SysUtils, Classes{$IFDEF CLX}, QGraphics{$ELSE}, Windows, Graphics{$ENDIF} {$IFDEF DELPHI_TOKYO_UP}, UITypes {$ENDIF};
{$ELSE}
uses
  SysUtils, Classes, Graphics,LCLType;
{$ENDIF}

{$IFDEF DELPHI10UP}{$REGION 'TFont'}{$ENDIF}
{$IFDEF class_helper_present}
type
  TFont_PSHelper = class helper for TFont
  public
    {$IFNDEF CLX}
    procedure HandleR(var T: HFONT);
    procedure HandleW(T: HFONT);
    {$ENDIF}
    procedure PixelsPerInchR(var T: Longint);
    procedure PixelsPerInchW(T: Longint);
    procedure StyleR(var T: TFontStyles);
    procedure StyleW(T: TFontStyles);
  end;
{$IFNDEF CLX}
procedure TFont_PSHelper.HandleR(var T: HFONT); begin T := Self.Handle; end;
procedure TFont_PSHelper.HandleW(T: HFONT); begin Self.Handle := T; end;
{$ENDIF}
procedure TFont_PSHelper.PixelsPerInchR(var T: Longint); begin T := Self.PixelsPerInch; end;
procedure TFont_PSHelper.PixelsPerInchW(T: Longint); begin {$IFNDEF FPC} Self.PixelsPerInch := T;{$ENDIF} end;
procedure TFont_PSHelper.StyleR(var T: TFontStyles); begin T := Self.Style; end;
procedure TFont_PSHelper.StyleW(T: TFontStyles); begin Self.Style:= T; end;

procedure RIRegisterTFont(Cl: TPSRuntimeClassImporter);
begin
  with Cl.Add(TFont) do
  begin
    RegisterConstructor(@TFont.Create, 'Create');
{$IFNDEF CLX}
    RegisterPropertyHelper(@TFont.HandleR, @TFont.HandleW, 'Handle');
{$ENDIF}
    RegisterPropertyHelper(@TFont.PixelsPerInchR, @TFont.PixelsPerInchW, 'PixelsPerInch');
    RegisterPropertyHelper(@TFont.StyleR, @TFont.StyleW, 'Style');
  end;
end;
{$ELSE}
{$IFNDEF CLX}
procedure TFontHandleR(Self: TFont; var T: HFONT); begin T := Self.Handle; end;
procedure TFontHandleW(Self: TFont; T: HFONT); begin Self.Handle := T; end;
{$ENDIF}
procedure TFontPixelsPerInchR(Self: TFont; var T: Longint); begin T := Self.PixelsPerInch; end;
procedure TFontPixelsPerInchW(Self: TFont; T: Longint); begin {$IFNDEF FPC} Self.PixelsPerInch := T;{$ENDIF} end;
procedure TFontStyleR(Self: TFont; var T: TFontStyles); begin T := Self.Style; end;
procedure TFontStyleW(Self: TFont; T: TFontStyles); begin Self.Style:= T; end;

procedure RIRegisterTFont(Cl: TPSRuntimeClassImporter);
begin
  with Cl.Add(TFont) do
  begin
    RegisterConstructor(@TFont.Create, 'Create');
{$IFNDEF CLX}
    RegisterPropertyHelper(@TFontHandleR, @TFontHandleW, 'Handle');
{$ENDIF}
    RegisterPropertyHelper(@TFontPixelsPerInchR, @TFontPixelsPerInchW, 'PixelsPerInch');
    RegisterPropertyHelper(@TFontStyleR, @TFontStyleW, 'Style');
  end;
end;
{$ENDIF class_helper_present}
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}

{ Members that are virtual in some or all Delphi versions, bound through routines that call them
  by name: the compiler then calls through the object's virtual method table wherever the member is
  virtual, so a descendant's override runs.  Bound by address, a script ran this class's own code
  whatever the object's class. }
procedure TCanvasArc_P(Self: TCanvas; X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer);
begin
  Self.Arc(X1, Y1, X2, Y2, X3, Y3, X4, Y4);
end;

procedure TCanvasChord_P(Self: TCanvas; X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer);
begin
  Self.Chord(X1, Y1, X2, Y2, X3, Y3, X4, Y4);
end;

procedure TCanvasDraw_P(Self: TCanvas; X, Y: Integer; Graphic: TGraphic);
begin
  Self.Draw(X, Y, Graphic);
end;

procedure TCanvasEllipse_P(Self: TCanvas; X1, Y1, X2, Y2: Integer);
begin
  Self.Ellipse(X1, Y1, X2, Y2);
end;

procedure TCanvasFillRect_P(Self: TCanvas; const Rect: TRect);
begin
  Self.FillRect(Rect);
end;

{$IFNDEF CLX}
{ FillStyle is a byte in scripts and TFillStyle has two members, which index a two-entry table: a value
  outside them is refused }
procedure TCanvasFloodFill_P(Self: TCanvas; X, Y: Integer; Color: TColor; FillStyle: Byte);
begin
  if FillStyle > Ord(High(TFillStyle)) then
    raise ERangeError.Create('Out Of Range');
  Self.FloodFill(X, Y, Color, TFillStyle(FillStyle));
end;
{$ENDIF}

procedure TCanvasLineTo_P(Self: TCanvas; X, Y: Integer);
begin
  Self.LineTo(X, Y);
end;

procedure TCanvasMoveTo_P(Self: TCanvas; X, Y: Integer);
begin
  Self.MoveTo(X, Y);
end;

procedure TCanvasPie_P(Self: TCanvas; X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer);
begin
  Self.Pie(X1, Y1, X2, Y2, X3, Y3, X4, Y4);
end;

procedure TCanvasRectangle_P(Self: TCanvas; X1, Y1, X2, Y2: Integer);
begin
  Self.Rectangle(X1, Y1, X2, Y2);
end;

procedure TCanvasRefresh_P(Self: TCanvas);
begin
  Self.Refresh;
end;

procedure TCanvasRoundRect_P(Self: TCanvas; X1, Y1, X2, Y2, X3, Y3: Integer);
begin
  Self.RoundRect(X1, Y1, X2, Y2, X3, Y3);
end;

procedure TCanvasTextOut_P(Self: TCanvas; X, Y: Integer; Text: string);
begin
  Self.TextOut(X, Y, Text);
end;

{$IFDEF DELPHI10UP}{$REGION 'TCanvas'}{$ENDIF}
{$IFDEF class_helper_present}
type
  TCanvas_PSHelper = class helper for TCanvas
  public
    {$IFNDEF CLX}
    procedure HandleR(var T: HDC);
    procedure HandleW(T: HDC);
    {$ENDIF}

    procedure PixelsR(var T: Longint; X,Y: Longint);
    procedure PixelsW(T, X, Y: Longint);
    (*
    {$IFDEF FPC}
    procedure Arc(Self : TCanvas; X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer);
    procedure Chord(Self : TCanvas; X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer);
    procedure Rectangle(Self : TCanvas; X1,Y1,X2,Y2 : integer);
    procedure RoundRect(Self : TCanvas; X1, Y1, X2, Y2, X3, Y3 : integer);
    procedure Ellipse(Self : TCanvas;X1, Y1, X2, Y2: Integer);
    procedure FillRect(Self : TCanvas; const Rect: TRect);
    procedure FloodFill(Self : TCanvas; X, Y: Integer; Color: TColor; FillStyle: TFillStyle);
    {$ENDIF}
    *)
  end;

{$IFNDEF CLX}
procedure TCanvas_PSHelper.HandleR(var T: HDC); begin T := Self.Handle; end;
procedure TCanvas_PSHelper.HandleW(T: HDC); begin Self.Handle:= T; end;
{$ENDIF}

procedure TCanvas_PSHelper.PixelsR(var T: Longint; X,Y: Longint); begin T := Self.Pixels[X,Y]; end;
procedure TCanvas_PSHelper.PixelsW(T, X, Y: Longint); begin Self.Pixels[X,Y]:= T; end;
(*
{$IFDEF FPC}
procedure TCanvas_PSHelper.Arc(Self : TCanvas; X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer); begin Self.Arc(X1, Y1, X2, Y2, X3, Y3, X4, Y4); end;
procedure TCanvas_PSHelper.Chord(Self : TCanvas; X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer); begin self.Chord(X1, Y1, X2, Y2, X3, Y3, X4, Y4); end;
procedure TCanvas_PSHelper.Rectangle(Self : TCanvas; X1,Y1,X2,Y2 : integer); begin self.Rectangle(x1,y1,x2,y2); end;
procedure TCanvas_PSHelper.RoundRect(Self : TCanvas; X1, Y1, X2, Y2, X3, Y3 : integer); begin self.RoundRect(X1, Y1, X2, Y2, X3, Y3); end;
procedure TCanvas_PSHelper.Ellipse(Self : TCanvas;X1, Y1, X2, Y2: Integer); begin self.Ellipse(X1, Y1, X2, Y2); end;
procedure TCanvas_PSHelper.FillRect(Self : TCanvas; const Rect: TRect); begin self.FillRect(rect); end;
procedure TCanvas_PSHelper.FloodFill(Self : TCanvas; X, Y: Integer; Color: TColor; FillStyle: TFillStyle); begin self.FloodFill(x,y,color,fillstyle); end;
{$ENDIF}
*)
procedure RIRegisterTCanvas(cl: TPSRuntimeClassImporter); // requires TPersistent
begin
  with Cl.Add(TCanvas) do
  begin
    {$IFNDEF FPC}
    RegisterConstructor(@TCanvas.Create, 'Create');
    {$ENDIF}
    RegisterMethod(@TCanvasArc_P, 'Arc');
    RegisterMethod(@TCanvasChord_P, 'Chord');
    RegisterMethod(@TCanvasRectangle_P, 'Rectangle');
    RegisterMethod(@TCanvasRoundRect_P, 'RoundRect');
    RegisterMethod(@TCanvasEllipse_P, 'Ellipse');
    RegisterMethod(@TCanvasFillRect_P, 'FillRect');
{$IFDEF FPC}
    RegisterMethod(@TCanvasFloodFill_P, 'FloodFill');
{$ELSE}
{$IFNDEF CLX}
    RegisterMethod(@TCanvasFloodFill_P, 'FloodFill');
{$ENDIF}
{$ENDIF}
    RegisterMethod(@TCanvasDraw_P, 'Draw');

    RegisterMethod(@TCanvasLineTo_P, 'LineTo');
    RegisterMethod(@TCanvasMoveTo_P, 'MoveTo');
    RegisterMethod(@TCanvasPie_P, 'Pie');
    RegisterMethod(@TCanvasRefresh_P, 'Refresh');
    RegisterMethod(@TCanvas.TextHeight, 'TextHeight');
    RegisterMethod(@TCanvasTextOut_P, 'TextOut');
    RegisterMethod(@TCanvas.TextWidth, 'TextWidth');
{$IFNDEF CLX}
    RegisterPropertyHelper(@TCanvas.HandleR, @TCanvas.HandleW, 'Handle');
{$ENDIF}
    RegisterPropertyHelper(@TCanvas.PixelsR, @TCanvas.PixelsW, 'Pixels');
  end;
end;


{$ELSE}

{$IFNDEF CLX}
procedure TCanvasHandleR(Self: TCanvas; var T: HDC); begin T := Self.Handle; end;
procedure TCanvasHandleW(Self: TCanvas; T: HDC); begin Self.Handle:= T; end;
{$ENDIF}

procedure TCanvasPixelsR(Self: TCanvas; var T: Longint; X,Y: Longint); begin T := Self.Pixels[X,Y]; end;
procedure TCanvasPixelsW(Self: TCanvas; T, X, Y: Longint); begin Self.Pixels[X,Y]:= T; end;
{$IFDEF FPC}
procedure TCanvasArc(Self : TCanvas; X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer); begin Self.Arc(X1, Y1, X2, Y2, X3, Y3, X4, Y4); end;
procedure TCanvasChord(Self : TCanvas; X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer); begin self.Chord(X1, Y1, X2, Y2, X3, Y3, X4, Y4); end;
procedure TCanvasRectangle(Self : TCanvas; X1,Y1,X2,Y2 : integer); begin self.Rectangle(x1,y1,x2,y2); end;
procedure TCanvasRoundRect(Self : TCanvas; X1, Y1, X2, Y2, X3, Y3 : integer); begin self.RoundRect(X1, Y1, X2, Y2, X3, Y3); end;
procedure TCanvasEllipse(Self : TCanvas;X1, Y1, X2, Y2: Integer); begin self.Ellipse(X1, Y1, X2, Y2); end;
procedure TCanvasFillRect(Self : TCanvas; const Rect: TRect); begin self.FillRect(rect); end;
procedure TCanvasFloodFill(Self : TCanvas; X, Y: Integer; Color: TColor; FillStyle: TFillStyle); begin self.FloodFill(x,y,color,fillstyle); end;
{$ENDIF}

procedure RIRegisterTCanvas(cl: TPSRuntimeClassImporter); // requires TPersistent
begin
  with Cl.Add(TCanvas) do
  begin
    {$IFNDEF FPC}
    RegisterConstructor(@TCanvas.Create, 'Create');
    {$ENDIF}
{$IFDEF FPC}
    RegisterMethod(@TCanvasArc, 'Arc');
    RegisterMethod(@TCanvasChord, 'Chord');
    RegisterMethod(@TCanvasRectangle, 'Rectangle');
    RegisterMethod(@TCanvasRoundRect, 'RoundRect');
    RegisterMethod(@TCanvasEllipse, 'Ellipse');
    RegisterMethod(@TCanvasFillRect, 'FillRect');
    RegisterMethod(@TCanvasFloodFill, 'FloodFill');
{$ELSE}
    RegisterMethod(@TCanvasArc_P, 'Arc');
    RegisterMethod(@TCanvasChord_P, 'Chord');
    RegisterMethod(@TCanvasRectangle_P, 'Rectangle');
    RegisterMethod(@TCanvasRoundRect_P, 'RoundRect');
    RegisterMethod(@TCanvasEllipse_P, 'Ellipse');
    RegisterMethod(@TCanvasFillRect_P, 'FillRect');
{$IFNDEF CLX}
    RegisterMethod(@TCanvasFloodFill_P, 'FloodFill');
{$ENDIF}
{$ENDIF}
    RegisterMethod(@TCanvasDraw_P, 'Draw');

    RegisterMethod(@TCanvasLineTo_P, 'LineTo');
    RegisterMethod(@TCanvasMoveTo_P, 'MoveTo');
    RegisterMethod(@TCanvasPie_P, 'Pie');
    RegisterMethod(@TCanvasRefresh_P, 'Refresh');
    RegisterMethod(@TCanvas.TextHeight, 'TextHeight');
    RegisterMethod(@TCanvasTextOut_P, 'TextOut');
    RegisterMethod(@TCanvas.TextWidth, 'TextWidth');
{$IFNDEF CLX}
    RegisterPropertyHelper(@TCanvasHandleR, @TCanvasHandleW, 'Handle');
{$ENDIF}
    RegisterPropertyHelper(@TCanvasPixelsR, @TCanvasPixelsW, 'Pixels');
  end;
end;


{$ENDIF class_helper_present}
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}

{$IFDEF DELPHI10UP}{$REGION 'TGraphicsObject'}{$ENDIF}
{$IFDEF class_helper_present}
type
  TGraphicsObject_PSHelper = class helper for TGraphicsObject
  public
    procedure ONCHANGE_W(T: TNotifyEvent);
    procedure ONCHANGE_R(var T: TNotifyEvent);
  end;

procedure TGraphicsObject_PSHelper.ONCHANGE_W(T: TNotifyEvent); begin Self.OnChange := t; end;
procedure TGraphicsObject_PSHelper.ONCHANGE_R(var T: TNotifyEvent); begin T :=Self.OnChange; end;


procedure RIRegisterTGRAPHICSOBJECT(Cl: TPSRuntimeClassImporter);
begin
  with Cl.Add(TGraphicsObject) do
  begin
    RegisterEventPropertyHelper(@TGraphicsObject.ONCHANGE_R, @TGraphicsObject.ONCHANGE_W, 'OnChange');
  end;
end;
{$ELSE}
procedure TGRAPHICSOBJECTONCHANGE_W(Self: TGraphicsObject; T: TNotifyEvent); begin Self.OnChange := t; end;
procedure TGRAPHICSOBJECTONCHANGE_R(Self: TGraphicsObject; var T: TNotifyEvent); begin T :=Self.OnChange; end;

procedure RIRegisterTGRAPHICSOBJECT(Cl: TPSRuntimeClassImporter);
begin
  with Cl.Add(TGRAPHICSOBJECT) do
  begin
    RegisterEventPropertyHelper(@TGRAPHICSOBJECTONCHANGE_R, @TGRAPHICSOBJECTONCHANGE_W, 'OnChange');
  end;
end;
{$ENDIF class_helper_present}
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}

{$IFDEF DELPHI10UP}{$REGION 'TPen'}{$ENDIF}
procedure RIRegisterTPEN(Cl: TPSRuntimeClassImporter);
begin
  with Cl.Add(TPen) do
  begin
    RegisterConstructor(@TPEN.CREATE, 'Create');
  end;
end;
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}

{$IFDEF DELPHI10UP}{$REGION 'TBrush'}{$ENDIF}
procedure RIRegisterTBRUSH(Cl: TPSRuntimeClassImporter);
begin
  with Cl.Add(TBrush) do
  begin
    RegisterConstructor(@TBRUSH.CREATE, 'Create');
  end;
end;
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}

{$IFDEF DELPHI10UP}{$REGION 'TGraphic'}{$ENDIF}
{$IFDEF class_helper_present}
type
  TGraphic_PSHelper = class helper for TGraphic
  public
    procedure OnChange_W(const T: TNotifyEvent);
    procedure OnChange_R(var T: TNotifyEvent);
    procedure Width_W(const T: Integer);
    procedure Width_R(var T: Integer);
    procedure Modified_W(const T: Boolean);
    procedure Modified_R(var T: Boolean);
    procedure Height_W(const T: Integer);
    procedure Height_R(var T: Integer);
    procedure Empty_R(var T: Boolean);
  end;

procedure TGraphic_PSHelper.OnChange_W(const T: TNotifyEvent); begin Self.OnChange := T; end;
procedure TGraphic_PSHelper.OnChange_R(var T: TNotifyEvent); begin T := Self.OnChange; end;
procedure TGraphic_PSHelper.Width_W(const T: Integer); begin Self.Width := T; end;
procedure TGraphic_PSHelper.Width_R(var T: Integer); begin T := Self.Width; end;
procedure TGraphic_PSHelper.Modified_W(const T: Boolean); begin Self.Modified := T; end;
procedure TGraphic_PSHelper.Modified_R(var T: Boolean); begin T := Self.Modified; end;
procedure TGraphic_PSHelper.Height_W(const T: Integer); begin Self.Height := T; end;
procedure TGraphic_PSHelper.Height_R(var T: Integer); begin T := Self.Height; end;
procedure TGraphic_PSHelper.Empty_R(var T: Boolean); begin T := Self.Empty; end;

procedure RIRegisterTGraphic(CL: TPSRuntimeClassImporter);
begin
  with CL.Add(TGraphic) do
  begin
    RegisterVirtualConstructor(@TGraphic.Create, 'Create');
    RegisterVirtualMethod(@TGraphic.LoadFromFile, 'LoadFromFile');
    RegisterVirtualMethod(@TGraphic.SaveToFile, 'SaveToFile');
    RegisterPropertyHelper(@TGraphic.Empty_R,nil,'Empty');
    RegisterPropertyHelper(@TGraphic.Height_R,@TGraphic.Height_W,'Height');
    RegisterPropertyHelper(@TGraphic.Width_R,@TGraphic.Width_W,'Width');
    RegisterEventPropertyHelper(@TGraphic.OnChange_R,@TGraphic.OnChange_W,'OnChange');

    {$IFNDEF PS_MINIVCL}
    RegisterPropertyHelper(@TGraphic.Modified_R,@TGraphic.Modified_W,'Modified');
    {$ENDIF}
  end;
end;

{$ELSE}
procedure TGraphicOnChange_W(Self: TGraphic; const T: TNotifyEvent); begin Self.OnChange := T; end;
procedure TGraphicOnChange_R(Self: TGraphic; var T: TNotifyEvent); begin T := Self.OnChange; end;
procedure TGraphicWidth_W(Self: TGraphic; const T: Integer); begin Self.Width := T; end;
procedure TGraphicWidth_R(Self: TGraphic; var T: Integer); begin T := Self.Width; end;
procedure TGraphicModified_W(Self: TGraphic; const T: Boolean); begin Self.Modified := T; end;
procedure TGraphicModified_R(Self: TGraphic; var T: Boolean); begin T := Self.Modified; end;
procedure TGraphicHeight_W(Self: TGraphic; const T: Integer); begin Self.Height := T; end;
procedure TGraphicHeight_R(Self: TGraphic; var T: Integer); begin T := Self.Height; end;
procedure TGraphicEmpty_R(Self: TGraphic; var T: Boolean); begin T := Self.Empty; end;

procedure RIRegisterTGraphic(CL: TPSRuntimeClassImporter);
begin
  with CL.Add(TGraphic) do
  begin
    RegisterVirtualConstructor(@TGraphic.Create, 'Create');
    RegisterVirtualMethod(@TGraphic.LoadFromFile, 'LoadFromFile');
    RegisterVirtualMethod(@TGraphic.SaveToFile, 'SaveToFile');
    RegisterPropertyHelper(@TGraphicEmpty_R,nil,'Empty');
    RegisterPropertyHelper(@TGraphicHeight_R,@TGraphicHeight_W,'Height');
    RegisterPropertyHelper(@TGraphicWidth_R,@TGraphicWidth_W,'Width');
    RegisterEventPropertyHelper(@TGraphicOnChange_R,@TGraphicOnChange_W,'OnChange');

    {$IFNDEF PS_MINIVCL}
    RegisterPropertyHelper(@TGraphicModified_R,@TGraphicModified_W,'Modified');
    {$ENDIF}
  end;
end;

{$ENDIF class_helper_present}
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}

{ Members that are virtual in some or all Delphi versions, bound through routines that call them
  by name: the compiler then calls through the object's virtual method table wherever the member is
  virtual, so a descendant's override runs.  Bound by address, a script ran this class's own code
  whatever the object's class. }
procedure TBitmapLoadFromStream_P(Self: TBitmap; Stream: TStream);
begin
  Self.LoadFromStream(Stream);
end;

procedure TBitmapSaveToStream_P(Self: TBitmap; Stream: TStream);
begin
  Self.SaveToStream(Stream);
end;

{$IFNDEF CLX}{$IFNDEF FPC}
procedure TBitmapLoadFromClipboardFormat_P(Self: TBitmap; AFormat: Word; AData: THandle; APalette: HPALETTE);
begin
  Self.LoadFromClipboardFormat(AFormat, AData, APalette);
end;

procedure TBitmapSaveToClipboardFormat_P(Self: TBitmap; var Format: Word; var Data: THandle;
  var APalette: HPALETTE);
begin
  Self.SaveToClipboardFormat(Format, Data, APalette);
end;
{$ENDIF}{$ENDIF}

{$IFDEF DELPHI10UP}{$REGION 'TBitmap'}{$ENDIF}
{$IFDEF class_helper_present}
type
  TBitmap_PSHelper = class helper for TBitmap
  public
    procedure TransparentColor_R(var T: TColor);
    {$IFNDEF CLX}
    {$IFNDEF FPC}
    procedure IgnorePalette_W(const T: Boolean);
    procedure IgnorePalette_R(var T: Boolean);
    {$ENDIF}
    procedure Palette_W(const T: HPALETTE);
    procedure Palette_R(var T: HPALETTE);
    {$ENDIF}
    procedure Monochrome_W(const T: Boolean);
    procedure Monochrome_R(var T: Boolean);
    {$IFNDEF CLX}
    procedure Handle_W(const T: HBITMAP);
    procedure Handle_R(var T: HBITMAP);
    {$ENDIF}
    procedure Canvas_R(var T: TCanvas);
  end;

procedure TBitmap_PSHelper.TransparentColor_R(var T: TColor); begin T := Self.TransparentColor; end;
{$IFNDEF CLX}
{$IFNDEF FPC}
procedure TBitmap_PSHelper.IgnorePalette_W(const T: Boolean); begin Self.IgnorePalette := T; end;
procedure TBitmap_PSHelper.IgnorePalette_R(var T: Boolean); begin T := Self.IgnorePalette; end;
{$ENDIF}
procedure TBitmap_PSHelper.Palette_W(const T: HPALETTE); begin Self.Palette := T; end;
procedure TBitmap_PSHelper.Palette_R(var T: HPALETTE); begin T := Self.Palette; end;
{$ENDIF}
procedure TBitmap_PSHelper.Monochrome_W(const T: Boolean); begin Self.Monochrome := T; end;
procedure TBitmap_PSHelper.Monochrome_R(var T: Boolean); begin T := Self.Monochrome; end;
{$IFNDEF CLX}
procedure TBitmap_PSHelper.Handle_W(const T: HBITMAP); begin Self.Handle := T; end;
procedure TBitmap_PSHelper.Handle_R(var T: HBITMAP); begin T := Self.Handle; end;
{$ENDIF}
procedure TBitmap_PSHelper.Canvas_R(var T: TCanvas); begin T := Self.Canvas; end;

procedure RIRegisterTBitmap(CL: TPSRuntimeClassImporter; Streams: Boolean);
begin
  with CL.Add(TBitmap) do
  begin
    if Streams then begin
      RegisterMethod(@TBitmapLoadFromStream_P, 'LoadFromStream');
      RegisterMethod(@TBitmapSaveToStream_P, 'SaveToStream');
    end;
    RegisterPropertyHelper(@TBitmap.Canvas_R,nil,'Canvas');
{$IFNDEF CLX}
    RegisterPropertyHelper(@TBitmap.Handle_R,@TBitmap.Handle_W,'Handle');
{$ENDIF}

    {$IFNDEF PS_MINIVCL}
{$IFNDEF FPC}
    RegisterMethod(@TBitmap.Dormant, 'Dormant');
{$ENDIF}
    RegisterMethod(@TBitmap.FreeImage, 'FreeImage');
{$IFNDEF CLX}
    {$IFDEF FPC}RegisterMethod(@TBitmap.LoadFromClipboardFormat, 'LoadFromClipboardFormat');{$ELSE}RegisterMethod(@TBitmapLoadFromClipboardFormat_P, 'LoadFromClipboardFormat');{$ENDIF}
{$ENDIF}
    RegisterMethod(@TBitmap.LoadFromResourceName, 'LoadFromResourceName');
    RegisterMethod(@TBitmap.LoadFromResourceID, 'LoadFromResourceID');
{$IFNDEF CLX}
    RegisterMethod(@TBitmap.ReleaseHandle, 'ReleaseHandle');
    RegisterMethod(@TBitmap.ReleasePalette, 'ReleasePalette');
    {$IFDEF FPC}RegisterMethod(@TBitmap.SaveToClipboardFormat, 'SaveToClipboardFormat');{$ELSE}RegisterMethod(@TBitmapSaveToClipboardFormat_P, 'SaveToClipboardFormat');{$ENDIF}
    RegisterPropertyHelper(@TBitmap.Monochrome_R,@TBitmap.Monochrome_W,'Monochrome');
    RegisterPropertyHelper(@TBitmap.Palette_R,@TBitmap.Palette_W,'Palette');
{$IFNDEF FPC}
    RegisterPropertyHelper(@TBitmap.IgnorePalette_R,@TBitmap.IgnorePalette_W,'IgnorePalette');
{$ENDIF}
{$ENDIF}
    RegisterPropertyHelper(@TBitmap.TransparentColor_R,nil,'TransparentColor');
    {$ENDIF}
  end;
end;

{$ELSE}
procedure TBitmapTransparentColor_R(Self: TBitmap; var T: TColor); begin T := Self.TransparentColor; end;
{$IFNDEF CLX}
{$IFNDEF FPC}
procedure TBitmapIgnorePalette_W(Self: TBitmap; const T: Boolean); begin Self.IgnorePalette := T; end;
procedure TBitmapIgnorePalette_R(Self: TBitmap; var T: Boolean); begin T := Self.IgnorePalette; end;
{$ENDIF}
procedure TBitmapPalette_W(Self: TBitmap; const T: HPALETTE); begin Self.Palette := T; end;
procedure TBitmapPalette_R(Self: TBitmap; var T: HPALETTE); begin T := Self.Palette; end;
{$ENDIF}
procedure TBitmapMonochrome_W(Self: TBitmap; const T: Boolean); begin Self.Monochrome := T; end;
procedure TBitmapMonochrome_R(Self: TBitmap; var T: Boolean); begin T := Self.Monochrome; end;
{$IFNDEF CLX}
procedure TBitmapHandle_W(Self: TBitmap; const T: HBITMAP); begin Self.Handle := T; end;
procedure TBitmapHandle_R(Self: TBitmap; var T: HBITMAP); begin T := Self.Handle; end;
{$ENDIF}
procedure TBitmapCanvas_R(Self: TBitmap; var T: TCanvas); begin T := Self.Canvas; end;

procedure RIRegisterTBitmap(CL: TPSRuntimeClassImporter; Streams: Boolean);
begin
  with CL.Add(TBitmap) do
  begin
    if Streams then begin
      RegisterMethod(@TBitmapLoadFromStream_P, 'LoadFromStream');
      RegisterMethod(@TBitmapSaveToStream_P, 'SaveToStream');
    end;
    RegisterPropertyHelper(@TBitmapCanvas_R,nil,'Canvas');
{$IFNDEF CLX}
    RegisterPropertyHelper(@TBitmapHandle_R,@TBitmapHandle_W,'Handle');
{$ENDIF}

    {$IFNDEF PS_MINIVCL}
{$IFNDEF FPC}
    RegisterMethod(@TBitmap.Dormant, 'Dormant');
{$ENDIF}
    RegisterMethod(@TBitmap.FreeImage, 'FreeImage');
{$IFNDEF CLX}
    {$IFDEF FPC}RegisterMethod(@TBitmap.LoadFromClipboardFormat, 'LoadFromClipboardFormat');{$ELSE}RegisterMethod(@TBitmapLoadFromClipboardFormat_P, 'LoadFromClipboardFormat');{$ENDIF}
{$ENDIF}
    RegisterMethod(@TBitmap.LoadFromResourceName, 'LoadFromResourceName');
    RegisterMethod(@TBitmap.LoadFromResourceID, 'LoadFromResourceID');
{$IFNDEF CLX}
    RegisterMethod(@TBitmap.ReleaseHandle, 'ReleaseHandle');
    RegisterMethod(@TBitmap.ReleasePalette, 'ReleasePalette');
    {$IFDEF FPC}RegisterMethod(@TBitmap.SaveToClipboardFormat, 'SaveToClipboardFormat');{$ELSE}RegisterMethod(@TBitmapSaveToClipboardFormat_P, 'SaveToClipboardFormat');{$ENDIF}
    RegisterPropertyHelper(@TBitmapMonochrome_R,@TBitmapMonochrome_W,'Monochrome');
    RegisterPropertyHelper(@TBitmapPalette_R,@TBitmapPalette_W,'Palette');
{$IFNDEF FPC}
    RegisterPropertyHelper(@TBitmapIgnorePalette_R,@TBitmapIgnorePalette_W,'IgnorePalette');
{$ENDIF}
{$ENDIF}
    RegisterPropertyHelper(@TBitmapTransparentColor_R,nil,'TransparentColor');
    {$ENDIF}
  end;
end;

{$ENDIF class_helper_present}
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}

{$IFDEF DELPHI10UP}{$REGION 'TPicture'}{$ENDIF}
{$IFDEF class_helper_present}
type
  TPicture_PSHelper = class helper for TPicture
  public
    procedure Bitmap_W(const T: TBitmap);
    procedure Bitmap_R(var T: TBitmap);
  end;

procedure TPicture_PSHelper.Bitmap_W(const T: TBitmap); begin Self.Bitmap := T; end;
procedure TPicture_PSHelper.Bitmap_R(var T: TBitmap); begin T := Self.Bitmap; end;
procedure RIRegisterTPicture(CL: TPSRuntimeClassImporter);
begin
  with CL.Add(TPicture) do
    registerPropertyHelper(@TPicture.Bitmap_R,@TPicture.Bitmap_W,'Bitmap');
end;
{$ELSE}
procedure TPictureBitmap_W(Self: TPicture; const T: TBitmap); begin Self.Bitmap := T; end;
procedure TPictureBitmap_R(Self: TPicture; var T: TBitmap); begin T := Self.Bitmap; end;
procedure RIRegisterTPicture(CL: TPSRuntimeClassImporter);
begin
  with CL.Add(TPicture) do
    registerPropertyHelper(@TPictureBitmap_R,@TPictureBitmap_W,'Bitmap');
end;
{$ENDIF class_helper_present}
{$IFDEF DELPHI10UP}{$ENDREGION}{$ENDIF}

procedure RIRegister_Graphics(Cl: TPSRuntimeClassImporter; Streams: Boolean);
begin
  RIRegisterTGRAPHICSOBJECT(cl);
  RIRegisterTFont(Cl);
  RIRegisterTCanvas(cl);
  RIRegisterTPEN(cl);
  RIRegisterTBRUSH(cl);
  RIRegisterTGraphic(CL);
  RIRegisterTBitmap(CL, Streams);
  RIRegisterTPicture(CL);
end;

// PS_MINIVCL changes by Martijn Laan

end.





