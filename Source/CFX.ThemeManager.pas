unit CFX.ThemeManager;

{$TYPEINFO ON}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, Registry, System.UITypes,
  Types, Vcl.Graphics, CFX.Colors, CFX.Utilities, Vcl.ExtCtrls, Vcl.Dialogs,
  Vcl.Forms, Classes, Vcl.Themes, Vcl.Styles, CFX.UIConsts,
  CFX.Types;

  type
    // Define Control type to identify on update
    FXControl = interface
      ['{5098EF5C-0451-490D-A0B2-24C414F21A24}']
      function IsContainer: Boolean;
      procedure UpdateTheme(const UpdateChidlren: Boolean);
    end;

    // Theme Manager
    FXThemeManager = class
    private
      FRegistryMonitor: TTimer;

      FDarkTheme: boolean;
      FDarkThemeMode: FXDarkSetting;

      FFormFont,
      FIconFont: string;
      FFormFontHeight: integer;

      FLegacyFontColor: boolean;

      // Private Declarations
      procedure RegMonitorProc(Sender: TObject);
      procedure SetDarkTheme(const Value: boolean);
      procedure SetDarkMode(const Value: FXDarkSetting);

    published
      (* Theme Settings *)
      property DarkTheme: boolean read FDarkTheme write SetDarkTheme;
      property DarkThemeMode: FXDarkSetting read FDarkThemeMode write SetDarkMode;

      (* Global Font Settings *)
      property FormFont: string read FFormFont write FFormFont;
      property FormFontHeight: integer read FFormFontHeight write FFormFontHeight;
      property IconFont: string read FIconFont write FIconFont;
      property LegacyFontColor: boolean read FLegacyFontColor write FLegacyFontColor;

    public
      constructor Create;
      destructor Destroy; override;

      (* Global Colors *)
      var
      SystemColorSet: FXCompleteColorSets;
      SystemColor: FXCompleteColorSet;
      SystemGrayControl: FXSingleColorStateSets;
      SystemAccentInteractStates: FXSingleColorStateSet;

      (* Tool Tip *)
      ToolTip: FXCompleteColorSets;

      (* Functions *)
      function AccentColor: TColor;

      function GetThemePrimaryColor: TColor;

      procedure LoadFontSettings;

      procedure UpdateThemeInformation;

      procedure UpdateColors;
      procedure UpdateSettings;
    end;

  // Functions
  function IsDesigning: boolean;

  function ThemeManager: FXThemeManager;
  function ExtractColor(ColorSet: FXColorSets; ClrType: FXColorType): TColor;

  var
    ThemeMgr: FXThemeManager;

implementation

// In Design Mode
function IsDesigning: boolean;
begin
  if TStyleManager.ActiveStyle.Name = 'Mountain_Mist' then
    Result := true
  else
    Result := false;
end;

// Get Theme Manager
function ThemeManager: FXThemeManager;
begin
  { Create Theme Manager }
    if ThemeMgr = nil then
      ThemeMgr := FXThemeManager.Create;

  Result := ThemeMgr;
end;

function ExtractColor(ColorSet: FXColorSets; ClrType: FXColorType): TColor;
begin
  Result := 0;
  if ThemeManager.DarkTheme then
  case ClrType of
    fctForeground: Result := ColorSet.DarkForeGround;
    fctBackGround: Result := ColorSet.DarkBackGround;
    fctAccent: Result := ColorSet.Accent;
  end
    else
  case ClrType of
    fctForeground: Result := ColorSet.LightForeGround;
    fctBackGround: Result := ColorSet.LightBackGround;
    fctAccent: Result := ColorSet.Accent;
  end;
end;

{ FXThemeManager }

function FXThemeManager.AccentColor: TColor;
begin
  Result := SystemColor.Accent;
end;

constructor FXThemeManager.Create;
begin
  // Load Settings
  if IsDesigning then
    FDarkTheme := false
  else
    FDarkTheme := CFX.Utilities.GetAppsUseDarkTheme;

  DarkThemeMode := fdsAuto;

  FLegacyFontColor := true;

  // Load Font
  LoadFontSettings;

  // Default Color Sets
  SystemColorSet := FXCompleteColorSets.Create;
  SystemColor := FXCompleteColorSet.Create(SystemColorSet, DarkTheme);
  SystemGrayControl := FXSingleColorStateSets.Create;
  SystemAccentInteractStates := FXSingleColorStateSet.Create(SystemGrayControl, DarkTheme);

  UpdateColors;

  ToolTip := FXCompleteColorSets.Create;

  { IGNORE IF IDE MODE! }
  if not IsDesigning then
    begin
      // Registry Monitor
      FRegistryMonitor := TTimer.Create(nil);
      with FRegistryMonitor do
        begin
          Enabled := true;
          Interval := 100;

          OnTimer := RegMonitorProc;
        end;
    end;
end;

destructor FXThemeManager.Destroy;
begin
  if FRegistryMonitor <> nil then
    begin
      FRegistryMonitor.Enabled := false;
      FreeAndNil( FRegistryMonitor );
    end;

  FreeAndNil( ToolTip );
  FreeAndNil( SystemColor );
  FreeAndNil( SystemColorSet );
  FreeAndNil( SystemGrayControl );
end;

function FXThemeManager.GetThemePrimaryColor: TColor;
begin
  if FDarkTheme then
    Result := 0
  else
    Result := TColors.White;
end;

procedure FXThemeManager.LoadFontSettings;
begin
  if Screen.Fonts.IndexOf(FORM_ICON_FONT_NAME_NEW) <> -1 then
    FIconFont := FORM_ICON_FONT_NAME_NEW
  else
    FIconFont := FORM_ICON_FONT_NAME_LEGACY;

  FFormFont := FORM_FONT_NAME;
  FFormFontHeight := FORM_FONT_HEIGHT;
end;

procedure FXThemeManager.RegMonitorProc(Sender: TObject);
begin
  // Manual theme override
  if FDarkThemeMode <> fdsAuto then
    Exit;

  // Check registry
  UpdateThemeInformation;
end;

procedure FXThemeManager.SetDarkMode(const Value: FXDarkSetting);
begin
  FDarkThemeMode := Value;

  if Value <> fdsAuto then
    ThemeManager.DarkTheme := Value = fdsForceDark;
end;

procedure FXThemeManager.SetDarkTheme(const Value: boolean);
begin
  if FDarkTheme <> Value then
  begin
    FDarkTheme := Value;

    UpdateSettings;
  end;
end;

procedure FXThemeManager.UpdateColors;
begin
  SystemColor := FXCompleteColorSet.Create(SystemColorSet, DarkTheme);

  // Get Accent
  SystemColor.Accent := GetAccentColor;

  // Create System Defaults
  SystemColorSet.Accent := AccentColor;
  SystemGrayControl.Accent := AccentColor;
  SystemAccentInteractStates := FXSingleColorStateSet.Create(AccentColor,
                                                      ChangeColorLight(AccentColor, ACCENT_DIFFERENTIATE_CONST),
                                                      ChangeColorLight(AccentColor, -ACCENT_DIFFERENTIATE_CONST));
end;

procedure FXThemeManager.UpdateSettings;
var
  I: Integer;
begin
  UpdateColors;

  for I := 0 to Screen.FormCount - 1 do
    if Screen.Forms[i] <> nil then    
      if Supports(Screen.Forms[i], FXControl) then
        (Screen.Forms[i] as FXControl).UpdateTheme(true);
end;

procedure FXThemeManager.UpdateThemeInformation;
var
  DrkMode: boolean;
begin
  // Get current dark theme state
  DrkMode := GetAppsUseDarkTheme;

  if DrkMode <> DarkTheme then
    begin
      DarkTheme := DrkMode;
    end;
end;

end.

