{
   Double Commander
   -------------------------------------------------------------------------
   Log colors options page

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

unit fOptionsLogColors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls, KASComboBox, fOptionsFrame;

type

  { TfrmOptionsLogColors }

  TfrmOptionsLogColors = class(TOptionsEditor)
    cbInformation: TKASColorBoxButton;
    cbSuccess: TKASColorBoxButton;
    cbError: TKASColorBoxButton;
    lblInformation: TLabel;
    lblSuccess: TLabel;
    lblError: TLabel;
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

{ TfrmOptionsLogColors }

procedure TfrmOptionsLogColors.Load;
begin
  with gColors.Log^ do
  begin
    cbInformation.Selected:= InfoColor;
    cbSuccess.Selected:= SuccessColor;
    cbError.Selected:= ErrorColor;
  end;
end;

function TfrmOptionsLogColors.Save: TOptionsEditorSaveFlags;
begin
  Result:= [];
  with gColors.Log^ do
  begin
    InfoColor:= cbInformation.Selected;
    SuccessColor:= cbSuccess.Selected;
    ErrorColor:= cbError.Selected;
  end;
end;

class function TfrmOptionsLogColors.GetIconIndex: Integer;
begin
  Result:= 4;
end;

class function TfrmOptionsLogColors.GetTitle: String;
begin
  Result:= rsOptionsEditorLog;
end;

end.
