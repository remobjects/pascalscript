@del /S *.dcu;*.drc;*.dex;*.rsm;*.~*>nul 2>nul
@del dcc32.log>nul 2>nul

@if exist _dcu (
 pushd _dcu
 del /Q *.*>nul 2>nul
 popd
)
