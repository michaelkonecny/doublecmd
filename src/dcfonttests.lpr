program dcfonttests;

{$mode objfpc}{$H+}

uses
  Interfaces, // LCL widgetset (needed to create controls headless)
  Forms,
  consoletestrunner,
  tcUGlobsFonts,
  tcFontSetup,
  tcFontForms;

var
  App: TTestRunner;

begin
  Application.Initialize;
  // Let exceptions propagate to fpcunit instead of popping modal dialogs.
  Application.Flags := Application.Flags + [AppNoExceptionMessages];
  App := TTestRunner.Create(nil);
  App.Initialize;
  App.Title := 'DC font GUI tests';
  App.Run;
  App.Free;
end.
