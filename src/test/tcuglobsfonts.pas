{
   Double Commander
   -------------------------------------------------------------------------
   Tier-2 tests: uGlobs font constants for the dcfInput / dcfTabs feature.
}

unit tcUGlobsFonts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

type

  { TTestUGlobsFontConstants }

  TTestUGlobsFontConstants = class(TTestCase)
  published
    // The input field font is picker-constrained to monospace.
    procedure TestInputIsMonospace;
    // The tab font is a free display font, not monospace-constrained.
    procedure TestTabsNotMonospace;
    // Config version was bumped for the two new font nodes.
    procedure TestConfigVersion;
  end;

implementation

uses
  uGlobs;

procedure TTestUGlobsFontConstants.TestInputIsMonospace;
begin
  AssertTrue('dcfInput in DCMonoFonts', dcfInput in DCMonoFonts);
end;

procedure TTestUGlobsFontConstants.TestTabsNotMonospace;
begin
  AssertFalse('dcfTabs in DCMonoFonts', dcfTabs in DCMonoFonts);
end;

procedure TTestUGlobsFontConstants.TestConfigVersion;
begin
  AssertEquals('ConfigVersion', 17, ConfigVersion);
end;

initialization
  RegisterTest(TTestUGlobsFontConstants);

end.
