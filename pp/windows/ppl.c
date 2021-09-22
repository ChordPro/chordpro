/* Portable Perl launcher for Windows, Strawberry Perl + GCC only.
 *
 * Based on ppl.c by Oliver Betz, inspired by "runperl.c" used to
 * compile the original perl.exe
 */

#define CASSERT(pred) switch(0){case 0:case (pred):;} // compile time assert

#include <stdio.h>
#include <windows.h>

// - ".pl" replaces just the extension from .exe to .pl
// variable path conversion to Perl script
static const char pathreplace[] = ".pl";

// search string for Perl DLL
static const char dllsearch[] = "perl5*.dll";

// act like the original "perl.exe" if our name is "perl.exe" (case sensitive!)
static const char perlexe[] = "perl.exe"; // set to NULL to disable

// number of arguments we put in front of the user provided args
#define ARGS_ADDED 1

// debug output. Comment to disable debug output
#ifdef DEBUG
#define DEBUGOUT stderr
#endif

// PATH_MAX is obsolete since Win10?
#define PATHBUFLEN 1000
// additional buffer size for the dll name
#define NAMEBUFLEN   50

// RunPerl.
typedef int (* RunPerl_t)(int argc, char **argv, char **env);

// Main.
int main( int argc, char **argv, char **env ) {

  // Make ourselves known.
  putenv( "PPL_PACKAGED=1.00" );

  // to construct script path from exe path
  char scriptpath[PATHBUFLEN];
  
  // to construct DLL (search) path from exe path
  char dllpath[PATHBUFLEN+NAMEBUFLEN];

  // pointer past (!) last backslash in dllpath buffer
  char *dlldir;

  int i, emulate_perlexe;

  scriptpath[0] = 0;		// ensure a null terminated string
  i = GetModuleFileName( NULL, scriptpath, sizeof(scriptpath) );
  if ( (i > 0)
       && (i < ((int)ARRAYSIZE(scriptpath)-(int)ARRAYSIZE(pathreplace)-(int)1)) ) {

    // limit strrchr search in case of errors (paranoia)
    scriptpath[ARRAYSIZE(scriptpath)-1] = 0;

    (void)memmove(dllpath, scriptpath, sizeof scriptpath);
    dlldir = strrchr(dllpath, '\\'); // find the last backslash
    dlldir = dlldir ? (dlldir + 1) : dllpath; // if find no backslash (unlikely), use the whole buffer
    emulate_perlexe = ((perlexe != 0) &&  (!strncmp(dlldir, perlexe, sizeof perlexe)));

    char *rep = strrchr(scriptpath, pathreplace[0]); // find the last delimiter in path
    if( !rep ) {
      (void)fprintf(stderr, "Failed to find '%c' in %s\n", pathreplace[0], scriptpath);
      return 1; // ---> early return
    }

    if ( (pathreplace[0] == '.') && (pathreplace[1] == 0) ) {
      *rep = 0; // Perl script without extension, drop the '.'
    }
    else {
      (void)memmove(rep, pathreplace, sizeof pathreplace); // paste replacement
    }
#ifdef SCRIPTPREFIX
    rep = strrchr( scriptpath, '\\' );
    if ( !rep ) rep = scriptpath;
    (void)memmove(rep+strlen(SCRIPTPREFIX)+1, rep+1, strlen(rep) );
    (void)memmove(rep+1, SCRIPTPREFIX, strlen(SCRIPTPREFIX) );
    rep[strlen(rep)+strlen(SCRIPTPREFIX)+1] = 0;
#endif
  }
  else {
    (void)fprintf(stderr, "Path to %s is too long for my %I64i bytes buffer \n", argv[0], sizeof(scriptpath));
    return 1; // ---> early return
  }

#ifdef DEBUGOUT
  fprintf( DEBUGOUT, "***** debug info *****\n" );
  fprintf( DEBUGOUT, "%i argv parameters were passed to the exe:\n", argc);
  for ( i = 0; i < argc; i++ ) {
    fprintf( DEBUGOUT, "%i:%s\n", i, argv[i] );
  }
  if ( !emulate_perlexe )
    fprintf(DEBUGOUT, "\nScript to be called: \"%s\"\n", scriptpath);
  else
    fprintf(DEBUGOUT, "\nWe emulate the original perl.exe\n");
#endif

  HINSTANCE hDLL;		// Handle to Perl DLL
  RunPerl_t RunPerl;		// Function pointer
  HANDLE hFind;			// for FindFirstFile()
  WIN32_FIND_DATA ffd;		// for FindFirstFile()

  CASSERT(((sizeof dllsearch)+(sizeof scriptpath)) < (sizeof dllpath));

  // the dllpath buffer is longer than the scriptpath buffer => memmove can't overflow:
  (void)memmove(dlldir, dllsearch, sizeof dllsearch); // build search spec for the Perl DLL
  // remember that dlldir currently points to the last backslash of the path to the exe

#ifdef DEBUGOUT
  fprintf(DEBUGOUT, "DLL search spec:     \"%s\"\n", dllpath);
#endif

  hFind = FindFirstFile( dllpath, &ffd );
  if ( hFind == INVALID_HANDLE_VALUE ) {
    (void)fprintf( stderr, "Could not find %s\n", dllpath );
    return 1; // ---> early return
  }
  // now we have the name of the DLL (without path) in ffd.cFileName

  // search again since our DLL search spec could contain again a backslash!
  dlldir = strrchr(dllpath, '\\'); // find the last backslash in path to get the DLL directory
  dlldir = dlldir ? (dlldir + 1) : dllpath; // if find no backslash (unlikely), set to start of buffer
  // note: a trailing slash is needed for the (stupid) case of a directory with a trailing space!

  *dlldir = 0; // strip the file name spec from the path
  (void)SetDllDirectory(dllpath); // add the directory to the search path
  // as a positive side-effect, this removes the current directory from the search path

#ifdef DEBUGOUT
  fprintf( DEBUGOUT, "DLL name found:      \"%s\" (length = %I64i)\n",
	   ffd.cFileName, strlen(ffd.cFileName) );
  fprintf( DEBUGOUT, "DLL search path set: \"%s\"\n", dllpath);
#endif

  // search first in the directory set by SetDllDirectory()
  hDLL = LoadLibrary(ffd.cFileName);
  if ( !hDLL ) {
    (void)fprintf(stderr, "Failed to load Perl DLL \"%s\" code %li\n", ffd.cFileName, GetLastError());
    (void)FindClose(hFind);
    return 1; // ---> early return
  }
  (void)FindClose(hFind);

  // "RunPerl" works with ActiveState and Strawberry
  RunPerl = (RunPerl_t)GetProcAddress(hDLL, "RunPerl");
  if ( !RunPerl ) {
    (void)FreeLibrary(hDLL);
    (void)fprintf( stderr, "Failed to get RunPerl address in DLL. Check the DLL for name mangling.\n" );
    return 1;			// ---> early return
  }

#ifdef DEBUGOUT
  fprintf( DEBUGOUT, "***** end of debug info *****\n" );
#endif

  if( emulate_perlexe ) {
    // emulate the standard perl.exe
    i = RunPerl( argc, argv, env );
    if( hDLL )
      (void)FreeLibrary(hDLL);
  }
  else {
    // generate "our" argument list with additional entries and terminating NULL pointer
    char **ourargv = (char **)malloc((argc+ARGS_ADDED+1) * sizeof(char**));
    if ( !ourargv ) {
      (void)fprintf(stderr, "Out of memory building new arg list\n");
      return 1;			// ---> early return
    }

    ourargv[0] = argv[0]; // keep filename, although it seems to be dropped by perl
    ourargv[1] = scriptpath; // pass script path to Perl interpreter
    // copy the remaining user provided arguments and the terminating NULL pointer
    for ( i=1; i<=argc; ++i ) {
      ourargv[i+ARGS_ADDED] = argv[i];
    }

    i = RunPerl( argc+ARGS_ADDED, ourargv, env );
    if( hDLL )
      (void)FreeLibrary(hDLL);
    free(ourargv);
  }

  // Pass the return code like original perl.exe does
  return i;

}

