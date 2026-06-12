{
   Double Commander
   -------------------------------------------------------------------------
   Tier-1 tests: TXmlConfig font primitive (SetFont / GetFont).

   These back the dcfInput / dcfTabs font feature, but exercise only the
   underlying config primitive, so they need no LCL widgetset.
}

unit tcXmlConfigFont;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, DCXmlConfig;

type

  { TTestXmlConfigFont }

  TTestXmlConfigFont = class(TTestCase)
  private
    FConfig: TXmlConfig;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // SetFont then GetFont on the same node returns identical name/size/style/quality.
    procedure TestRoundTrip;
    // GetFont on a node without font values returns the supplied defaults unchanged.
    procedure TestDefaultFallback;
    // A combined style bitmask (bold+italic) round-trips intact.
    procedure TestStyleBitmask;
    // Values survive a write-to-stream / read-from-stream cycle.
    procedure TestSerializationRoundTrip;
  end;

implementation

const
  // fsBold = bit 0, fsItalic = bit 1; the primitive treats Style as an Integer.
  StyleBoldItalic = 3;

procedure TTestXmlConfigFont.SetUp;
begin
  FConfig := TXmlConfig.Create;
end;

procedure TTestXmlConfigFont.TearDown;
begin
  FreeAndNil(FConfig);
end;

procedure TTestXmlConfigFont.TestRoundTrip;
var
  Node: TXmlNode;
  Name: String;
  Size, Style, Quality: Integer;
begin
  Node := FConfig.FindNode(FConfig.RootNode, 'Fonts/Test', True);
  FConfig.SetFont(Node, '', 'JetBrains Mono', 14, 1, 2);

  // Seed with values that must be overwritten by the stored ones.
  Name := ''; Size := 0; Style := 0; Quality := 0;
  FConfig.GetFont(Node, '', Name, Size, Style, Quality, 'default', 10, 0, 0);

  AssertEquals('Name', 'JetBrains Mono', Name);
  AssertEquals('Size', 14, Size);
  AssertEquals('Style', 1, Style);
  AssertEquals('Quality', 2, Quality);
end;

procedure TTestXmlConfigFont.TestDefaultFallback;
var
  Node: TXmlNode;
  Name: String;
  Size, Style, Quality: Integer;
begin
  // Empty node: no font values stored, so defaults must come back unchanged.
  Node := FConfig.FindNode(FConfig.RootNode, 'Fonts/Missing', True);

  Name := 'should be overwritten'; Size := -1; Style := -1; Quality := -1;
  FConfig.GetFont(Node, '', Name, Size, Style, Quality, 'MonoSpace', 12, 0, 1);

  AssertEquals('Name', 'MonoSpace', Name);
  AssertEquals('Size', 12, Size);
  AssertEquals('Style', 0, Style);
  AssertEquals('Quality', 1, Quality);
end;

procedure TTestXmlConfigFont.TestStyleBitmask;
var
  Node: TXmlNode;
  Name: String;
  Size, Style, Quality: Integer;
begin
  Node := FConfig.FindNode(FConfig.RootNode, 'Fonts/Styled', True);
  FConfig.SetFont(Node, '', 'Test', 10, StyleBoldItalic, 0);

  Style := 0;
  FConfig.GetFont(Node, '', Name, Size, Style, Quality, '', 0, 0, 0);

  AssertEquals('Combined bold+italic bitmask', StyleBoldItalic, Style);
end;

procedure TTestXmlConfigFont.TestSerializationRoundTrip;
var
  Node: TXmlNode;
  Stream: TMemoryStream;
  Reloaded: TXmlConfig;
  Name: String;
  Size, Style, Quality: Integer;
begin
  Node := FConfig.FindNode(FConfig.RootNode, 'Fonts/Test', True);
  FConfig.SetFont(Node, '', 'JetBrains Mono', 14, StyleBoldItalic, 2);

  Stream := TMemoryStream.Create;
  Reloaded := nil;
  try
    FConfig.WriteToStream(Stream);
    Stream.Position := 0;

    Reloaded := TXmlConfig.Create;
    Reloaded.ReadFromStream(Stream);
    Node := Reloaded.FindNode(Reloaded.RootNode, 'Fonts/Test', False);
    AssertNotNull('Fonts/Test node present after reload', Node);

    FConfig.GetFont(Node, '', Name, Size, Style, Quality, 'default', 10, 0, 0);
    AssertEquals('Name', 'JetBrains Mono', Name);
    AssertEquals('Size', 14, Size);
    AssertEquals('Style', StyleBoldItalic, Style);
    AssertEquals('Quality', 2, Quality);
  finally
    Reloaded.Free;
    Stream.Free;
  end;
end;

initialization
  RegisterTest(TTestXmlConfigFont);

end.
