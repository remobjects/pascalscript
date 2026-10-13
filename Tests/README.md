# PascalScript test suite

`PascalScriptTestSuite.dpr` is a single self-contained console program that
exercises the PascalScript compiler and runtime in `../Source`.  It has no
dependencies beyond the RTL, needs no command line arguments and never asks
for input.  Every check prints one of three verdicts:

* `PASS` - the behavior was verified,
* `FAIL` - the behavior is wrong (the process exit code becomes 1),
* `SKIP` - the behavior cannot be verified on this tree/platform; the reason
  is printed in brackets.

The last line is always

    Total: N  Passed: N  Failed: N  Skipped: N

and the exit code is 0 exactly when `Failed` is 0, so the program is directly
usable in CI.

## Building and running

The suite compiles with Delphi 7 through current Delphi versions (Win32 and
Win64) and with Free Pascal 3.2.2 (`-Mdelphi`).  From the `Tests` directory:

```
rem Delphi (any recent version, 32 bit)
dcc32 -B -NSSystem.Win;Winapi;System;Vcl -I..\Source -U..\Source PascalScriptTestSuite.dpr

rem Delphi 64 bit
dcc64 -B -NSSystem.Win;Winapi;System;Vcl -I..\Source -U..\Source PascalScriptTestSuite.dpr

rem Delphi 7
dcc32 -B -I..\Source -U..\Source PascalScriptTestSuite.dpr

# Free Pascal 3.2.2
fpc -Mdelphi -Fu../Source PascalScriptTestSuite.dpr

.\PascalScriptTestSuite.exe
```

Conditional defines the sources understand (for trees that support them) can
simply be added to the command line, e.g. `-DPS_NATIVESTRINGS` or
`-DPS_USECLASSICINVOKE`; the suite adapts automatically.

Arguments are optional: when present, the ParamStr section additionally
cross-checks `ParamStr(1)` between script and host.

## The SKIP philosophy

The exact same source file is meant to run against *any* state of the
PascalScript sources - plain upstream master as well as trees carrying
additional fixes or features.  A test suite that fails on features a tree
simply does not have would be useless for bisecting, so the suite
distinguishes between "wrong" and "absent":

* **Script-language features** (set-range literals, `packed`, `raise`,
  `ParamCount`/`ParamStr`, the `AnsiChar`/`PAnsiChar`/`PWideChar` script
  types, ...) are detected at runtime by trying to compile a small snippet
  (`FeatureCompiles`).  If the snippet does not compile, the section reports
  SKIP with the reason.
* **Optional unit-level host APIs** (`StringToPSVariant`,
  `PSVariantToString(AppendType, NoQuotes)`) are gated at compile time with
  `{$IF DECLARED(...)}` so the suite still builds on trees without them.
* **Behavioral fixes** (catchable failing casts, `Variant` <-> interface
  assignments, IDispatch values crossing the script boundary, dynamic arrays
  through the invoke path, P-char parameters of DLL imports, single-character
  literals in `array of const`, ...) are *probed*: the minimal scenario runs
  first and stores its observation; only when the probe shows sane behavior
  are the real assertions made, otherwise the section reports SKIP including
  what the probe saw (e.g. `got "42/?"`).  A section that cannot run is
  always visible as SKIP with a reason - it is never silently absent.
### Strict mode (`-strict`)

Probe-detected broken behavior normally reports SKIP so that the suite stays
green on vanilla upstream while still documenting every defect. Pass
`-strict` as the first argument to turn exactly those probe-skips into
FAILURES: on a tree where the fixes are supposed to be present, a regression
then flips the exit code instead of hiding as a skip. Feature-skips (a
script type or keyword the tree simply does not have) and platform-skips
stay skips even in strict mode.

Recommended usage: run without arguments against foreign/vanilla trees, run
`-strict` in CI against your own tree.

* **Platform differences** use plain conditional compilation: COM and DLL
  imports are Windows-only, the memory-usage helper has FPC/Delphi 7
  fallbacks, and expectations that depend on the script character width are
  computed from `SizeOf(TbtChar)` instead of being hard-coded.

Two portability details worth knowing when extending the suite:

* The byte buffer between `TPSPascalCompiler.GetOutput`, `TPSExec.LoadData`
  and `IFPS3DataToText` is declared as
  `{$IFDEF PS_NATIVESTRINGS}TbtAnsiString{$ELSE}TbtString{$ENDIF}` (type
  `TPSData` in the suite).  Trees that predate `PS_NATIVESTRINGS` never
  define it, so they always see plain `TbtString`.
* Host-side parameters for script `string` arguments use `TScrStr`
  (`UnicodeString` on Unicode Delphi, `string` elsewhere).

## Sections

| #  | Section                  | Covers |
|----|--------------------------|--------|
| 01 | Basics                   | compile/load/run, integer/byte/Int64 arithmetic, function results, locals, string/AnsiString indexing (StrGet/StrSet), concatenation, `Ord` |
| 02 | CompatRules              | `IsCompatibleType`: assignments that must keep compiling (string/WideString/char/Variant) and, when the precedence fix is present, `Integer := string` & friends being rejected again |
| 03 | OrdChr                   | `Ord`/`Chr` on `Char` and (when available) `AnsiChar` |
| 04 | SetRangeLiterals         | constant ranges in set literals: `['0'..'9']`, multiple ranges, mixed single values + ranges, byte ranges up to 255, enum ranges, empty inverted ranges |
| 05 | PackedTypes              | the `packed` keyword in script and `AddTypeS` declarations (issue #246), `packed` before non-structured types still rejected |
| 06 | CompilerReuse            | one `TPSPascalCompiler` instance surviving a failing `OnUses` registration and compiling again afterwards |
| 07 | RegisterPropertyFailure  | `RegisterProperty` with an unresolvable type must raise instead of silently dropping the property |
| 08 | LoadDataErrorMessages    | truncated bytecode streams are refused with an exception code set, the full stream still loads |
| 09 | ArrayOfConst             | inline `array of const` arguments (issue #296), element types string/Integer/PChar/AnsiString/PAnsiChar/AnsiChar, single-character literal elements (probed) |
| 10 | RaiseAndParams           | `ParamCount`/`ParamStr` builtins (cross-checked against the host), `raise Exception.Create(...)`, bare `raise` re-raising, `ExceptionType`/`ExceptionParam`, handler control flow |
| 11 | Interfaces               | `Variant` <-> interface assignments, casts via QueryInterface, `Unassigned` -> nil |
| 12 | CatchableCastErrors      | a failing interface cast raises a script-catchable error instead of killing the execution |
| 13 | COM (Windows)            | IDispatch late binding via `Variant` (Scripting.Dictionary): property put/get, method calls, catchable COM exceptions, IDispatch values as arguments/results (probed), clean CoUninitialize |
| 14 | DllImport (Windows)      | script-declared kernel32 imports: integer parameters, `delayload`, `UnloadDll`, P-char parameters (probed) |
| 15 | WideStrings              | extern string/AnsiString marshaling, stack-spilled parameters (8 ints, 5 strings, Int64, Double), char width, PWideChar/PAnsiChar interop |
| 16 | RecordInterop            | records crossing the host boundary by `var`/`const` parameter, including AnsiChar fields, static AnsiChar array fields and `set of AnsiChar` |
| 17 | PCharOwnership           | script-owned P-char values: aliasing, self/cross assignment, re-owning host pointers (results, var params, record fields), stress loop, leak check over a full compile/run cycle |
| 18 | DebugHelpers             | `PSVariantToString` (quoting, `AppendType`, `NoQuotes`) and `StringToPSVariant` on Integer/string/WideString/Char/dyn array/record/set/Variant/Double (`{$IF DECLARED}`-gated) |
| 19 | Disassembly              | `IFPS3DataToText` produces a listing with intact string constants |
| 20 | DynArrayInvoke           | dynamic arrays as function result and by-value parameter of imported host functions (issue #198 area, probed; runs last because unfixed trees crash inside the invoke path) |

## Edge cases covered only by standalone tests

A few checks from the historical standalone test programs are deliberately
not part of this suite:

* **RTTI-based type registration** (`TPSPascalCompiler.AddType(PTypeInfo)`,
  `AddRecordWithRTTI`): these are *methods* of `TPSPascalCompiler`, and
  `{$IF DECLARED(...)}` can only detect unit-level symbols, so there is no
  way to compile the calls conditionally on trees without the feature.
* **UInt64 full-range arithmetic**: needs both a host compiler with real
  UInt64 support (Delphi 2010+/FPC) and tree-side support; the standalone
  test gates on `CompilerVersion` and would add host-compiler-dependent
  PASS/SKIP noise here.
* **`PSBorrowPCharOwnership`** is not called directly (it is an
  implementation detail of the invoke paths); its effect is verified
  behaviorally by section 17.
* **Crash-hard scenarios** (deliberately corrupted bytecode beyond simple
  truncation, invoke-path access violations) are kept out because a suite
  that must survive any tree state cannot afford scenarios that may take the
  process down; section 20 only probes them defensively.

## Reference results

Without `-strict` all cells end with `Failed: 0`; the pass/skip split depends
on how many features the tree has. Numbers from July 2026:

| Tree | Compiler | Total | Passed | Skipped | strict Failed |
|------|----------|-------|--------|---------|---------------|
| upstream master | Delphi 12 Win32 | 93 | 70 | 23 | 10 |
| upstream master | Delphi 12 Win64 | 93 | 70 | 23 | 10 |
| all bug fixes applied | Delphi 12 Win32 | 128 | 117 | 11 | 2 |
| all bug fixes applied | Delphi 7 | 128 | 119 | 9 | 1 |
| native-strings tree (default) | Delphi 12 Win32 | 128 | 117 | 11 | 2 |
| native-strings tree, `PS_NATIVESTRINGS` | Delphi 12 Win32/Win64, default and classic invoke | 153 | 152 | 1 | 0 |
| native-strings tree (default and `PS_NATIVESTRINGS`) | FPC 3.2.2 x86_64-linux | 116 | 105 | 11 | 1 |

The remaining strict failures are real, currently unfixed defects that the
suite documents:

* **raw btPChar assignments dangle** (all trees without p-char ownership):
  `SetVariantValue` assigns `pansichar(dest^) := pansichar(PSGetAnsiString(...))`,
  i.e. the slot points into a TEMPORARY string that is freed right after the
  statement. Any later use of the P-char value reads freed memory (visible
  as `lstrlenA(...) = 4` in section 14). Trees with owned p-char slots pass.
* **PChar elements in `array of const` arrive as vtPointer** on the Rtti
  invoke path (section 09); fixed on the native-strings tree.
* **by-value dynarray parameters crash on FPC x86_64-linux** through the
  classic x64 path (section 20); the Windows paths pass.

Upstream master itself does not compile with Delphi 7 (`Low`/`High` on
`tbtU64` constants in `uPSCompiler.pas`) or FPC 3.2.2 (`Inc`/`Dec` on
`Variant` and a `ResultAsRegister` implementation hidden behind
`empty_methods_handler` in `uPSRuntime.pas`); those cells become possible
once the corresponding compatibility fixes are applied to the sources.
