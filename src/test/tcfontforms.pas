{
   Double Commander
   -------------------------------------------------------------------------
   Tier-3 tests: the dcfInput / dcfTabs fonts reach the isolatable forms.
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
    // Options page surfaces both new rows (label + preview edit) from enum iteration.
    procedure TestOptionsFontsPage;
    // MkDir combo uses the input font.
    procedure TestMkDir;
    // Multi-rename edits and preview grid use the input font.
    procedure TestMultiRename;
    // Quick search edit uses the input font.
    procedure TestQuickSearch;
  end;

implementation

uses
  Controls, Forms, StdCtrls, Grids,
  uGlobs, uLng, fOptionsFrame, fOptionsFonts, fMkDir, fMultiRename, fQuickSearch,
  tcFontSetup;

procedure TTestFontForms.SetUp;
begin
  EnsureTestGlobals;
end;

procedure TTestFontForms.TestOptionsFontsPage;
var
  ParentForm: TForm;
  Frame: TfrmOptionsFonts;
  i: Integer;
  c: TComponent;
  HasInputLabel, HasTabsLabel, HasInputPreview: Boolean;
begin
  ParentForm := TForm.CreateNew(nil);
  try
    Frame := TfrmOptionsFonts.Create(ParentForm);
    Frame.Init(ParentForm, nil, [oeifLoad]);

    HasInputLabel := False; HasTabsLabel := False; HasInputPreview := False;
    for i := 0 to Frame.ComponentCount - 1 do
    begin
      c := Frame.Components[i];
      if (c is TLabel) and (TLabel(c).Caption = rsFontUsageInput) then
        HasInputLabel := True;
      if (c is TLabel) and (TLabel(c).Caption = rsFontUsageTabs) then
        HasTabsLabel := True;
      if (c is TEdit) and (TEdit(c).Text = cInputFontName) then
        HasInputPreview := True;
    end;

    AssertTrue('Input usage label present', HasInputLabel);
    AssertTrue('Tabs usage label present', HasTabsLabel);
    AssertTrue('Preview edit shows configured input font name', HasInputPreview);
  finally
    ParentForm.Free;
  end;
end;

procedure TTestFontForms.TestMkDir;
var
  Form: TfrmMkDir;
begin
  Form := TfrmMkDir.Create(nil);
  try
    AssertEquals('cbMkDir font', cInputFontName, Form.cbMkDir.Font.Name);
  finally
    Form.Free;
  end;
end;

procedure TTestFontForms.TestMultiRename;
var
  Form: TfrmMultiRename;
begin
  Form := TfrmMultiRename.Create(nil);
  try
    AssertEquals('edFind font', cInputFontName, Form.edFind.Font.Name);
    AssertEquals('edReplace font', cInputFontName, Form.edReplace.Font.Name);
    AssertEquals('edPoc font', cInputFontName, Form.edPoc.Font.Name);
    AssertEquals('edInterval font', cInputFontName, Form.edInterval.Font.Name);
    AssertEquals('StringGrid font', cInputFontName, Form.StringGrid.Font.Name);
  finally
    Form.Free;
  end;
end;

procedure TTestFontForms.TestQuickSearch;
var
  ParentForm: TForm;
  Frame: TfrmQuickSearch;
begin
  ParentForm := TForm.CreateNew(nil);
  try
    Frame := TfrmQuickSearch.Create(ParentForm);
    AssertEquals('edtSearch font', cInputFontName, Frame.edtSearch.Font.Name);
  finally
    ParentForm.Free;
  end;
end;

initialization
  RegisterTest(TTestFontForms);

end.
