This program requires SynEdit (http://synedit.sf.net) to compile.


UnitParser v0.4, written by M. Knight.
UnitParser v0.5, updated by NP. v/d Spek, 21-oct-2003

Source Code from Carlo Kok has been used to implement various sections of
UnitParser. Components of ifps3 are used in the construction of UnitParser,
code implementing the class wrapper is taken from Carlo Kok's conv unility

This version works with the newExec source from Carlo Kok's IFPS so now all 
identifirs are normal cased.

Licence :
This software is provided 'as-is', without any expressed or implied
warranty. In no event will the author be held liable for any damages
arising from the use of this software.
Permission is granted to anyone to use this software for any kind of
application, and to alter it and redistribute it freely, subject to
the following restrictions:
1. The origin of this software must not be misrepresented, you must
   not claim that you wrote the original software.
2. Altered source versions must be plainly marked as such, and must
   not be misrepresented as being the original software.
3. You may not create a library that uses this library as a main part
   of the program and sell that library.
4. You must have a visible line in your programs aboutbox or
   documentation that it is made using Innerfuse Script and where
   Innerfuse Pascal Script can be found.
5. This notice may not be removed or altered from any source
   distribution.

It can currently handle :
- Constants(both with explicit & implicit type),
- Global variables are parsed, but no output is generated for them
  As I would need to be able to set their value at startup, or generate
  getters & setters for them(need info before I can do this)
- Normal Delphi routines are properly encaptulated

The following different types :
- simple typing ie 'MyInt = Integer;'
- type identity ie 'MyInt =  type Integer;' (it drops the 'type' and then
  handles it like simple typing)
- method pointers(function pointers are not supported by ifps3)
- Enums ie 'MyEnum = (ab,abc);'
- sets are correctly parsed
- records, and nested records
- classes
- dynamic arrays only (static arrays are not implemented by the ifps3 to my
  knowlage)
- On discovering a function marked with the overload directive, it prompts
  for a new function name, and then generates wrapper code that maps the 
  new method name to the original version. Press enter to use the same name
  * NVDS> fixed some bug's here. 
- Some constant expressions cause the parser to get confused
  (<constname>=<constname>). It will then prompt for the correct
  Expression type (string, integer, char, boolean, etc)

Todo:
- Add MUCH better error reporting
- Add a symbol table to keep track of dereferenced data types to flag them
  as non importable & allow better constant parsing.
- Add support for interfaces to be correctly parsed & generate wrapper
  classes for them.
- Combining more then one orginal file to one IFPS-import file.
- Handling constante sets.
- Add correct support to handle Abstract functions and Procedures.

Added in version 0.5 (NVDS):
- Posiblity to see the Orginal soure code, master source code and after converting 
  the result code files.
- Added the choice of makking a single file or not.
- Created a INI-project file with all the settings.
- Modified files are saved as *.int.
- Fixed the way of handling Overloaded functions.
- Now all identifiers are all normal cased.

Added in version 0.4 :
- Fixed spelling errors in readme.txt & output file
- Fixed parsing of multidimensional arrays & arrays with the size of a type
- Improved error reporting, by default the last 5 tokens are reported. It is
  posible to have more tokens listed. The token string is RECONTRUCTED so will
  NOT containt any comments, formatting or exact casing.

Added in version 0.31 :
- Fixed error that would result in the files bwing written to in the root 
  of the drive, if a output dir wasnt supplied.
- Fixed error in code generation when the '-U' flag was used (prevent the 
  class parent's name from being written).
- Now defaults to '-u' instead of '-UseUnitAtDT'
- Updated readme.txt

Added in version 0.3 :
- Added command line options
- Added the better clas registration code generation (handles forward
  declarations)
- now uses the 'conv.ini' file that Carlo Kok's Conv utility does.
- Altered the file BigIni.pas to NOT include references to VCL

Added in version 0.2 (not release to public):
- Added an option that controls how the design time import module is
  generated.
  Now it is posible to generate design time wrapper units without using the
  wrapped unit.
- Fixed a bug in the constant expression parser, #10#13 is now interpreted
  as a string instead as a char
- Output files are now generated in the same directory as the file being
  wrapped by default.
  With the option of forcing all generated files into a spesific folder.


