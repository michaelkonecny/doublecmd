{
   Double Commander
   -------------------------------------------------------------------------
   Tier-2 tests: the font category/subcategory hierarchy — resolver, parent
   map, monospace-constraint membership, config version.
}

unit tcUGlobsFonts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

type

  { TTestFontHierarchy }

  TTestFontHierarchy = class(TTestCase)
  published
    // An inheriting subcategory resolves to its category root's whole font.
    procedure TestInheritResolvesToParent;
    // An overriding subcategory keeps its own values, ignoring the parent.
    procedure TestOverrideWins;
    // Every subcategory maps to its category root; roots are roots.
    procedure TestParentMap;
    // Monospace constraint covers Document/Console/Input; not UI/Filesystem.
    procedure TestMonoConstraintMembership;
    // Config version was bumped for the hierarchy migration.
    procedure TestConfigVersion;
  end;

implementation

uses
  Graphics, uGlobs;

procedure TTestFontHierarchy.TestInheritResolvesToParent;
var
  Resolved: TDCFontOptions;
begin
  gFonts[dcfFilesystem].Name := 'ParentFace';
  gFonts[dcfFilesystem].Size := 17;
  gFonts[dcfFilesystem].Style := [fsBold];
  gFonts[dcfFilesystem].Quality := fqNonAntialiased;

  // Own values deliberately differ from the parent.
  gFonts[dcfInlineRename].Name := 'OwnFace';
  gFonts[dcfInlineRename].Size := 8;
  gFonts[dcfInlineRename].Style := [];
  gFonts[dcfInlineRename].Quality := fqDefault;
  gFonts[dcfInlineRename].Inherit := True;

  Resolved := ResolveFont(dcfInlineRename);
  AssertEquals('inherited name', 'ParentFace', Resolved.Name);
  AssertEquals('inherited size', 17, Resolved.Size);
  AssertTrue('inherited style', Resolved.Style = [fsBold]);
  AssertTrue('inherited quality', Resolved.Quality = fqNonAntialiased);
end;

procedure TTestFontHierarchy.TestOverrideWins;
var
  Resolved: TDCFontOptions;
begin
  gFonts[dcfFilesystem].Name := 'ParentFace';
  gFonts[dcfFilesystem].Size := 17;

  gFonts[dcfPathEdit].Name := 'OverrideFace';
  gFonts[dcfPathEdit].Size := 9;
  gFonts[dcfPathEdit].Inherit := False;

  Resolved := ResolveFont(dcfPathEdit);
  AssertEquals('override name', 'OverrideFace', Resolved.Name);
  AssertEquals('override size', 9, Resolved.Size);
end;

procedure TTestFontHierarchy.TestParentMap;
begin
  // Category roots.
  AssertTrue('UI is root', IsCategoryRoot(dcfUIRoot));
  AssertTrue('Filesystem is root', IsCategoryRoot(dcfFilesystem));
  AssertTrue('Input is root', IsCategoryRoot(dcfInput));
  AssertTrue('Document is root', IsCategoryRoot(dcfDocumentRoot));
  AssertTrue('Console is root', IsCategoryRoot(dcfConsoleRoot));

  // Subcategories are not roots and map to their category.
  AssertFalse('StatusBar not root', IsCategoryRoot(dcfStatusBar));
  AssertTrue('StatusBar->UI', ParentCategory(dcfStatusBar) = dcfUIRoot);
  AssertTrue('FunctionButtons->UI', ParentCategory(dcfFunctionButtons) = dcfUIRoot);
  AssertTrue('Tabs->UI', ParentCategory(dcfTabs) = dcfUIRoot);
  AssertTrue('TreeViewMenu->UI', ParentCategory(dcfTreeViewMenu) = dcfUIRoot);
  AssertTrue('PathEdit->Filesystem', ParentCategory(dcfPathEdit) = dcfFilesystem);
  AssertTrue('InlineRename->Filesystem', ParentCategory(dcfInlineRename) = dcfFilesystem);
  AssertTrue('SearchResults->Filesystem', ParentCategory(dcfSearchResults) = dcfFilesystem);
  AssertTrue('Editor->Document', ParentCategory(dcfEditor) = dcfDocumentRoot);
  AssertTrue('Viewer->Document', ParentCategory(dcfViewer) = dcfDocumentRoot);
  AssertTrue('ViewerBook->Document', ParentCategory(dcfViewerBook) = dcfDocumentRoot);
  AssertTrue('Log->Console', ParentCategory(dcfLog) = dcfConsoleRoot);
end;

procedure TTestFontHierarchy.TestMonoConstraintMembership;
begin
  // Document (+subs), Console (+Log), User input.
  AssertTrue('Document mono', dcfDocumentRoot in DCMonoFonts);
  AssertTrue('Editor mono', dcfEditor in DCMonoFonts);
  AssertTrue('Viewer mono', dcfViewer in DCMonoFonts);
  AssertTrue('ViewerBook mono', dcfViewerBook in DCMonoFonts);
  AssertTrue('Console mono', dcfConsoleRoot in DCMonoFonts);
  AssertTrue('Log mono', dcfLog in DCMonoFonts);
  AssertTrue('Input mono', dcfInput in DCMonoFonts);

  // UI and Filesystem (+their subs) are free.
  AssertFalse('UI not mono', dcfUIRoot in DCMonoFonts);
  AssertFalse('StatusBar not mono', dcfStatusBar in DCMonoFonts);
  AssertFalse('FunctionButtons not mono', dcfFunctionButtons in DCMonoFonts);
  AssertFalse('Tabs not mono', dcfTabs in DCMonoFonts);
  AssertFalse('TreeViewMenu not mono', dcfTreeViewMenu in DCMonoFonts);
  AssertFalse('Filesystem not mono', dcfFilesystem in DCMonoFonts);
  AssertFalse('PathEdit not mono', dcfPathEdit in DCMonoFonts);
  AssertFalse('InlineRename not mono', dcfInlineRename in DCMonoFonts);
  AssertFalse('SearchResults not mono', dcfSearchResults in DCMonoFonts);
end;

procedure TTestFontHierarchy.TestConfigVersion;
begin
  AssertEquals('ConfigVersion', 18, ConfigVersion);
end;

initialization
  RegisterTest(TTestFontHierarchy);

end.
