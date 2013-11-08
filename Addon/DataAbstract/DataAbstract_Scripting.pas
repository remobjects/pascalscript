{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit DataAbstract_Scripting;

interface

uses
  DataAbstract_Scripting_Reg, uDAPascalScript, uDAPSScriptingProvider, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('DataAbstract_Scripting_Reg', 
    @DataAbstract_Scripting_Reg.Register);
end;

initialization
  RegisterPackage('DataAbstract_Scripting', @Register);
end.
