{ console_rops_test_fp64.inc }

function fp64_decl: tbtString;
var s: tbtString;
begin
  s := 'function fp64(';
  s := s + 'p1:string; p2:string; p3:string; p4:string; p5:string; p6:string; p7:string; p8:string; ';
  s := s + 'p9:string; p10:string; p11:string; p12:string; p13:string; p14:string; p15:string; ';
  s := s + 'p16:string; p17:string; p18:string; p19:string; p20:string; p21:string; p22:string; ';
  s := s + 'p23:string; p24:string; p25:string; p26:string; p27:string; p28:string; p29:string; ';
  s := s + 'p30:string; p31:string; p32:string; p33:string; p34:string; p35:string; p36:string; ';
  s := s + 'p37:string; p38:string; p39:string; p40:string; p41:string; p42:string; p43:string; ';
  s := s + 'p44:string; p45:string; p46:string; p47:string; p48:string; p49:string; p50:string; ';
  s := s + 'p51:string; p52:string; p53:string; p54:string; p55:string; p56:string; p57:string; ';
  s := s + 'p58:string; p59:string; p60:string; p61:string; p62:string; p63:string; ';
  s := s + 'var p64:string';
  s := s + '): string';
  Result := s;
end;

function script_fp64(
  // x.AddDelphiFunction(fp64_decl());
  // Sender.Exec.RegisterDelphiFunction(@script_fp64, 'fp64', cdRegister);
  p1: string;
  p2: string;
  p3: string;
  p4: string;
  p5: string;
  p6: string;
  p7: string;
  p8: string;
  p9: string;
  p10: string;
  p11: string;
  p12: string;
  p13: string;
  p14: string;
  p15: string;
  p16: string;
  p17: string;
  p18: string;
  p19: string;
  p20: string;
  p21: string;
  p22: string;
  p23: string;
  p24: string;
  p25: string;
  p26: string;
  p27: string;
  p28: string;
  p29: string;
  p30: string;
  p31: string;
  p32: string;
  p33: string;
  p34: string;
  p35: string;
  p36: string;
  p37: string;
  p38: string;
  p39: string;
  p40: string;
  p41: string;
  p42: string;
  p43: string;
  p44: string;
  p45: string;
  p46: string;
  p47: string;
  p48: string;
  p49: string;
  p50: string;
  p51: string;
  p52: string;
  p53: string;
  p54: string;
  p55: string;
  p56: string;
  p57: string;
  p58: string;
  p59: string;
  p60: string;
  p61: string;
  p62: string;
  p63: string;
  var p64: string
): string;
begin
  p64 := 'var:('+p64+')';
  Result := 'fp64';
end;

{procedure fp64_test();
var r,p64: string;
begin
  p64 := '!p64!';
  r := script_fp64('p1','p2','p3','p4','p5','p6','p7','p8','p9','p10','p11','p12','p13','p14','p15','p16','p17','p18','p19','p20','p21','p22','p23','p24','p25','p26','p27','p28','p29','p30','p31','p32','p33','p34','p35','p36','p37','p38','p39','p40','p41','p42','p43','p44','p45','p46','p47','p48','p49','p50','p51','p52','p53','p54','p55','p56','p57','p58','p59','p60','p61','p62','p63',p64);
  writeln('r="'+r+'"'+'; p64="'+p64+'"');
end;//}
