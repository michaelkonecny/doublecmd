{
   Double Commander
   -------------------------------------------------------------------------
   Drive free space indicator colors options page

   Copyright (C) 2006-2025 Alexander Koblov (alexx2000@mail.ru)

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with this program; if not, write to the Free Software Foundation, Inc.,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
}

unit fOptionsDriveFreeSpaceColors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, ExtCtrls, KASComboBox, fOptionsFrame;

type

  { TfrmOptionsDriveFreeSpaceColors }

  TfrmOptionsDriveFreeSpaceColors = class(TOptionsEditor)
    cbbUseGradientInd: TCheckBox;
    cbIndColor: TKASColorBoxButton;
    cbIndBackColor: TKASColorBoxButton;
    cbIndThresholdColor: TKASColorBoxButton;
    lblIndColor: TLabel;
    lblIndBackColor: TLabel;
    lblIndThresholdColor: TLabel;
    pbxFakeDrive: TPaintBox;
    procedure cbbUseGradientIndChange(Sender: TObject);
    procedure cbIndColorChange(Sender: TObject);
    procedure pbxFakeDriveClick(Sender: TObject);
    procedure pbxFakeDrivePaint(Sender: TObject);
  protected
    procedure Load; override;
    function Save: TOptionsEditorSaveFlags; override;
  public
    class function GetIconIndex: Integer; override;
    class function GetTitle: String; override;
  end;

implementation

{$R *.lfm}

uses
  Forms, uGlobs, uLng, fMain;

{ TfrmOptionsDriveFreeSpaceColors }

procedure TfrmOptionsDriveFreeSpaceColors.cbbUseGradientIndChange(Sender: TObject);
var
  vNoGradient: Boolean;
begin
  vNoGradient := not (cbbUseGradientInd.Checked);

  lblIndThresholdColor.Enabled := vNoGradient;
  lblIndColor.Enabled := vNoGradient;
  lblIndBackColor.Enabled := vNoGradient;

  cbIndThresholdColor.Enabled := vNoGradient;
  cbIndColor.Enabled := vNoGradient;
  cbIndBackColor.Enabled := vNoGradient;

  pbxFakeDrive.Repaint;
end;

procedure TfrmOptionsDriveFreeSpaceColors.cbIndColorChange(Sender: TObject);
begin
  pbxFakeDrive.Repaint;
end;

procedure TfrmOptionsDriveFreeSpaceColors.pbxFakeDriveClick(Sender: TObject);
begin
  pbxFakeDrive.Tag:= (pbxFakeDrive.ScreenToClient(Mouse.CursorPos).X * 100) div pbxFakeDrive.Width;
  pbxFakeDrive.Hint:= pbxFakeDrive.Tag.ToString + '%';
  pbxFakeDrive.Repaint;
end;

procedure TfrmOptionsDriveFreeSpaceColors.pbxFakeDrivePaint(Sender: TObject);
begin
  frmMain.PaintDriveFreeBar(pbxFakeDrive, cbbUseGradientInd.Checked,
    cbIndColor.Selected, cbIndThresholdColor.Selected, cbIndBackColor.Selected);
end;

procedure TfrmOptionsDriveFreeSpaceColors.Load;
begin
  with gColors.FreeSpaceInd^ do
  begin
    cbIndColor.Selected:= ForeColor;
    cbIndBackColor.Selected:= BackColor;
    cbIndThresholdColor.Selected:= ThresholdForeColor;
  end;
  cbbUseGradientInd.Checked:= gIndUseGradient;
  cbbUseGradientIndChange(cbbUseGradientInd);
  pbxFakeDrive.Hint:= pbxFakeDrive.Tag.ToString + '%';
end;

function TfrmOptionsDriveFreeSpaceColors.Save: TOptionsEditorSaveFlags;
begin
  Result:= [];
  gIndUseGradient:= cbbUseGradientInd.Checked;
  with gColors.FreeSpaceInd^ do
  begin
    ForeColor := cbIndColor.Selected;
    BackColor := cbIndBackColor.Selected;
    ThresholdForeColor := cbIndThresholdColor.Selected;
  end;
end;

class function TfrmOptionsDriveFreeSpaceColors.GetIconIndex: Integer;
begin
  Result:= 4;
end;

class function TfrmOptionsDriveFreeSpaceColors.GetTitle: String;
begin
  Result:= rsDriveFreeSpaceIndicator;
end;

end.
