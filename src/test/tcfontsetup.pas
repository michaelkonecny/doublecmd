{
   Double Commander
   -------------------------------------------------------------------------
   Shared setup for the GUI font tests: minimal global state plus recognisable
   test fonts for dcfInput / dcfTabs.
}

unit tcFontSetup;

{$mode objfpc}{$H+}

interface

const
  cInputFontName = 'Test Input Mono';
  cInputFontSize = 13;
  cTabsFontName  = 'Test Tabs Display';
  cTabsFontSize  = 11;

// Idempotent: create the globals the forms touch and stamp the test fonts.
procedure EnsureTestGlobals;

implementation

uses
  SysUtils, Graphics, DCXmlConfig,
  uGlobs, uGlobsPaths, uLng, uHotkeyManager, uSpecialDir;

procedure EnsureTestGlobals;
begin
  if gpCfgDir = '' then
  begin
    gpCfgDir := IncludeTrailingPathDelimiter(GetTempDir) + 'dc-fonttests' + PathDelim;
    ForceDirectories(gpCfgDir);
  end;
  if not Assigned(HotMan) then
    HotMan := THotKeyManager.Create;
  if not Assigned(gConfig) then
    gConfig := TXmlConfig.Create(gpCfgDir + 'doublecmd.xml');
  if not Assigned(gSpecialDirList) then
    gSpecialDirList := TSpecialDirList.Create;
  // Allocate the global lists that SetDefaultConfigGlobs / LoadXmlConfig touch.
  if not Assigned(gExts) then
    CreateGlobs;

  gFonts[dcfInput].Name := cInputFontName;
  gFonts[dcfInput].Size := cInputFontSize;
  gFonts[dcfInput].Style := [];
  gFonts[dcfInput].Quality := fqDefault;
  gFonts[dcfInput].MinValue := 6;
  gFonts[dcfInput].MaxValue := 200;
  gFonts[dcfInput].Usage := rsFontUsageInput;

  gFonts[dcfTabs].Name := cTabsFontName;
  gFonts[dcfTabs].Size := cTabsFontSize;
  gFonts[dcfTabs].Style := [];
  gFonts[dcfTabs].Quality := fqDefault;
  gFonts[dcfTabs].MinValue := 6;
  gFonts[dcfTabs].MaxValue := 200;
  gFonts[dcfTabs].Usage := rsFontUsageTabs;
end;

end.
