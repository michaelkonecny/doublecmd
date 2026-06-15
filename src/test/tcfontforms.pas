{
   Double Commander
   -------------------------------------------------------------------------
   Tier-3 tests: the Options > Fonts picker rows and the User-input slot
   reaching the isolatable forms.
}

unit tcFontForms;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

type

  { TTestFontForms }

  TTestFontForms = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    // One row per font: category rows have no Inherit checkbox, subcategory
    // rows do.
    procedure TestIndentedRows;
    // An inheriting subcategory's controls are disabled and show the resolved
    // parent values; unchecking Inherit re-enables them.
    procedure TestInheritDisablesControls;
    // Re-checking Inherit on an explicit subcategory discards the override on
    // save; the stored font re-derives from the parent category.
    procedure TestReInheritDiscardsOverride;
    // MkDir / MultiRename / QuickSearch are driven by the User-input slot;
    // numeric counters keep the default font.
    procedure TestUserInputWidgets;
  end;

implementation

uses
  Controls, Forms, StdCtrls, Graphics,
  uGlobs, fOptionsFrame, fOptionsFonts, fMkDir, fMultiRename, fQuickSearch,
  tcFontSetup;

procedure TTestFontForms.SetUp;
begin
  EnsureTestGlobals;
end;

function MakeFontsFrame(AParent: TForm): TfrmOptionsFonts;
begin
  Result := TfrmOptionsFonts.Create(AParent);
  Result.Init(AParent, nil, [oeifLoad]);
end;

procedure TTestFontForms.TestIndentedRows;
var
  ParentForm: TForm;
  Frame: TfrmOptionsFonts;
  AFont: TDCFont;
begin
  ParentForm := TForm.CreateNew(nil);
  try
    Frame := MakeFontsFrame(ParentForm);
    for AFont in TDCFont do
      if IsCategoryRoot(AFont) then
        AssertTrue('category ' + gFonts[AFont].Usage + ' has no Inherit checkbox',
                   Frame.VisualFontElements[AFont].InheritCheck = nil)
      else
        AssertTrue('subcategory ' + gFonts[AFont].Usage + ' has an Inherit checkbox',
                   Assigned(Frame.VisualFontElements[AFont].InheritCheck));
  finally
    ParentForm.Free;
  end;
end;

procedure TTestFontForms.TestInheritDisablesControls;
var
  ParentForm: TForm;
  Frame: TfrmOptionsFonts;
begin
  // Parent category carries a recognisable font; the subcategory inherits.
  gFonts[dcfFilesystem].Name := 'InheritParentFace';
  gFonts[dcfFilesystem].Size := 21;
  gFonts[dcfInlineRename].Name := 'ChildOwnFace';
  gFonts[dcfInlineRename].Size := 8;
  gFonts[dcfInlineRename].Inherit := True;

  ParentForm := TForm.CreateNew(nil);
  try
    Frame := MakeFontsFrame(ParentForm);
    with Frame.VisualFontElements[dcfInlineRename] do
    begin
      AssertTrue('Inherit checked', InheritCheck.Checked);
      AssertFalse('size disabled when inheriting', FontSpinEdit.Enabled);
      AssertFalse('preview disabled when inheriting', FontEdit.Enabled);
      AssertEquals('preview shows parent face', 'InheritParentFace', FontEdit.Text);
      AssertEquals('size shows parent size', 21, FontSpinEdit.Value);

      // Unchecking enables the controls again.
      InheritCheck.Checked := False;
      AssertTrue('size enabled after uncheck', FontSpinEdit.Enabled);
      AssertTrue('preview enabled after uncheck', FontEdit.Enabled);
    end;
  finally
    ParentForm.Free;
  end;
end;

procedure TTestFontForms.TestReInheritDiscardsOverride;
var
  ParentForm: TForm;
  Frame: TfrmOptionsFonts;
begin
  gFonts[dcfFilesystem].Name := 'ParentFaceX';
  gFonts[dcfFilesystem].Size := 19;
  gFonts[dcfFilesystem].Style := [];
  gFonts[dcfFilesystem].Quality := fqDefault;
  gFonts[dcfFilesystem].Inherit := False;

  // Start as an explicit override that differs from the parent.
  gFonts[dcfInlineRename].Name := 'ChildOverride';
  gFonts[dcfInlineRename].Size := 7;
  gFonts[dcfInlineRename].Inherit := False;

  ParentForm := TForm.CreateNew(nil);
  try
    Frame := MakeFontsFrame(ParentForm);
    // User re-checks Inherit, then saves.
    Frame.VisualFontElements[dcfInlineRename].InheritCheck.Checked := True;
    Frame.SaveSettings;

    AssertTrue('saved as inheriting', gFonts[dcfInlineRename].Inherit);
    AssertEquals('override discarded -> parent name', 'ParentFaceX', gFonts[dcfInlineRename].Name);
    AssertEquals('override discarded -> parent size', 19, gFonts[dcfInlineRename].Size);
    AssertEquals('resolves to parent', 'ParentFaceX', ResolveFont(dcfInlineRename).Name);
  finally
    ParentForm.Free;
  end;
end;

procedure TTestFontForms.TestUserInputWidgets;
var
  MkDir: TfrmMkDir;
  MultiRename: TfrmMultiRename;
  ParentForm: TForm;
  QuickSearch: TfrmQuickSearch;
begin
  MkDir := TfrmMkDir.Create(nil);
  try
    AssertEquals('cbMkDir font', cInputFontName, MkDir.cbMkDir.Font.Name);
  finally
    MkDir.Free;
  end;

  MultiRename := TfrmMultiRename.Create(nil);
  try
    AssertEquals('cbName font', cInputFontName, MultiRename.cbName.Font.Name);
    AssertEquals('cbExt font', cInputFontName, MultiRename.cbExt.Font.Name);
    AssertEquals('edFind font', cInputFontName, MultiRename.edFind.Font.Name);
    AssertEquals('edReplace font', cInputFontName, MultiRename.edReplace.Font.Name);
    AssertEquals('log path font', cInputFontName, MultiRename.fneRenameLogFileFilename.Font.Name);
    AssertEquals('StringGrid font', cInputFontName, MultiRename.StringGrid.Font.Name);
    AssertTrue('edPoc keeps default font', MultiRename.edPoc.Font.Name <> cInputFontName);
    AssertTrue('edInterval keeps default font', MultiRename.edInterval.Font.Name <> cInputFontName);
  finally
    MultiRename.Free;
  end;

  ParentForm := TForm.CreateNew(nil);
  try
    QuickSearch := TfrmQuickSearch.Create(ParentForm);
    AssertEquals('edtSearch font', cInputFontName, QuickSearch.edtSearch.Font.Name);
  finally
    ParentForm.Free;
  end;
end;

initialization
  RegisterTest(TTestFontForms);

end.
