{
   Double Commander
   -------------------------------------------------------------------------
   Dark mode options page

   Copyright (C) 2006-2025 Alexander Koblov (alexx2000@mail.ru)

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with this program; if not, write to the Free Software Foundation, Inc.,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
}

unit fOptionsDarkMode;

{$mode objfpc}{$H+}

{$IF DEFINED(darwin)}
  {$DEFINE DARKWIN}
{$ENDIF}

interface

uses
  Classes, SysUtils, Dialogs, StdCtrls, ExtCtrls, fOptionsFrame;

type

  { TfrmOptionsDarkMode }

  TfrmOptionsDarkMode = class(TOptionsEditor)
    rgDarkMode: TRadioGroup;
    lblUnsupported: TLabel;
  private
    FAppMode: Integer;
  protected
    procedure Init; override;
    procedure Load; override;
    function Save: TOptionsEditorSaveFlags; override;
  public
    class function GetIconIndex: Integer; override;
    class function GetTitle: String; override;
  end;

implementation

{$R *.lfm}

uses
  uGlobs, uLng, DCStrUtils, uEarlyConfig
{$IF not DEFINED(darwin)}
  , uDarkStyle
{$ELSE}
  , uDarwinApplication
{$ENDIF}
  ;

{ TfrmOptionsDarkMode }

procedure TfrmOptionsDarkMode.Init;
var
  ASupported: Boolean = True;
begin
  ParseLineToList(rsDarkModeOptions, rgDarkMode.Items);
  FAppMode:= gAppMode;
{$IFDEF LCLWIN32}
  ASupported:= g_darkModeSupported;
{$ENDIF}
  rgDarkMode.Enabled:= ASupported;
  lblUnsupported.Visible:= not ASupported;
  if not ASupported then
    lblUnsupported.Caption:= rsDarkModeUnsupported;
end;

procedure TfrmOptionsDarkMode.Load;
begin
  case FAppMode of
    1: rgDarkMode.ItemIndex:= 0;
    2: rgDarkMode.ItemIndex:= 1;
    3: rgDarkMode.ItemIndex:= 2;
  end;
end;

function TfrmOptionsDarkMode.Save: TOptionsEditorSaveFlags;
begin
  Result:= [];
  case rgDarkMode.ItemIndex of
    0: gAppMode:= 1;
    1: gAppMode:= 2;
    2: gAppMode:= 3;
  end;
  if gAppMode <> FAppMode then
  try
    FAppMode:= gAppMode;
    {$IF not DEFINED(darwin)}
    if g_darkModeSupported then
      Result:= [oesfNeedsRestart];
    {$ELSE}
    TDarwinApplicationUtil.setTheme( gAppMode );
    {$ENDIF}
    SaveEarlyConfig;
  except
    on E: Exception do MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

class function TfrmOptionsDarkMode.GetIconIndex: Integer;
begin
  Result:= 4;
end;

class function TfrmOptionsDarkMode.GetTitle: String;
begin
  Result:= rsDarkMode;
end;

end.
