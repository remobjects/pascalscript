unit DataAbstract_Scripting_Reg;
{----------------------------------------------------------------------------}
{ Data Abstract Library - Pascal Script                                      } 
{                                                                            }
{ (c)opyright RemObjects Software. all rights reserved.                      }
{                                                                            }
{ Using this code requires a valid license of the Data Abstract              }
{ which can be obtained at http://www.remobjects.com.                        }
{----------------------------------------------------------------------------}

{$I DataAbstract.inc}

interface

procedure Register;

implementation

uses
  Classes, uDAPSScriptingProvider, uDARes;

{$R DataAbstract_Scripting_Glyphs.res}

procedure Register;
begin
  RegisterComponents('RemObjects Data Abstract (Legacy)', [TDAPSScriptingProvider]);
end;

end.
