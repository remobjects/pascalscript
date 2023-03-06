program DataTypes;

(*
const
  Eleven = 11;
  Twelfe = 12;
  Thirteen = 13;
  Fourteen = 14;
  Fiveteen = 15;
  Sixteen = 16;
  Seventeen = 17;
  Eightteen = 18;
  Nineteen = 19;
  Twenty = 20;
*)

type
  TEnum = (One, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten);
//  TEnum2 = (Eleven, Twelfe, Thirteen, Fourteen, Fiveteen, Sixteen, Seventeen, Eightteen, Nineteen, Twenty);    

  TRecord = record
    B   : Boolean;
    U8  : Byte;
    S8  : ShortInt;
    U16 : Word;
    S16 : SmallInt;
    U32 : Cardinal;
    S32 : Integer;
//    U64 : UInt64;
    S64 : Int64;
    S   : Single;
    D   : Double;
    E   : Extended;
    ASt : AnsiString;
    WS  : WideString; 
    AC  : AnsiChar;
    WC  : WideChar;
    Enum : TEnum;
//    Enum2 : TEnum2;        
  end;

const
  ArraySize = 10;

type  
  TRecordStaticArray = record
    saB   : Array [ 0..ArraySize-1 ] of Boolean;
    saU8  : Array [ 0..ArraySize-1 ] of Byte;
    saS8  : Array [ 0..ArraySize-1 ] of ShortInt;
    saU16 : Array [ 0..ArraySize-1 ] of Word;
    saS16 : Array [ 0..ArraySize-1 ] of SmallInt;
    saU32 : Array [ 0..ArraySize-1 ] of Cardinal;
    saS32 : Array [ 0..ArraySize-1 ] of Integer;
//    saU64 : Array [ 0..ArraySize-1 ] of UInt64;
    saS64 : Array [ 0..ArraySize-1 ] of Int64;
    saS   : Array [ 0..ArraySize-1 ] of Single;
    saD   : Array [ 0..ArraySize-1 ] of Double;
    saE   : Array [ 0..ArraySize-1 ] of Extended;
    saAS  : Array [ 0..ArraySize-1 ] of AnsiString;
    saWS  : Array [ 0..ArraySize-1 ] of WideString;
    saAC  : Array [ 0..ArraySize-1 ] of AnsiChar;
    saWC  : Array [ 0..ArraySize-1 ] of WideChar;
    saEnum : Array [ 0..ArraySize-1 ] of TEnum;
//    saEnum2 : Array [ 0..ArraySize-1 ] of TEnum2;                 
  end;  

  TRecordArray = record
    aB   : Array of Boolean;
    aU8  : Array of Byte;
    aS8  : Array of ShortInt;
    aU16 : Array of Word;
    aS16 : Array of SmallInt;
    aU32 : Array of Cardinal;
    aS32 : Array of Integer;
//    aU64 : Array of UInt64;
    aS64 : Array of Int64;
    aSi  : Array of Single;
    aD   : Array of Double;
    aE   : Array of Extended;
    aAS  : Array of AnsiString;
    aWS  : Array of WideString;
    aAC  : Array of AnsiChar;
    aWC  : Array of WideChar;
    aEnum : Array of TEnum;
//    aEnum2 : Array of TEnum2;                 
  end; 

var
  B   : Boolean;
  U8  : Byte;
  S8  : ShortInt;
  U16 : Word;
  S16 : SmallInt;
  U32 : Cardinal;
  S32 : Integer;
//  U64 : UInt64;
  S64 : Int64;
  S   : Single;
  D   : Double;
  E   : Extended;
  ASt : AnsiString;
  WS  : WideString; 
  AC  : AnsiChar;
  WC  : WideChar; 
  Enum : TEnum;
//  Enum2 : TEnum2;    
  StrL : TStringList;
  
  saB   : Array [ 0..ArraySize-1 ] of Boolean;
  saU8  : Array [ 0..ArraySize-1 ] of Byte;
  saS8  : Array [ 0..ArraySize-1 ] of ShortInt;
  saU16 : Array [ 0..ArraySize-1 ] of Word;
  saS16 : Array [ 0..ArraySize-1 ] of SmallInt;
  saU32 : Array [ 0..ArraySize-1 ] of Cardinal;
  saS32 : Array [ 0..ArraySize-1 ] of Integer;
//  saU64 : Array [ 0..ArraySize-1 ] of UInt64;
  saS64 : Array [ 0..ArraySize-1 ] of Int64;
  saS   : Array [ 0..ArraySize-1 ] of Single;
  saD   : Array [ 0..ArraySize-1 ] of Double;
  saE   : Array [ 0..ArraySize-1 ] of Extended;
  saAS  : Array [ 0..ArraySize-1 ] of AnsiString;
  saWS  : Array [ 0..ArraySize-1 ] of WideString;
  saAC  : Array [ 0..ArraySize-1 ] of AnsiChar;
  saWC  : Array [ 0..ArraySize-1 ] of WideChar;
  saEnum : Array [ 0..ArraySize-1 ] of TEnum;
//  saEnum2 : Array [ 0..ArraySize-1 ] of TEnum2;     
  
  aB   : Array of Boolean;
  aU8  : Array of Byte;
  aS8  : Array of ShortInt;
  aU16 : Array of Word;
  aS16 : Array of SmallInt;
  aU32 : Array of Cardinal;
  aS32 : Array of Integer;
//  aU64 : Array of UInt64;
  aS64 : Array of Int64;
  aSi  : Array of Single;
  aD   : Array of Double;
  aE   : Array of Extended;
  aAS  : Array of AnsiString;
  aWS  : Array of WideString;
  aAC  : Array of AnsiChar;
  aWC  : Array of WideChar;
  aEnum : Array of TEnum;
//  aEnum2 : Array of TEnum2;         

  TestRecord : TRecord;
  TestRecordStaticArray : TRecordStaticArray;
  TestRecordArray : TRecordArray;
  
  i : Integer;  
begin
  B   := True;
  U8  := 127;
  S8  := -127;
  U16 := 12345;
  S16 := -12345;
  U32 := 123456789;
  S32 := -123456789;
// U64 := 123456789;
  S64 := -1234567890123;
  S   := 1234567.123;
  D   := 123456789.123456789;
  E   := 123456789.123456789;
  ASt := 'This is a Test String (ANSI)';
  WS  := 'This is a Test String (WIDE)'; 
  AC  := 'A';
  WC  := 'W';
  Enum := Seven;
//  Enum2 := Seventeen;       

  StrL := TStringList.Create;
  StrL.Add( 'Line One' );
  StrL.Add( 'Line Two' );  

  TestRecord.B   := True;
  TestRecord.U8  := 127;
  TestRecord.S8  := -127;
  TestRecord.U16 := 12345;
  TestRecord.S16 := -12345;
  TestRecord.U32 := 123456789;
  TestRecord.S32 := -123456789;
// TestRecord.U64 := 123456789;
  TestRecord.S64 := -1234567890123;
  TestRecord.S   := 1234567.123;
  TestRecord.D   := 123456789.123456789;
  TestRecord.E   := 123456789.123456789;
  TestRecord.ASt := 'This is a Test String (ANSI)';
  TestRecord.WS  := 'This is a Test String (WIDE)';
  TestRecord.AC  := 'A';
  TestRecord.WC  := 'W';
  TestRecord.Enum := Seven;
//  TestRecord.Enum2 := Seven;        
  
  // Static Array
  for i := Low( saB ) to High( saB ) do
    begin
    saB[i] := ( i mod 2 = 0 );
    saU8[i] := i;
    saS8[i] := -i;
    saU16[i] := i;
    saS16[i] := -i;
    saU32[i] := i;
    saS32[i] := -i;
//    saU64[i] := i;
    saS64[i] := -i;
    saS[i] := i + i*0.3;
    saD[i] := i + i*0.3;
    saE[i] := i + i*0.3;
    saAS[i] := 'This is a Test String (ANSI)';
    saWS[i] := 'This is a Test String (WIDE)';
    saAC[i] := 'A';
    saWC[i] := 'W';
    saEnum[i] := Seven;
//    saEnum2[i] := Seventeen;               
    end;    
  
  // Static Array (Record)
  for i := Low( TestRecordStaticArray.saB ) to High( TestRecordStaticArray.saB ) do
    begin
    TestRecordStaticArray.saB[i] := ( i mod 2 = 0 );
    TestRecordStaticArray.saU8[i] := i;
    TestRecordStaticArray.saS8[i] := -i;
    TestRecordStaticArray.saU16[i] := i;
    TestRecordStaticArray.saS16[i] := -i;
    TestRecordStaticArray.saU32[i] := i;
    TestRecordStaticArray.saS32[i] := -i;
//    TestRecordStaticArray.saU64[i] := i;
    TestRecordStaticArray.saS64[i] := -i;
    TestRecordStaticArray.saS[i] := i + i*0.3;
    TestRecordStaticArray.saD[i] := i + i*0.3;
    TestRecordStaticArray.saE[i] := i + i*0.3;
    TestRecordStaticArray.saAS[i] := 'This is a Test String (ANSI)';
    TestRecordStaticArray.saWS[i] := 'This is a Test String (WIDE)';
    TestRecordStaticArray.saAC[i] := 'A';
    TestRecordStaticArray.saWC[i] := 'W';
    TestRecordStaticArray.saEnum[i] := Seven;
//    TestRecordStaticArray.saEnum2[i] := Seventeen;                
    end;  

  // Dynamic Array
  SetLength( aB, ArraySize );
  SetLength( aU8, ArraySize );
  SetLength( aS8, ArraySize );
  SetLength( aU16, ArraySize );
  SetLength( aS16, ArraySize );
  SetLength( aU32, ArraySize );
  SetLength( aS32, ArraySize );
//  SetLength( aU64, ArraySize );
  SetLength( aS64, ArraySize );
  SetLength( aSi, ArraySize );
  SetLength( aD, ArraySize );
  SetLength( aE, ArraySize );
  SetLength( aAS, ArraySize );
  SetLength( aWS, ArraySize );
  SetLength( aAC, ArraySize );
  SetLength( aWC, ArraySize );
  SetLength( aEnum, ArraySize );
//  SetLength( aEnum2, ArraySize );      
 
  for i := Low( aB ) to High( aB ) do
    begin
    aB[i] := ( i mod 2 = 0 );
    aU8[i] := i;
    aS8[i] := -i;
    aU16[i] := i;
    aS16[i] := -i;
    aU32[i] := i;
    aS32[i] := -i;
//    aU64[i] := i;
    aS64[i] := -i;
    aSi[i] := i + i*0.3;
    aD[i] := i + i*0.3;
    aE[i] := i + i*0.3;
    aAS[i] := 'This is a Test String (ANSI)';
    aWS[i] := 'This is a Test String (WIDE)';
    aAC[i] := 'A';
    aWC[i] := 'W';
    aEnum[i] := Seven;
//    aEnum2[i] := Seventeen;                
    end;      

  // Dynamic Array (Record)
  SetLength( TestRecordArray.aB, ArraySize );
  SetLength( TestRecordArray.aU8, ArraySize );
  SetLength( TestRecordArray.aS8, ArraySize );
  SetLength( TestRecordArray.aU16, ArraySize );
  SetLength( TestRecordArray.aS16, ArraySize );
  SetLength( TestRecordArray.aU32, ArraySize );
  SetLength( TestRecordArray.aS32, ArraySize );
//  SetLength( TestRecordArray.aU64, ArraySize );
  SetLength( TestRecordArray.aS64, ArraySize );
  SetLength( TestRecordArray.aSi, ArraySize );
  SetLength( TestRecordArray.aD, ArraySize );
  SetLength( TestRecordArray.aE, ArraySize );
  SetLength( TestRecordArray.aAS, ArraySize );
  SetLength( TestRecordArray.aWS, ArraySize );
  SetLength( TestRecordArray.aAC, ArraySize );
  SetLength( TestRecordArray.aWC, ArraySize );
  SetLength( TestRecordArray.aEnum, ArraySize );
//  SetLength( TestRecordArray.aEnum2, ArraySize );      
 
  for i := Low( TestRecordArray.aB ) to High( TestRecordArray.aB ) do
    begin
    TestRecordArray.aB[i] := ( i mod 2 = 0 );
    TestRecordArray.aU8[i] := i;
    TestRecordArray.aS8[i] := -i;
    TestRecordArray.aU16[i] := i;
    TestRecordArray.aS16[i] := -i;
    TestRecordArray.aU32[i] := i;
    TestRecordArray.aS32[i] := -i;
//    TestRecordArray.aU64[i] := i;
    TestRecordArray.aS64[i] := -i;
    TestRecordArray.aSi[i] := i + i*0.3;
    TestRecordArray.aD[i] := i + i*0.3;
    TestRecordArray.aE[i] := i + i*0.3;
    TestRecordArray.aAS[i] := 'This is a Test String (ANSI)';
    TestRecordArray.aWS[i] := 'This is a Test String (WIDE)';
    TestRecordArray.aAC[i] := 'A';
    TestRecordArray.aWC[i] := 'W';
    TestRecordArray.aEnum[i] := Seven;
//    TestRecordArray.aEnum2[i] := Seventeen;                
    end;
    
  SetLength( aB, 0 );
  SetLength( aU8, 0 );
  SetLength( aS8, 0 );
  SetLength( aU16, 0 );
  SetLength( aS16, 0 );
  SetLength( aU32, 0 );
  SetLength( aS32, 0 );
//  SetLength( aU64, 0 );
  SetLength( aS64, 0 );
  SetLength( aSi, 0 );
  SetLength( aD, 0 );
  SetLength( aE, 0 );
  SetLength( aAS, 0 );
  SetLength( aWS, 0 );     
  SetLength( aAC, 0 );
  SetLength( aWC, 0 );
  SetLength( aEnum, 0 );
//  SetLength( aEnum2, 0 );      
    
  SetLength( TestRecordArray.aB, 0 );
  SetLength( TestRecordArray.aU8, 0 );
  SetLength( TestRecordArray.aS8, 0 );
  SetLength( TestRecordArray.aU16, 0 );
  SetLength( TestRecordArray.aS16, 0 );
  SetLength( TestRecordArray.aU32, 0 );
  SetLength( TestRecordArray.aS32, 0 );
//  SetLength( TestRecordArray.aU64, 0 );
  SetLength( TestRecordArray.aS64, 0 );
  SetLength( TestRecordArray.aSi, 0 );
  SetLength( TestRecordArray.aD, 0 );
  SetLength( TestRecordArray.aE, 0 );
  SetLength( TestRecordArray.aAS, 0 );
  SetLength( TestRecordArray.aWS, 0 );
  SetLength( TestRecordArray.aAC, 0 );
  SetLength( TestRecordArray.aWC, 0 );
  SetLength( TestRecordArray.aEnum, 0 );
//  SetLength( TestRecordArray.aEnum2, 0 );          
end.