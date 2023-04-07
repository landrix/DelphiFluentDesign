unit CFX.PropertyEditors;

interface

uses
  SysUtils,
  Windows,
  Classes,
  Types,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.ExtCtrls,
  Threading,
  System.Generics.Collections,
  Vcl.Menus,
  CFX.Graphics,
  CFX.VarHelpers,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtDlgs,
  DateUtils,
  IOUtils,
  CFX.Utilities,
  CFX.ThemeManager,
  CFX.BlurMaterial,
  CFX.Classes,
  CFX.UIConsts,
  CFX.Colors,
  CFX.Math,
  CFX.GDI,
  CFX.Animations,
  CFX.Types,
  CFX.Forms,
  CFX.FontIcons,
  CFX.Button,
  CFX.PopupMenu,

  // Property Editor
  DesignEditors,
  DesignIntf,
  RTTI,
  TypInfo;

  type
    // Default Edit Form Template
    FXEditForm = class(TForm)
    private
      FMainTitle,
      FSubTitle: string;

      FTitle1,
      FTitle2: TLabel;

      FButtonSave,
      FButtonClose: FXBUtton;

      FAllowCancel: boolean;
      FStyled: boolean;

      const
        ZONE_MARGIN = 20;

      procedure SetSubTitle(const Value: string);
      procedure SetTitle(const Value: string);
      procedure SetAllowCancel(const Value: boolean);

    public
      property Title: string read FMainTitle write SetTitle;
      property SubTitle: string read FSubTitle write SetSubTitle;

      property AllowCancel: boolean read FAllowCancel write SetAllowCancel;
      property Styled: boolean read FStyled write FStyled;

      function ComponentsZone: TRect;
      function Margin: integer;
      function MarginTiny: integer;

      procedure UpdateUI;

      constructor CreateNew(AOwner: TComponent; Dummy: Integer  = 0); override;
      destructor Destroy; override;

    end;

    // Popup Menu Items
    TFXPopupItemsProperty = class(TPropertyEditor)
    public
      procedure Edit; override;
      function GetAttributes: TPropertyAttributes; override;
      function GetValue: string; override;
      procedure SetValue(const Value: string); override;
    end;

    // Icon Selector
    TFXIconSelectProperty = class(TPropertyEditor)
    private
      Item: FXIconSelect;
      Form: FXEditForm;

      LB1,
      LB2: TLabel;

      ImagePicture,
      ImageBitmap: TImage;
      FontIcon: TEdit;

      const
        IMAGEBOX_SIZE = 150;

    public
      procedure Edit; override;
      function GetAttributes: TPropertyAttributes; override;
      function GetValue: string; override;
      procedure SetValue(const Value: string); override;

      procedure ButtonSelect(Sender: TObject);
      procedure ButtonImageAction(Sender: TObject);
      procedure EditInteract(Sender: TObject; var Key: Word; Shift: TShiftState);

      procedure ShowPanel(Index: integer);
    end;

implementation

{ TFXPopupItemsProperty }

procedure TFXPopupItemsProperty.Edit;
var
  PropValue: TValue;
  PropInfo: PPropInfo;
  Items: FXPopupItems;
  Form: TForm;
  V: Variant;
begin
  // get the current value of the property
  PropValue := GetValue;

  // get the property info
  PropInfo := TypInfo.GetPropInfo(GetComponent(0).ClassInfo, 'FXPopupItems');

  if PropValue.IsEmpty then
    Items := []
  else
    // cast the property value to the appropriate type
    Items := FXPopupItems(Pointer(PropValue.GetReferenceToRawData)^);

  ShowMessage( Length(ITems).ToString );

  // modify the items
  SetLength(Items, 0);

  ShowMessage( Length(ITems).ToString );

  // create a variant from the items
  V := TValue.From<FXPopupItems>(Items).AsVariant;

  // set the value of the property
  SetValue(V);

  // notify the designer that the property has been modified
  Modified;
end;

function TFXPopupItemsProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

function TFXPopupItemsProperty.GetValue: string;
begin
  // Return the current value of the property as a string
  Result := '(FXPopupItems)';
end;

procedure TFXPopupItemsProperty.SetValue(const Value: string);
begin
  inherited;
end;

{ TFXIconSelectProperty }

procedure TFXIconSelectProperty.ButtonImageAction(Sender: TObject);
begin
  case FXButton(Sender).Tag of
    (* TPicture *)
    1: begin
      with TOpenPictureDialog.Create(nil) do
        if Execute then
          if TFile.Exists(FileName) then
            begin
              Item.SelectPicture.LoadFromFile(FileName);

              ImagePicture.Picture.Assign( Item.SelectPicture );

              LB1.Hide;
            end;
    end;
    2: begin
      with TSavePictureDialog.Create(nil) do
        begin
          FileName := 'Image.png';
          if Execute then
            if not Item.SelectPicture.Graphic.Empty then
              Item.SelectPicture.SaveToFile(FileName);
        end;
    end;
    3: begin
      Item.SelectPicture.Free;
      Item.SelectPicture := TPicture.Create;

      ImagePicture.Picture.Assign( Item.SelectPicture );

      LB1.Show;
    end;

    (* TBitMap *)
    4: begin
      with TOpenPictureDialog.Create(nil) do
        begin
          Filter := 'Bitmaps (*.bmp)|*.bmp|All Files|*';
          if Execute then
            if TFile.Exists(FileName) then
              begin
                Item.SelectBitmap.LoadFromFile(FileName);

                ImageBitMap.Picture.Assign( Item.SelectBitmap );

                LB2.Hide;
              end;
        end;
    end;
    5: begin
      with TSavePictureDialog.Create(nil) do
        begin
          FileName := 'BitMap.bmp';
          Filter := 'Bitmaps (*.bmp)|*.bmp|All Files|*';

          if Execute then
            if not Item.SelectBitmap.Empty then
              Item.SelectBitmap.SaveToFile(FileName);
        end;
    end;
    6: begin
      Item.SelectBitmap.Free;
      Item.SelectBitmap := TBitMap.Create;

      ImageBitMap.Picture.Assign( Item.SelectBitmap );

      LB2.Show;
    end;
  end;
end;

procedure TFXIconSelectProperty.ButtonSelect(Sender: TObject);
var
  I: integer;
begin
  Item.Enabled := FXButton(Sender).Tag <> 1;

  if Item.Enabled then
    Item.IconType := FXImageType(FXButton(Sender).Tag-2);

  for I := 0 to FXButton(Sender).Parent.ControlCount - 1 do
    if FXButton(Sender).Parent.Controls[I] is FXButton then
      FXButton(FXButton(Sender).Parent.Controls[I]).FlatButton := false;

  FXButton(Sender).FlatButton := true;

  ShowPanel( FXButton(Sender).Tag - 1 );
end;

procedure TFXIconSelectProperty.Edit;
var
  ListPanel, Panel: TPanel;
  I: integer;
  ItemOrig: FXIconSelect;
begin
  inherited;
  // Item
  ItemOrig := FXIconSelect(Self.GetOrdValue);
  Item := FXIconSelect.Create(nil);
  Item.Assign(ItemOrig);

  // Update Theme
  ThemeManager.UpdateThemeInformation;

  // Form
  Form := FXEditForm.CreateNew(Application);
  try
    with Form do
      begin
        Caption := 'Editing Icon Item';

        Title := 'Edit Selected Image';
        SubTitle := 'Choose a icon';

        Form.Height := Form.Height + 100;

        // Create Components
        ListPanel := TPanel.Create(Form);
        with ListPanel do
          begin
            Parent := Form;

            Top := Form.ComponentsZone.Top;
            Left := Form.ComponentsZone.Left;
            Width := Form.ComponentsZone.Width;
            Height := 100;

            BevelOuter := bvNone;
            ParentColor := true;
          end;

        with FXButton.Create(ListPanel) do
          begin
            Parent := ListPanel;

            BSegoeIcon := #$F714;
            Text := 'Font Icon';
            Tag := 5;
          end;

        with FXButton.Create(ListPanel) do
          begin
            Parent := ListPanel;

            BSegoeIcon := #$E8B9;
            Text := 'Image List';
            Tag := 4;
          end;

        with FXButton.Create(ListPanel) do
          begin
            Parent := ListPanel;

            BSegoeIcon := #$E8BA;
            Text := 'Bitmap';
            Tag := 3;
          end;

        with FXButton.Create(ListPanel) do
          begin
            Parent := ListPanel;

            BSegoeIcon := #$EB9F;
            Text := 'Picture';
            Tag := 2;
          end;

        with FXButton.Create(ListPanel) do
          begin
            Parent := ListPanel;

            BSegoeIcon := #$E711;
            Text := 'None';
            Tag := 1;
          end;

          // Create Panels
          (* TPicture *)
          Panel := TPanel.Create(Form);
          with Panel do
            begin
              Parent := Form;
              Tag := 1;

              BevelOuter := bvNone;
              ParentBackground := false;
              Color := ThemeManager.SystemColor.BackGroundInterior;

              Top := ListPanel.BoundsRect.Bottom + Form.MarginTiny;
              Left := Form.ComponentsZone.Left;
              Width := Form.ComponentsZone.Width;
              Height := Form.ComponentsZone.Bottom - Top;

              LB1 := TLabel.Create(Panel);
              with LB1 do
                begin
                  Parent := Panel;

                  AutoSize := false;
                  Transparent := false;
                  Color := ThemeManager.SystemColor.Accent;

                  Layout := tlCenter;
                  Alignment := taCenter;


                  //Font.Name := ThemeManager.IconFont;
                  Caption := 'No image loaded';

                  Top := Form.MarginTiny;
                  Left := Form.MarginTiny;

                  Width := IMAGEBOX_SIZE;
                  Height := IMAGEBOX_SIZE;
                end;

              ImagePicture := TImage.Create(Panel);
              with ImagePicture do
                begin
                  Parent := Panel;

                  Proportional := true;
                  Center := true;

                  Top := Form.MarginTiny;
                  Left := Form.MarginTiny;

                  Width := IMAGEBOX_SIZE;
                  Height := IMAGEBOX_SIZE;

                  // Update Image
                  Picture.Assign( Item.SelectPicture );

                  LB1.Visible := (Item.SelectPicture.Graphic = nil) or Item.SelectPicture.Graphic.Empty;
                end;

              with FXButton.Create(Panel) do
                begin
                  Parent := Panel;

                  Top := Form.MarginTiny;
                  Left := Form.MarginTiny + IMAGEBOX_SIZE + Form.Margin;

                  Width := IMAGEBOX_SIZE;

                  Text := 'Browse';

                  ButtonIcon := cicSegoeFluent;
                  BSegoeIcon := #$E7C5;

                  Tag := 1;
                  OnClick := ButtonImageAction;
                end;

              with FXButton.Create(Panel) do
                begin
                  Parent := Panel;

                  Top := Form.MarginTiny + Height + Form.MarginTiny;
                  Left := Form.MarginTiny + IMAGEBOX_SIZE + Form.Margin;

                  Width := IMAGEBOX_SIZE;

                  Text := 'Save';

                  ButtonIcon := cicSegoeFluent;
                  BSegoeIcon := #$EA35;

                  Tag := 2;
                  OnClick := ButtonImageAction;
                end;

              with FXButton.Create(Panel) do
                begin
                  Parent := Panel;

                  Top := Form.MarginTiny + (Height + Form.MarginTiny) * 2;
                  Left := Form.MarginTiny + IMAGEBOX_SIZE + Form.Margin;

                  Width := IMAGEBOX_SIZE;

                  Text := 'Clear';

                  ButtonIcon := cicSegoeFluent;
                  BSegoeIcon := #$ED62;

                  Tag := 3;
                  OnClick := ButtonImageAction;
                end;
            end;

          (* TBitMap *)
          Panel := TPanel.Create(Form);
          with Panel do
            begin
              Parent := Form;
              Tag := 2;

              BevelOuter := bvNone;
              ParentBackground := false;
              Color := ThemeManager.SystemColor.BackGroundInterior;

              Top := ListPanel.BoundsRect.Bottom + Form.MarginTiny;
              Left := Form.ComponentsZone.Left;
              Width := Form.ComponentsZone.Width;
              Height := Form.ComponentsZone.Bottom - Top;

              LB2 := TLabel.Create(Panel);
              with LB2 do
                begin
                  Parent := Panel;

                  AutoSize := false;
                  Transparent := false;
                  Color := ThemeManager.SystemColor.Accent;

                  Layout := tlCenter;
                  Alignment := taCenter;


                  //Font.Name := ThemeManager.IconFont;
                  Caption := 'No bitmap loaded';

                  Top := Form.MarginTiny;
                  Left := Form.MarginTiny;

                  Width := IMAGEBOX_SIZE;
                  Height := IMAGEBOX_SIZE;
                end;

              ImageBitmap := TImage.Create(Panel);
              with ImageBitmap do
                begin
                  Parent := Panel;

                  Proportional := true;
                  Center := true;

                  Top := Form.MarginTiny;
                  Left := Form.MarginTiny;

                  Width := IMAGEBOX_SIZE;
                  Height := IMAGEBOX_SIZE;

                  // Update Image
                  Picture.Assign( Item.SelectBitmap );

                  LB2.Visible := Item.SelectBitmap.Empty;
                end;

              with FXButton.Create(Panel) do
                begin
                  Parent := Panel;

                  Top := Form.MarginTiny;
                  Left := Form.MarginTiny + IMAGEBOX_SIZE + Form.Margin;

                  Width := IMAGEBOX_SIZE;

                  Text := 'Browse';

                  ButtonIcon := cicSegoeFluent;
                  BSegoeIcon := #$E7C5;

                  Tag := 4;
                  OnClick := ButtonImageAction;
                end;

              with FXButton.Create(Panel) do
                begin
                  Parent := Panel;

                  Top := Form.MarginTiny + Height + Form.MarginTiny;
                  Left := Form.MarginTiny + IMAGEBOX_SIZE + Form.Margin;

                  Width := IMAGEBOX_SIZE;

                  Text := 'Save';

                  ButtonIcon := cicSegoeFluent;
                  BSegoeIcon := #$EA35;

                  Tag := 5;
                  OnClick := ButtonImageAction;
                end;

              with FXButton.Create(Panel) do
                begin
                  Parent := Panel;

                  Top := Form.MarginTiny + (Height + Form.MarginTiny) * 2;
                  Left := Form.MarginTiny + IMAGEBOX_SIZE + Form.Margin;

                  Width := IMAGEBOX_SIZE;

                  Text := 'Clear';

                  ButtonIcon := cicSegoeFluent;
                  BSegoeIcon := #$ED62;

                  Tag := 6;
                  OnClick := ButtonImageAction;
                end;
            end;

        (* Image List *)
        Panel := TPanel.Create(Form);
          with Panel do
            begin
              Parent := Form;
              Tag := 3;

              BevelOuter := bvNone;
              ParentBackground := false;
              Color := ThemeManager.SystemColor.BackGroundInterior;

              Top := ListPanel.BoundsRect.Bottom + Form.MarginTiny;
              Left := Form.ComponentsZone.Left;
              Width := Form.ComponentsZone.Width;
              Height := Form.ComponentsZone.Bottom - Top;

              Caption := 'Work in progress...';
            end;

        (* Font Icon *)
        Panel := TPanel.Create(Form);
          with Panel do
            begin
              Parent := Form;
              Tag := 4;

              BevelOuter := bvNone;
              ParentBackground := false;
              Color := ThemeManager.SystemColor.BackGroundInterior;

              Top := ListPanel.BoundsRect.Bottom + Form.MarginTiny;
              Left := Form.ComponentsZone.Left;
              Width := Form.ComponentsZone.Width;
              Height := Form.ComponentsZone.Bottom - Top;

              Caption := '';

              with TLabel.Create(Panel) do
                begin
                  Parent := Panel;

                  Left := Form.MarginTiny;
                  Top := Form.MarginTiny;

                  Width := Panel.Width - Left * 2;

                  AutoSize := false;
                  WordWrap := true;
                  Caption := 'Paste the Font Unicode Character below, or enter the Unicode Point and press enter';

                  Height := Form.Margin * 4 - Top;

                  OnKeyUp := EditInteract;
                end;

              FontIcon := TEdit.Create(Panel);
              with FontIcon do
                begin
                  Parent := Panel;

                  Left := Form.MarginTiny;
                  Top := Form.Margin * 4;

                  Color := ThemeManager.SystemColor.BackGround;

                  Width := Panel.Width - Left * 2;
                  Alignment := taCenter;

                  Font.Size := 50;
                  Font.Name := ThemeManager.IconFont;

                  OnKeyUp := EditInteract;

                  // Load Icon
                  Text := Item.SelectSegoe;
                end;
            end;

        // Prepare Buttons
        for I := 0 to ListPanel.ControlCount - 1 do
          if ListPanel.Controls[I] is FXButton then
            with FXButton(ListPanel.Controls[I]) do
              begin
                Align := alLeft;
                AlignWithMargins := true;
                ButtonIcon := cicSegoeFluent;

                BImageLayout := cpTop;

                Width := ListPanel.Width div 5 - Margins.Left * 2;

                OnClick := ButtonSelect;

                FlatButton := ((Tag = 1) and (not Item.Enabled)) or
                              (Item.Enabled and (Tag - 2 = integer(Item.IconType)));

                if FlatButton then
                  ShowPanel( Tag - 1 );
              end;

      end;

      // Save?
      if Form.ShowModal = mrOk then
        Self.SetOrdValue(Integer(Item));
  finally
    Form.Free;
  end;
end;

procedure TFXIconSelectProperty.EditInteract(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Icon: string;
begin
  try
    if Length(FontIcon.Text) = 4 then
      begin
        Icon := UnicodeToString(FontIcon.Text);

        FontIcon.Text := Icon;
      end;
  except

  end;

  // Update Icon
  Item.SelectSegoe := FontIcon.Text;
end;

function TFXIconSelectProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

function TFXIconSelectProperty.GetValue: string;
begin
  Result := '(FXIconSelect)';
end;

procedure TFXIconSelectProperty.SetValue(const Value: string);
begin
  inherited;
end;

procedure TFXIconSelectProperty.ShowPanel(Index: integer);
var
  I: Integer;
begin
  with Form do
    for I := 0 to ControlCount - 1 do
      if Controls[I] is TPanel then
        if (Controls[I] as TPanel).Tag > 0 then
          TPanel(Controls[I]).Visible := TPanel(Controls[I]).Tag = Index;
end;

{ FXEditForm }

function FXEditForm.ComponentsZone: TRect;
begin
  Result := Rect(ZONE_MARGIN, FTitle2.BoundsRect.Bottom + ZONE_MARGIN div 2, ClientWidth - ZONE_MARGIN, FButtonSave.Top - ZONE_MARGIN div 2);
end;

constructor FXEditForm.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  inherited;

  // Defaults
  FMainTitle := 'Title';
  FSubTitle := 'Sub title';

  FAllowCancel := true;
  FStyled := true;

  // Form
  BorderIcons := [biSystemMenu];
  BorderStyle := bsSingle;
  Position := poMainFormCenter;

  Font.Name := 'Segoe UI';
  Font.Size := 12;

  Caption := 'Class Editor';

  // Theme
  if Styled then
    if GetAppsUseDarkTheme then
      begin
        Color := DEFAULT_DARK_BACKGROUND_COLOR;
        Font.Color := DEFAULT_DARK_FOREGROUND_COLOR;
      end;

  // Labels
  FTitle1 := TLabel.Create(Self);
  with FTitle1 do
    begin
      Parent  := Self;

      Left := ZONE_MARGIN;
      Top := ZONE_MARGIN div 2;

      Font.Size := 18;
      Font.Name := 'Segoe UI Bold';
    end;

  FTitle2 := TLabel.Create(Self);
  with FTitle2 do
    begin
      Parent  := Self;

      Left := ZONE_MARGIN;
      Top := FTitle1.Top + FTitle1.Height;

      Font.Size := 14;
      Font.Name := 'Segoe UI SemiBold';
    end;

  // Buttons
  FButtonSave := FXButton.Create(Self);
  with FButtonSave do
    begin
      Parent  := Self;

      Left := Self.ClientWidth - Width - ZONE_MARGIN;
      Top := Self.ClientHeight - Height - ZONE_MARGIN div 2;

      Text := 'Save';
      ButtonIcon := cicYes;

      Default := true;

      ModalResult := mrOk;

      Anchors := [akBottom, akRight];
    end;

  FButtonClose := FXButton.Create(Self);
  with FButtonClose do
    begin
      Parent  := Self;

      Left := Self.ClientWidth - Width - ZONE_MARGIN - FButtonSave.Width - 10;
      Top := Self.ClientHeight - Height - ZONE_MARGIN div 2;

      Text := 'Close';
      ButtonIcon := cicNo;

      Cancel := true;

      FlatButton := true;

      ModalResult := mrCancel;

      Anchors := [akBottom, akRight];
    end;

  // Size
  Width := 500;
  Height := 350;

  // Update
  UpdateUI;
end;

destructor FXEditForm.Destroy;
begin

  inherited;
end;

function FXEditForm.Margin: integer;
begin
  Result := ZONE_MARGIN;
end;

function FXEditForm.MarginTiny: integer;
begin
  Result := ZONE_MARGIN div 2;
end;

procedure FXEditForm.SetAllowCancel(const Value: boolean);
begin
  FAllowCancel := Value;
  UpdateUI;
end;

procedure FXEditForm.SetSubTitle(const Value: string);
begin
  FSubTitle := Value;
  UpdateUI;
end;

procedure FXEditForm.SetTitle(const Value: string);
begin
  FMainTitle := Value;
  UpdateUI;
end;

procedure FXEditForm.UpdateUI;
begin
  // New Values
  FTitle1.Caption := Title;
  FTitle2.Caption := SubTitle;

  // Cancel
  FButtonClose.Visible := FAllowCancel;
end;

{ Initialize }
initialization
  RegisterPropertyEditor(TypeInfo(FXIconSelect), nil, '', TFXIconSelectProperty);

  RegisterPropertyEditor(TypeInfo(FXPopupItems), nil, '', TFXPopupItemsProperty);
  (*
  Parameter 1: Edited Class for Property Edit
  Parameter 2: Compoent to work with. Enter nil for it to work with all
  Parameter 3: Property Name, leave blank to work with any name
  Parameter 4: Property Edit Class
  *)

end.
