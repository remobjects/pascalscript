unit Extendedreg;

interface

procedure Register;          

implementation

uses classes, IFSI_IBX, {IFSI_lumSystem, IFSI_ImpExpStruct,} IFSI_JvMail, IFSI_Dialogs, IFSI_Registry;

procedure Register;
begin
  RegisterComponents('Innerfuse', [TIFPS3CE_IBX, {TIFPS3CE_lumSystem, TIFPS3CE_ImpExpStruct,}
                                   TIFPS3CE_JvMail, TIFPS3CE_Dialogs, TIFPS3CE_Registry]);

end;

end.
