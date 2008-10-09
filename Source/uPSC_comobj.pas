{ compiletime ComObj support }
unit uPSC_comobj;

{$I PascalScript.inc}
interface
uses
  uPSCompiler, uPSUtils;

{
 
Will register:
 
function CreateOleObject(const ClassName: NativeString): IDispatch;
function GetActiveOleObject(const ClassName: NativeString): IDispatch;

}

procedure SIRegister_ComObj(cl: TPSPascalCompiler);

implementation

procedure SIRegister_ComObj(cl: TPSPascalCompiler);
begin
  cl.AddDelphiFunction('function CreateOleObject(const ClassName: NativeString): IDispatch;');
  cl.AddDelphiFunction('function GetActiveOleObject(const ClassName: NativeString): IDispatch;');
end;

end.
