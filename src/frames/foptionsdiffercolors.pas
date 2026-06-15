{
   Double Commander
   -------------------------------------------------------------------------
   Differ colors options page

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

unit fOptionsDifferColors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls, DividerBevel, KASComboBox, fOptionsFrame;

type

  { TfrmOptionsDifferColors }

  TfrmOptionsDifferColors = class(TOptionsEditor)
    cbAdded: TKASColorBoxButton;
    cbDeleted: TKASColorBoxButton;
    cbModified: TKASColorBoxButton;
    cbModifiedBinary: TKASColorBoxButton;
    dbTextMode: TDividerBevel;
    dbBinaryMode: TDividerBevel;
    DividerBevel4: TDividerBevel;
    DividerBevel6: TDividerBevel;
    lblAdded: TLabel;
    lblDeleted: TLabel;
    lblModified: TLabel;
    lblModifiedBinary: TLabel;
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

{ TfrmOptionsDifferColors }

procedure TfrmOptionsDifferColors.Load;
begin
  with gColors.Differ^ do
  begin
    cbAdded.Selected:= AddedColor;
    cbDeleted.Selected:= DeletedColor;
    cbModified.Selected:= ModifiedColor;
    cbModifiedBinary.Selected:= ModifiedBinaryColor;
  end;
end;

function TfrmOptionsDifferColors.Save: TOptionsEditorSaveFlags;
begin
  Result:= [];
  with gColors.Differ^ do
  begin
    AddedColor:= cbAdded.Selected;
    DeletedColor:= cbDeleted.Selected;
    ModifiedColor:= cbModified.Selected;
    ModifiedBinaryColor:= cbModifiedBinary.Selected;
  end;
end;

class function TfrmOptionsDifferColors.GetIconIndex: Integer;
begin
  Result:= 4;
end;

class function TfrmOptionsDifferColors.GetTitle: String;
begin
  Result:= rsToolDiffer;
end;

end.
