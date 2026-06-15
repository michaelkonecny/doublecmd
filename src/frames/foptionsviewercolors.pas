{
   Double Commander
   -------------------------------------------------------------------------
   Viewer colors options page

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

unit fOptionsViewerColors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls, DividerBevel, KASComboBox, fOptionsFrame;

type

  { TfrmOptionsViewerColors }

  TfrmOptionsViewerColors = class(TOptionsEditor)
    cbBookBackground: TKASColorBoxButton;
    cbBookText: TKASColorBoxButton;
    cbImageBackground1: TKASColorBoxButton;
    cbImageBackground2: TKASColorBoxButton;
    dbBookMode: TDividerBevel;
    dbImageMode: TDividerBevel;
    DividerBevel9: TDividerBevel;
    DividerBevel11: TDividerBevel;
    lblBookBackground: TLabel;
    lblBookText: TLabel;
    lblImageBackground1: TLabel;
    lblImageBackground2: TLabel;
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

{ TfrmOptionsViewerColors }

procedure TfrmOptionsViewerColors.Load;
begin
  with gColors.Viewer^ do
  begin
    cbBookText.Selected:= BookFontColor;
    cbBookBackground.Selected:= BookBackgroundColor;
    cbImageBackground1.Selected:= ImageBackColor1;
    cbImageBackground2.Selected:= ImageBackColor2;
  end;
end;

function TfrmOptionsViewerColors.Save: TOptionsEditorSaveFlags;
begin
  Result:= [];
  with gColors.Viewer^ do
  begin
    BookFontColor:= cbBookText.Selected;
    BookBackgroundColor:= cbBookBackground.Selected;
    ImageBackColor1:= cbImageBackground1.Selected;
    ImageBackColor2:= cbImageBackground2.Selected;
  end;
end;

class function TfrmOptionsViewerColors.GetIconIndex: Integer;
begin
  Result:= 4;
end;

class function TfrmOptionsViewerColors.GetTitle: String;
begin
  Result:= rsToolViewer;
end;

end.
