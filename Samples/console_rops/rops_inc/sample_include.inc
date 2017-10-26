{ sample_include.inc }

procedure println(L: string);
begin
  writeln(L);
end;

procedure make_error(e: string);
begin
  RaiseExceptionMessage(e);
end;
