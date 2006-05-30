
A modified UnitParser which creates a single import unit
---------------------------------------------------------
  IFPS3  1.21 
  Delphi 7 Enterprise
---------------------------------------------------------

Hi there

I've modified the "imp" application a little.
The "imp" application is written by M. Knight.

Mainly I've added the private
  procedure FinishParseSingleUnit;
to the ParserU.TUnitParser

Now the UnitParser, (if the -added property-
SingleUnit is True), creates a single import unit file
after parsing the source file.

The produced import file is given the name
  UnitPrefix + '_' + SourceUnitName + '.pas'
when SingleUnit is True

Also the
  procedure TUnitParser.SaveToPath(const Path: string);
is added in order to save the produced file
(or files if SingleUnit is False)

When SingleUnit is True the produced import file
contains 
	the compile-time registration code
	the run-time registration code
	and a TIFPS3Plugin descendant, say TImport_XXX, 
which imports the registration code

In order to use the produced import file, add
its name to a uses clause and then code
  XXX_Importer := TImport_XXX.Create(Self);
  TIFPS3CEPluginItem(Debugger.Plugins.Add).Plugin := XXX_Importer;   
or just install TImport_XXX as a component,
drop it on a form, etc. etc...   

I prefer the first method since it's more flexible
and I modify my units all the time.

Also, I've created an import file for the DBClient.pas
since I use the TClientDataset too often.
The DBClientImport folder contains the -truncated- 
source of the DBClient.pas (that's all the code I import)
and the produced import file. You may take a look.


Theo Bebekis
teo@epektasis.gr

