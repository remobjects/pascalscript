unit ParserUtils;

interface
uses uPSUtils, SysUtils, Classes;

const
  version = 'v0.7';

procedure RaiseError(const errormsg: string; row, col: integer);
function GetLicence: string;

function GetUsedUnitList(list: Tstringlist): string;

function GetTokenName(TokenID: TPSPasToken): string;

const
  NewLine = #13#10;

implementation


function GetTokenName(TokenID: TPSPasToken): string;
begin
  case TokenID of
  {Items that are used internally}
    CSTIINT_Comment: Result := 'Comment(should not encountered)';
    CSTIINT_WhiteSpace: Result := 'WhiteSpace(should not encountered)';
  {Tokens}
    CSTI_EOF: Result := 'End Of File';
    CSTI_Identifier: Result := 'Identifier';
    CSTI_SemiColon: Result := ';';
    CSTI_Comma: Result := ',';
    CSTI_Period: Result := ';';
    CSTI_Colon: Result := ':';
    CSTI_OpenRound: Result := '(';
    CSTI_CloseRound: Result := ')';
    CSTI_OpenBlock: Result := '[';
    CSTI_CloseBlock: Result := ']';
    CSTI_Assignment: Result := ':=';
    CSTI_Equal: Result := '=';
    CSTI_NotEqual: Result := '<>';
    CSTI_Greater: Result := '>';
    CSTI_GreaterEqual: Result := '>=';
    CSTI_Less: Result := '<';
    CSTI_LessEqual: Result := '<=';
    CSTI_Plus: Result := '+';
    CSTI_Minus: Result := '-';
    CSTI_Divide: Result := '/';
    CSTI_Multiply: Result := '*';
    CSTI_Integer: Result := 'Integer';
    CSTI_Real: Result := 'Floatpoint';
    CSTI_String: Result := 'string';
    CSTI_Char: Result := 'Character';
    CSTI_HexInt: Result := 'Hexadecimal';
    CSTI_AddressOf: Result := '@';
    CSTI_Dereference: Result := '^';
    CSTI_TwoDots : Result := '..';
  {Identifiers}
    CSTII_and: Result := 'and';
    CSTII_array: Result := 'array';
    CSTII_begin: Result := 'begin';
    CSTII_case: Result := 'case';
    CSTII_const: Result := 'const';
    CSTII_div: Result := 'div';
    CSTII_do: Result := 'do';
    CSTII_downto: Result := 'downto';
    CSTII_else: Result := 'else';
    CSTII_end: Result := 'end';
    CSTII_for: Result := 'for';
    CSTII_function: Result := 'function';
    CSTII_if: Result := 'if';
    CSTII_in: Result := 'in';
    CSTII_mod: Result := 'mod';
    CSTII_not: Result := 'not';
    CSTII_of: Result := 'of';
    CSTII_or: Result := 'or';
    CSTII_procedure: Result := 'procedure';
    CSTII_program: Result := 'program';
    CSTII_repeat: Result := 'repeat';
    CSTII_record: Result := 'record';
    CSTII_set: Result := 'set';
    CSTII_shl: Result := 'shl';
    CSTII_shr: Result := 'shr';
    CSTII_then: Result := 'then';
    CSTII_to: Result := 'to';
    CSTII_type: Result := 'type';
    CSTII_until: Result := 'until';
    CSTII_uses: Result := 'uses';
    CSTII_var: Result := 'var';
    CSTII_out: Result := 'out'; //Birb
    CSTII_while: Result := 'while';
    CSTII_with: Result := 'with';
    CSTII_xor: Result := 'xor';
    CSTII_exit: Result := 'exit';
    CSTII_class: Result := 'class';
    CSTII_constructor: Result := 'constructor';
    CSTII_destructor: Result := 'destructor';
    CSTII_inherited: Result := 'inherited';
    CSTII_private: Result := 'private';
    CSTII_public: Result := 'public';
    CSTII_published: Result := 'published';
    CSTII_protected: Result := 'protected';
    CSTII_property: Result := 'property';
    CSTII_virtual: Result := 'virtual';
    CSTII_override: Result := 'override';
    //CSTII_default: Result := 'default'; //Birb
    CSTII_As: Result := 'as';
    CSTII_Is: Result := 'is';
    CSTII_Unit: Result := 'unit';
    CSTII_Try: Result := 'try';
    CSTII_Except: Result := 'except';
    CSTII_Finally: Result := 'finally';
    CSTII_External: Result := 'external';
    CSTII_Forward: Result := 'forward';
    CSTII_Export: Result := 'export';
    CSTII_Label: Result := 'label';
    CSTII_Goto: Result := 'goto';
    CSTII_Chr: Result := 'char';
    CSTII_Ord: Result := 'ord';
    CSTII_Interface: Result := 'interface';
    CSTII_Implementation: Result := 'Implementation';
  else
    Result := '[Unknown Token name]';
  end;
end; {GetTokenName}

function GetUsedUnitList(list: Tstringlist): string;
var
  index: integer;
  charcount: integer;
  s: string;
begin
  if (list <> nil) and (list.Count <> 0) then
  begin
    Result := 'Uses ' + list[0];
    charcount := length(result);
    for index := 1 to list.Count - 1 do
    begin
      s := list[index];
      inc(charcount, length(s));
      if charcount < 80 then
        Result := Result + ', ' + s
      else
      begin
        Result := Result + ', ' + NewLine + s;
        charcount := 0;
      end;
    end;
    Result := Result + ';';
  end
  else
    Result := '';
end; {GetUsedUnitList}

procedure RaiseError(const errormsg: string; row, col: integer);
begin
  raise Exception.create(errormsg + ' At postion: ' + inttostr(row) + ':' + inttostr(col));
end; {RaiseError}

function GetLicence: string;
begin
  result :=
    '{' + NewLine +
    'This file has been generated by UnitParser ' + version + ', written by M. Knight' + Newline +
    'and updated by NP. v/d Spek and George Birbilis. ' + Newline +
    'Source Code from Carlo Kok has been used to implement various sections of' + Newline +
    'UnitParser. Components of ROPS are used in the construction of UnitParser,' + Newline +
    'code implementing the class wrapper is taken from Carlo Kok''s conv utility' + Newline +
    Newline +
    '}';
end; {GetLicence}

end.
