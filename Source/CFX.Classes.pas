unit CFX.Classes;

interface
  uses
    Vcl.Graphics, Classes, Types, CFX.Types, CFX.UIConsts, SysUtils,
    CFX.Graphics, CFX.VarHelpers, CFX.ThemeManager, Vcl.Controls,
    TypInfo;

  type
    // Base Clases
    FXComponent = class(TComponent)

    end;

    // Persistent
    TMPersistent = class(TPersistent)
      Owner : TPersistent;
      constructor Create(AOwner : TPersistent); overload; virtual;
    end;

    TAssignPersistent = class(TMPersistent)
    public
      procedure Assign(Source: TPersistent); override;
    end;

    // Icon
    FXIconSelect = class(TMPersistent)
    private
      FEnabled: boolean;

      FType: FXImageType;
      FPicture: TPicture;
      FBitMap: TBitMap;
      FSegoeText: string;
      FImageIndex: integer;

      procedure SetBitMap(const Value: TBitMap);
      procedure SetPicture(const Value: TPicture);

    published
      property Enabled: boolean read FEnabled write FEnabled default False;
      property IconType: FXImageType read FType write FType default fitSegoeIcon;

      property SelectPicture: TPicture read FPicture write SetPicture;
      property SelectBitmap: TBitMap read FBitMap write SetBitMap;
      property SelectSegoe: string read FSegoeText write FSegoeText;
      property SelectImageIndex: integer read FImageIndex write FImageIndex default -1;

    public
      constructor Create(AOwner : TPersistent); override;
      destructor Destroy; override;

      procedure Assign(Source: TPersistent); override;

      procedure DrawIcon(Canvas: TCanvas; Rectangle: TRect);

      procedure FreeUnusedAssets;
    end;

implementation

{ FXIconSelect }

procedure FXIconSelect.Assign(Source: TPersistent);
begin
  with FXIconSelect(Source) do
    begin
      Self.FEnabled := FEnabled;

      Self.FType := FType;

      Self.FPicture.Assign(FPicture);
      Self.FBitMap.Assign(FBitMap);
      Self.FSegoeText := FSegoeText;
      Self.FImageIndex := FImageIndex;
    end;
end;

constructor FXIconSelect.Create(AOwner : TPersistent);
begin
  inherited;
  Enabled := false;

  FPicture := TPicture.Create;
  FBitMap := TBitMap.Create;

  IconType := fitSegoeIcon;
  FSegoeText := SEGOE_UI_STAR;
end;

destructor FXIconSelect.Destroy;
begin
  FreeAndNil(FPicture);
  FreeAndNil(FBitMap);

  inherited;
end;

procedure FXIconSelect.DrawIcon(Canvas: TCanvas; Rectangle: TRect);
var
  TextDraw: string;
begin
  case IconType of
    fitImage: DrawImageInRect( Canvas, Rectangle, SelectPicture.Graphic, dmCenterFit );
    fitBitMap: DrawImageInRect( Canvas, Rectangle, SelectBitmap, dmCenterFit );
    fitImageList: (* Work In Progress;*);
    fitSegoeIcon: begin
      TextDraw := SelectSegoe;

      Canvas.Font.Name := ThemeManager.IconFont;

      Canvas.TextRect( Rectangle, TextDraw, [tfSingleLine, tfCenter, tfVerticalCenter] )
    end;
  end;
end;

procedure FXIconSelect.FreeUnusedAssets;
begin
  if (IconType <> fitImage) and (FPicture <> nil) and (not FPicture.Graphic.Empty) then
    FPicture.Free;

  if (IconType <> fitBitMap) and (FBitMap <> nil) and (not FBitMap.Empty) then
    FBitMap.Free;
end;

procedure FXIconSelect.SetBitMap(const Value: TBitMap);
begin
  if FBitmap = nil then
    FBitmap := TBitMap.Create;

  FBitmap.Assign(value);
end;

procedure FXIconSelect.SetPicture(const Value: TPicture);
begin
  if FPicture = nil then
    FPicture := TPicture.Create;

  FPicture.Assign(Value);
end;

{ TMPersistent }

constructor TMPersistent.Create(AOwner: TPersistent);
begin
  inherited Create;
  Owner := AOwner;
end;


{ TAssignPersistent }

procedure TAssignPersistent.Assign(Source: TPersistent);
var
  PropList: PPropList;
  PropCount, i: Integer;
begin
  if Source is TAssignPersistent then
  begin
    PropCount := GetPropList(Source.ClassInfo, tkProperties, nil);
    if PropCount > 0 then
    begin
      GetMem(PropList, PropCount * SizeOf(PPropInfo));
      try
        GetPropList(Source.ClassInfo, tkProperties, PropList);
        for i := 0 to PropCount - 1 do
          SetPropValue(Self, string(PropList^[i]^.Name), GetPropValue(Source, string(PropList^[i]^.Name)));
      finally
        FreeMem(PropList);
      end;
    end;
  end
  else
    inherited Assign(Source);
end;

end.
