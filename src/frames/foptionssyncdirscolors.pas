{
   Double Commander
   -------------------------------------------------------------------------
   Synchronize directories colors options page

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

unit fOptionsSyncDirsColors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls, KASComboBox, fOptionsFrame;

type

  { TfrmOptionsSyncDirsColors }

  TfrmOptionsSyncDirsColors = class(TOptionsEditor)
    cbLeft: TKASColorBoxButton;
    cbRight: TKASColorBoxButton;
    cbUnknown: TKASColorBoxButton;
    cbSelection: TKASColorBoxButton;
    lblLeft: TLabel;
    lblRight: TLabel;
    lblUnknown: TLabel;
    lblSelection: TLabel;
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
  uGlobs, uLng;

{ TfrmOptionsSyncDirsColors }

procedure TfrmOptionsSyncDirsColors.Load;
begin
  with gColors.SyncDirs^ do
  begin
    cbLeft.Selected:= LeftColor;
    cbRight.Selected:= RightColor;
    cbUnknown.Selected:= UnknownColor;
    cbSelection.Selected:= SelectedColor;
  end;
end;

function TfrmOptionsSyncDirsColors.Save: TOptionsEditorSaveFlags;
begin
  Result:= [];
  with gColors.SyncDirs^ do
  begin
    LeftColor:= cbLeft.Selected;
    RightColor:= cbRight.Selected;
    UnknownColor:= cbUnknown.Selected;
    SelectedColor:= cbSelection.Selected;
  end;
end;

class function TfrmOptionsSyncDirsColors.GetIconIndex: Integer;
begin
  Result:= 4;
end;

class function TfrmOptionsSyncDirsColors.GetTitle: String;
begin
  Result:= rsHotkeyCategorySyncDirs;
end;

end.
