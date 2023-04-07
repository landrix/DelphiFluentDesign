unit CFX.Controls;

interface
  uses
    Vcl.Graphics, Classes, Types, CFX.Types, CFX.UIConsts, SysUtils,
    CFX.Graphics, CFX.VarHelpers, CFX.ThemeManager, Vcl.Controls,
    CFX.PopupMenu;

  type
    // Control
    FXTransparentControl = class(TCustomTransparentControl)
    private
      FPopupMenu: FXPopupMenu;

    protected
      property PopupMenu: FXPopupMenu read FPopupMenu write FPopupMenu;

      procedure MouseUp(Button : TMouseButton; Shift: TShiftState; X, Y : integer); override;

    published

    public
    end;

implementation

{ FXTransparentControl }

procedure FXTransparentControl.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
begin
  inherited;
  if (Button = mbRight) and Assigned(PopupMenu) then
    FPopupMenu.PopupAtPoint( ClientToScreen(Point(X,Y)) );
end;

end.
