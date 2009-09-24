{ compiletime ComObj support }
unit uPSC_comobj;

{$I PascalScript.inc}
interface
uses
  uPSCompiler, uPSUtils;

{
 
Will register:
 
function CreateOleObject(const ClassName: String): IDispatch;
function GetActiveOleObject(const ClassName: String): IDispatch;

}

procedure SIRegister_ComObj(cl: TPSPascalCompiler);

implementation

procedure SIRegister_ComObj(cl: TPSPascalCompiler);
begin
  cl.AddTypeS('TGUID', 'record D1: LongWord; D2: Word; D3: Word; D4: array[0..7] of Byte; end;');
{$IFNDEF PS_NOINTERFACES}
{$IFDEF DELPHI3UP}
  cl.AddDelphiFunction('function StringToGUID(const S: string): TGUID;');
  cl.AddDelphiFunction('function CreateComObject(const ClassID: TGUID): IUnknown;');
{$ENDIF}
{$ENDIF}
  cl.AddDelphiFunction('function CreateOleObject(const ClassName: String): IDispatch;');
  cl.AddDelphiFunction('function GetActiveOleObject(const ClassName: String): IDispatch;');
end;

end.
