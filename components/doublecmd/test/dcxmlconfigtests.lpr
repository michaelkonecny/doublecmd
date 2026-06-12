program dcxmlconfigtests;

{$mode objfpc}{$H+}

uses
  consoletestrunner, tcXmlConfigFont;

var
  App: TTestRunner;

begin
  App := TTestRunner.Create(nil);
  App.Initialize;
  App.Title := 'DC XmlConfig font tests';
  App.Run;
  App.Free;
end.
