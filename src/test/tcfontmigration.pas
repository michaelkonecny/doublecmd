{
   Double Commander
   -------------------------------------------------------------------------
   Tier-2 tests: font config migration (v17 flat nodes -> v18 hierarchy) and
   the nested save/load round-trip.
}

unit tcFontMigration;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

type

  { TTestFontMigration }

  TTestFontMigration = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    // Each legacy slot migrates to its hierarchy position as an explicit font.
    procedure TestLegacySlotsMigrateExplicit;
    // New-only slots keep their defaults (inline rename inherits; roots set).
    procedure TestNewOnlySlotsSeed;
    // Save then load the nested tree preserves fonts and Inherit flags.
    procedure TestNestedRoundTrip;
    // A v17 config missing some font nodes loads; those slots fall back.
    procedure TestMissingNodeFallback;
    // After migrate+save the config is v18 with the flat nodes gone, and a
    // second load reads the nested tree without re-seeding.
    procedure TestMigrateThenReloadStable;
    // The carried-over quirk: a SearchResults font from a pre-v11 config is
    // ignored (kept default); from v11+ it migrates.
    procedure TestSearchResultsVersionGuard;
  end;

implementation

uses
  Graphics, DCXmlConfig, uGlobs, uOSUtils, tcFontSetup;

procedure TTestFontMigration.SetUp;
begin
  EnsureTestGlobals;
end;

// Start from a clean in-memory config plus default fonts.
procedure ResetConfig;
begin
  gConfig.Clear;
  SetDefaultConfigGlobs;
end;

procedure WriteLegacyFont(const APath, AName: String; ASize: Integer);
begin
  gConfig.SetFont(gConfig.FindNode(gConfig.RootNode, APath, True), '',
                  AName, ASize, 0, Integer(fqDefault));
end;

procedure TTestFontMigration.TestLegacySlotsMigrateExplicit;
begin
  ResetConfig;
  gConfig.SetAttr(gConfig.RootNode, 'ConfigVersion', 17);
  WriteLegacyFont('Fonts/Main', 'LegacyMain', 13);
  WriteLegacyFont('Fonts/Editor', 'LegacyEditor', 15);
  WriteLegacyFont('Fonts/Console', 'LegacyConsole', 12);
  WriteLegacyFont('Fonts/PathEdit', 'LegacyPath', 11);
  WriteLegacyFont('Fonts/Tabs', 'LegacyTabs', 10);

  LoadXmlConfig;

  AssertEquals('Filesystem name', 'LegacyMain', gFonts[dcfFilesystem].Name);
  AssertEquals('Filesystem size', 13, gFonts[dcfFilesystem].Size);
  AssertFalse('Filesystem explicit', gFonts[dcfFilesystem].Inherit);

  AssertEquals('Editor migrated', 'LegacyEditor', gFonts[dcfEditor].Name);
  AssertEquals('Console root migrated', 'LegacyConsole', gFonts[dcfConsoleRoot].Name);
  AssertEquals('PathEdit migrated', 'LegacyPath', gFonts[dcfPathEdit].Name);
  AssertFalse('PathEdit explicit', gFonts[dcfPathEdit].Inherit);
  AssertEquals('Tabs migrated', 'LegacyTabs', gFonts[dcfTabs].Name);
end;

procedure TTestFontMigration.TestNewOnlySlotsSeed;
begin
  ResetConfig;
  gConfig.SetAttr(gConfig.RootNode, 'ConfigVersion', 17);
  WriteLegacyFont('Fonts/Main', 'LegacyMain', 13);

  LoadXmlConfig;

  // Inline rename has no legacy node -> stays inheriting.
  AssertTrue('InlineRename inherits', gFonts[dcfInlineRename].Inherit);
  // UI root defaults to the system font (size 0 sentinel).
  AssertEquals('UI root name', 'default', gFonts[dcfUIRoot].Name);
  AssertEquals('UI root size', 0, gFonts[dcfUIRoot].Size);
  // Document root defaults to monospace.
  AssertEquals('Document root name', MonoSpaceFont, gFonts[dcfDocumentRoot].Name);
end;

procedure TTestFontMigration.TestNestedRoundTrip;
begin
  ResetConfig;

  gFonts[dcfPathEdit].Name := 'RoundPath';
  gFonts[dcfPathEdit].Size := 11;
  gFonts[dcfPathEdit].Inherit := False;

  gFonts[dcfInlineRename].Inherit := True;

  gFonts[dcfEditor].Name := 'RoundEditor';
  gFonts[dcfEditor].Size := 16;
  gFonts[dcfEditor].Inherit := False;

  SaveXmlConfig;

  // Scramble in-memory state, then reload from the saved (v18) tree.
  gFonts[dcfPathEdit].Name := 'XXX';
  gFonts[dcfPathEdit].Size := 99;
  gFonts[dcfInlineRename].Inherit := False;
  gFonts[dcfEditor].Name := 'YYY';

  LoadXmlConfig;

  AssertEquals('PathEdit name preserved', 'RoundPath', gFonts[dcfPathEdit].Name);
  AssertEquals('PathEdit size preserved', 11, gFonts[dcfPathEdit].Size);
  AssertFalse('PathEdit still explicit', gFonts[dcfPathEdit].Inherit);
  AssertTrue('InlineRename still inherits', gFonts[dcfInlineRename].Inherit);
  AssertEquals('Editor name preserved', 'RoundEditor', gFonts[dcfEditor].Name);
  AssertEquals('Editor size preserved', 16, gFonts[dcfEditor].Size);
end;

procedure TTestFontMigration.TestMissingNodeFallback;
begin
  ResetConfig;
  gConfig.SetAttr(gConfig.RootNode, 'ConfigVersion', 17);
  // Only the main font is present; every other legacy node is absent.
  WriteLegacyFont('Fonts/Main', 'OnlyMain', 11);

  LoadXmlConfig; // must not raise

  AssertEquals('Filesystem from node', 'OnlyMain', gFonts[dcfFilesystem].Name);
  // A category with no legacy node falls back to its default (mono editor).
  AssertEquals('Editor default', MonoSpaceFont, gFonts[dcfEditor].Name);
  // A subcategory with no legacy node falls back to inherit.
  AssertTrue('InlineRename inherits', gFonts[dcfInlineRename].Inherit);
end;

procedure TTestFontMigration.TestMigrateThenReloadStable;
begin
  ResetConfig;
  gConfig.SetAttr(gConfig.RootNode, 'ConfigVersion', 17);
  WriteLegacyFont('Fonts/Main', 'MigMain', 13);
  WriteLegacyFont('Fonts/Editor', 'MigEditor', 15);

  LoadXmlConfig;  // migrate into memory
  SaveXmlConfig;  // persist nested tree, stamp v18, drop flat nodes

  AssertEquals('stamped v18', 18, gConfig.GetAttr(gConfig.RootNode, 'ConfigVersion', 0));
  AssertTrue('flat Fonts/Main removed',
             gConfig.FindNode(gConfig.RootNode, 'Fonts/Main') = nil);

  // Scramble, then reload: must read the nested tree, not re-seed defaults.
  gFonts[dcfFilesystem].Name := 'scrambled';
  gFonts[dcfEditor].Name := 'scrambled';
  LoadXmlConfig;

  AssertEquals('Filesystem stable', 'MigMain', gFonts[dcfFilesystem].Name);
  AssertEquals('Editor stable', 'MigEditor', gFonts[dcfEditor].Name);
end;

procedure TTestFontMigration.TestSearchResultsVersionGuard;
begin
  // Pre-v11: the stored SearchResults font is ignored, default kept.
  ResetConfig;
  gConfig.SetAttr(gConfig.RootNode, 'ConfigVersion', 10);
  WriteLegacyFont('Fonts/Main', 'M', 10);
  WriteLegacyFont('Fonts/SearchResults', 'OldSearch', 20);
  LoadXmlConfig;
  AssertTrue('pre-v11 SearchResults ignored', gFonts[dcfSearchResults].Name <> 'OldSearch');

  // v11+: the stored SearchResults font migrates.
  ResetConfig;
  gConfig.SetAttr(gConfig.RootNode, 'ConfigVersion', 11);
  WriteLegacyFont('Fonts/Main', 'M', 10);
  WriteLegacyFont('Fonts/SearchResults', 'NewSearch', 20);
  LoadXmlConfig;
  AssertEquals('v11+ SearchResults migrates', 'NewSearch', gFonts[dcfSearchResults].Name);
end;

initialization
  RegisterTest(TTestFontMigration);

end.
