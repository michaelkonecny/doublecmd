{
   Double Commander
   -------------------------------------------------------------------------
   Fonts options page

   Copyright (C) 2006-2022 Alexander Koblov (alexx2000@mail.ru)

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>.
}

unit fOptionsFonts;

{$mode objfpc}{$H+}

interface

uses
  //Lazarus, Free-Pascal, etc.
  Classes, StdCtrls, Spin, Dialogs,

  //DC
  fOptionsFrame, uGlobs;
type
  { One picker row, one per TDCFont. InheritCheck is nil on category roots. }
  TVisualFontElement = record
    FontEdit: TEdit;
    FontSpinEdit: TSpinEdit;
    FontButton: TButton;
    InheritCheck: TCheckBox;
  end;

  { TSpinEdit }

  TSpinEdit = class(Spin.TSpinEdit)
  public
    function GetLimitedValue(const AValue: Double): Double; override;
  end;

  { TfrmOptionsFonts }
  TfrmOptionsFonts = class(TOptionsEditor)
    dlgFnt: TFontDialog;
    procedure edtFontSizeChange(Sender: TObject);
    procedure btnSelFontClick(Sender: TObject);
    procedure chkInheritChange(Sender: TObject);
  private
    // Reflect a subcategory's inherit state into its row: when inheriting,
    // controls are disabled and show the resolved parent-category values.
    procedure UpdateInheritRow(AFont: TDCFont);
  protected
    procedure Init; override;
    procedure Load; override;
    function Save: TOptionsEditorSaveFlags; override;
  public
    // Indexed by font so tests and handlers can find a row directly.
    VisualFontElements: array[TDCFont] of TVisualFontElement;
    class function GetIconIndex: integer; override;
    class function GetTitle: string; override;
  end;

implementation

{$R *.lfm}

uses
  //Lazarus, Free-Pascal, etc.
  Controls,

  //DC
  uLng;

const
  cSubcategoryIndent = 24; // left indent of subcategory rows under their category

{ TSpinEdit }

function TSpinEdit.GetLimitedValue(const AValue: Double): Double;
begin
  // Zero - default font size
  if (AValue = 0.0) then Exit(0);
  Result:= inherited GetLimitedValue(AValue);
end;

{ TfrmOptionsFonts }

{ TfrmOptionsFonts.GetIconIndex }
class function TfrmOptionsFonts.GetIconIndex: integer;
begin
  Result := 3;
end;

{ TfrmOptionsFonts.GetTitle }
class function TfrmOptionsFonts.GetTitle: string;
begin
  Result := rsOptionsEditorFonts;
end;

{ TfrmOptionsFonts.Init }
// Rows are built from the TDCFont hierarchy rather than designed at conception
// time, so adding a font needs no change here. Category roots get a plain row;
// subcategories are indented and carry an Inherit checkbox.
procedure TfrmOptionsFonts.Init;
var
  ALabelFont: TLabel;
  AEditFont: TEdit;
  APreviousEditFont: TEdit = nil;
  ASpinEditFontSize: TSpinEdit;
  AButtonFont: TButton;
  AInheritCheck: TCheckBox;
  AFont: TDCFont;
  AIndent: Integer;
begin
  for AFont in TDCFont do
  begin
    AInheritCheck := nil;
    if IsCategoryRoot(AFont) then AIndent := 0 else AIndent := cSubcategoryIndent;

    ALabelFont := TLabel.Create(Self);
    ALabelFont.Parent := Self;
    ALabelFont.Caption := gFonts[AFont].Usage;

    AEditFont := TEdit.Create(Self);
    VisualFontElements[AFont].FontEdit := AEditFont;
    AEditFont.Parent := Self;
    AEditFont.Tag := Ord(AFont);
    AEditFont.ReadOnly := True; // the face is chosen through the "..." dialog
    AEditFont.Anchors := [akTop, akLeft, akRight];
    ALabelFont.FocusControl := AEditFont;

    ASpinEditFontSize := TSpinEdit.Create(Self);
    VisualFontElements[AFont].FontSpinEdit := ASpinEditFontSize;
    ASpinEditFontSize.Tag := Ord(AFont);
    ASpinEditFontSize.Parent := Self;
    ASpinEditFontSize.OnChange := @edtFontSizeChange;
    ASpinEditFontSize.MinValue := gFonts[AFont].MinValue;
    ASpinEditFontSize.MaxValue := gFonts[AFont].MaxValue;
    ASpinEditFontSize.Width := 55;
    ASpinEditFontSize.Anchors := [akTop, akRight];

    AButtonFont := TButton.Create(Self);
    VisualFontElements[AFont].FontButton := AButtonFont;
    AButtonFont.Tag := Ord(AFont);
    AButtonFont.Parent := Self;
    AButtonFont.AutoSize := True;
    AButtonFont.Caption := '...';
    AButtonFont.OnClick := @btnSelFontClick;
    AButtonFont.Anchors := [akTop, akRight];

    if not IsCategoryRoot(AFont) then
    begin
      AInheritCheck := TCheckBox.Create(Self);
      VisualFontElements[AFont].InheritCheck := AInheritCheck;
      AInheritCheck.Parent := Self;
      AInheritCheck.Tag := Ord(AFont);
      AInheritCheck.Caption := rsFontInherit;
      AInheritCheck.OnChange := @chkInheritChange;
      AInheritCheck.Anchors := [akTop, akLeft];
    end;

    { Vertical placement: label above its edit row, edit row below the label. }
    ALabelFont.AnchorSideLeft.Control := Self;
    ALabelFont.BorderSpacing.Left := AIndent;
    if APreviousEditFont <> nil then
    begin
      ALabelFont.AnchorSideTop.Control := APreviousEditFont;
      ALabelFont.AnchorSideTop.Side := asrBottom;
      ALabelFont.BorderSpacing.Top := 6;
    end
    else
      ALabelFont.AnchorSideTop.Control := Self;

    AEditFont.AnchorSideTop.Control := ALabelFont;
    AEditFont.AnchorSideTop.Side := asrBottom;
    AEditFont.AnchorSideRight.Control := ASpinEditFontSize;

    if Assigned(AInheritCheck) then
    begin
      // Inherit checkbox sits at the indent; the preview edit follows it.
      AInheritCheck.AnchorSideLeft.Control := Self;
      AInheritCheck.BorderSpacing.Left := AIndent;
      AInheritCheck.AnchorSideTop.Control := AEditFont;
      AInheritCheck.AnchorSideTop.Side := asrCenter;
      AEditFont.AnchorSideLeft.Control := AInheritCheck;
      AEditFont.AnchorSideLeft.Side := asrBottom;
    end
    else
      AEditFont.AnchorSideLeft.Control := ALabelFont;

    ASpinEditFontSize.AnchorSideTop.Control := AEditFont;
    ASpinEditFontSize.AnchorSideTop.Side := asrCenter;
    ASpinEditFontSize.AnchorSideRight.Control := AButtonFont;

    AButtonFont.AnchorSideTop.Control := AEditFont;
    AButtonFont.AnchorSideTop.Side := asrCenter;
    AButtonFont.AnchorSideRight.Control := Self;
    AButtonFont.AnchorSideRight.Side := asrBottom;
    AButtonFont.AnchorSideBottom.Side := asrBottom;

    APreviousEditFont := AEditFont;
  end;
end;

{ TfrmOptionsFonts.Load }
procedure TfrmOptionsFonts.Load;
var
  AFont: TDCFont;
begin
  for AFont in TDCFont do
    with VisualFontElements[AFont] do
    begin
      FontEdit.Text := gFonts[AFont].Name;
      FontOptionsToFont(gFonts[AFont], FontEdit.Font);
      FontSpinEdit.HandleNeeded;
      FontSpinEdit.Value := gFonts[AFont].Size;
      if Assigned(InheritCheck) then
        InheritCheck.Checked := gFonts[AFont].Inherit;
      UpdateInheritRow(AFont);
    end;
end;

{ TfrmOptionsFonts.Save }
function TfrmOptionsFonts.Save: TOptionsEditorSaveFlags;
var
  AFont: TDCFont;
begin
  Result := [];
  for AFont in TDCFont do
    with VisualFontElements[AFont] do
    begin
      // When inheriting, the (disabled) controls already show the parent's
      // font, so this stores the resolved parent values + the inherit flag,
      // discarding any earlier explicit override.
      FontToFontOptions(FontEdit.Font, gFonts[AFont]);
      gFonts[AFont].Size := FontSpinEdit.Value;
      if Assigned(InheritCheck) then
        gFonts[AFont].Inherit := InheritCheck.Checked
      else
        gFonts[AFont].Inherit := False;
    end;
end;

{ TfrmOptionsFonts.UpdateInheritRow }
procedure TfrmOptionsFonts.UpdateInheritRow(AFont: TDCFont);
var
  Inheriting: Boolean;
  CategoryFont: TDCFontOptions;
begin
  with VisualFontElements[AFont] do
  begin
    Inheriting := Assigned(InheritCheck) and InheritCheck.Checked;
    FontEdit.Enabled := not Inheriting;
    FontSpinEdit.Enabled := not Inheriting;
    FontButton.Enabled := not Inheriting;
    if Inheriting then
    begin
      // Show the resolved parent-category values; on a later uncheck these
      // stay as the starting point for an explicit override.
      CategoryFont := gFonts[ParentCategory(AFont)];
      FontEdit.Text := CategoryFont.Name;
      FontOptionsToFont(CategoryFont, FontEdit.Font);
      FontSpinEdit.Value := CategoryFont.Size;
    end;
  end;
end;

{ TfrmOptionsFonts.edtFontSizeChange }
procedure TfrmOptionsFonts.edtFontSizeChange(Sender: TObject);
begin
  with VisualFontElements[TDCFont(TSpinEdit(Sender).Tag)] do
    if FontEdit.Font.Size <> TSpinEdit(Sender).Value then
      FontEdit.Font.Size := TSpinEdit(Sender).Value;
end;

{ TfrmOptionsFonts.chkInheritChange }
procedure TfrmOptionsFonts.chkInheritChange(Sender: TObject);
begin
  UpdateInheritRow(TDCFont(TCheckBox(Sender).Tag));
end;

{ TfrmOptionsFonts.btnSelFontClick }
procedure TfrmOptionsFonts.btnSelFontClick(Sender: TObject);
var
  AFont: TDCFont;
begin
  AFont := TDCFont(TButton(Sender).Tag);
  with VisualFontElements[AFont] do
  begin
    dlgFnt.Font := FontEdit.Font;
    if (AFont in DCMonoFonts) then
      dlgFnt.Options := dlgFnt.Options + [fdFixedPitchOnly, fdNoStyleSel]
    else
      dlgFnt.Options := dlgFnt.Options - [fdFixedPitchOnly, fdNoStyleSel];
    if dlgFnt.Execute then
    begin
      FontEdit.Font := dlgFnt.Font;
      FontEdit.Text := dlgFnt.Font.Name;
      FontSpinEdit.Value := dlgFnt.Font.Size;
    end;
  end;
end;

end.
