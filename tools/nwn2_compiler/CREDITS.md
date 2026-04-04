# NWNScriptCompiler Credits

NO CREDIT GOES TO CROMFR FOR THE NWNSCRIPTCOMPILER  
http://neverwintervault.org/project/nwn2/other/tool/advanced-script-compiler-nwn2

NWNScriptCompiler is an improved version of Edward T. Smith (Torlack's)
nwnnsscomp, with numerous bugfixes and improvements. It is a standalone,
console driven compiler suitable for batch usage outside of the toolset.

## Improvements over the stock nwnnsscomp include

- New -l option to load resources from the game zip files.
- New -b option for true batch mode under Windows.
- New -r option to load module.ifo from any path.
- Nested structs are now usable and do not produce an erroneous syntax error.
- Case statement blocks now obey proper rules for variable declarations; it is
  no longer possible to declare a variable that is skipped by a case statement,
  which would not compile with the standard (toolset) script compiler.
- The main and StartingConditional symbols are now required to be functions.
- Prototypes that do not match their function declarations are now fixed up by
  the compiler (with a warning) if compiler version 1.69 or lower is specified.
  This allows several broken include scripts shipped with the game to compile.
- Script analysis and verification can be enabled via the -a command line
  option.
- Response files are supported with the @ResponseFile option.
- Script disassembly now generates high-level IR output (.ir and .ir-opt).
- Existing nwnnsscomp options are preserved and kept functional.

Run `NWNScriptCompiler -?` for a listing of command line options and meanings.
