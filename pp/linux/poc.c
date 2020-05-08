/* Dynamic Perl Loader.

This starter runs a Perl application by dynamically locating and
loading the Perl runtime.

The setup is to have a small Perl distribution installed in an
arbitrary directory, and run from there. The subset is based on the
currently installed system perl.

The loader program effectively runs a Perl script named after the
program. If invoked as 'myapp' it will start the perl runtime to run
the script 'myapp.pl'.

Finding out what files to include in the small distribution can be
tedious. A tool like PAR::Packer can help.

Compile options are provided by
  perl -MExtUtils::Embed -e ccopts
Link options:
  -ldl

Optional compile options are PERLSO (the name of the Perl runtime
library) and SCRIPTDIR (where to find the scripts).

Some steps:

	cp -pL ${PERLLIB}/libperl.so ${DEST}/${PERLSO}
	cp -pL ${PERLLIB}/libpthread.so.0 ${DEST}/
	patchelf --set-soname perl530.so ${DEST}/${PERLSO}
	find ${DEST} -name '*.so' -exec patchelf --replace-needed libperl.so.5.30 ${PERLSO} {} \;

*/

#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <EXTERN.h>
#include <perl.h>

void *handle;			/* for dl */

#ifndef PERLSO
#  define PERLSO "perl530.so"
#endif

static pTHX;

void xs_init(pTHX);

static char selfpath[PATH_MAX];	/* /foo/bar */

int main( int argc, char **argv, char **env ) {

  /* Assuming the program binary   /foo/bar/blech */
  char scriptname[PATH_MAX];	/* blech */
  char dllpath[PATH_MAX];	/* /foo/bar/PERLSO */
  memset (selfpath,   0, PATH_MAX);
  memset (scriptname, 0, PATH_MAX);
  memset (dllpath,    0, PATH_MAX);

  if ( readlink ("/proc/self/exe", selfpath, PATH_MAX-1 ) > 0 ) {
    char *p = rindex( selfpath, '/' );
    if ( p ) {
      p++;
      strcpy( scriptname, p );
      *p = 0;
    }
    else
      strcpy( scriptname, selfpath );
#ifdef DEBUG
    fprintf( stderr, "selfpath:   %s\n", selfpath );
    fprintf( stderr, "scriptname: %s\n", scriptname );
#endif
  }
  else {
    strncpy( selfpath, argv[0], PATH_MAX-1 );
    char *p = rindex( selfpath, '/' );
    if ( p ) {
      p++;
      strcpy( scriptname, p );
      *p = 0;
    }
    else {
      p = getcwd( selfpath, PATH_MAX-1 );
      strcat( selfpath, "/" );
      strncpy( scriptname, argv[0], PATH_MAX-1 );
    }
#ifdef DEBUG
    fprintf( stderr, "cwdpath:    %s\n", selfpath );
    fprintf( stderr, "scriptname: %s\n", scriptname );
#endif
  }

  /* Open shared lib. */
  strcpy( dllpath, selfpath );
  strcat( dllpath, PERLSO );

#ifdef DEBUG
  fprintf( stderr, "dllpath:    %s\n", dllpath );
#endif

  handle = dlopen( dllpath, RTLD_LAZY );
  if ( !handle ) {
    fprintf( stderr, "%s\n", dlerror() );
    exit(EXIT_FAILURE);
  }

  /* For clarity, we first fetch all dynamic entry points. */
  static void (*Perl_sys_init3)( int*, char***, char*** );
  Perl_sys_init3 = (void(*)(int*, char***, char***)) dlsym(handle, "Perl_sys_init3");
  static tTHX (*perl_alloc)();
  perl_alloc = (tTHX(*)()) dlsym(handle, "perl_alloc");
  static void (*perl_construct)(pTHX);
  perl_construct = (void(*)(pTHX)) dlsym(handle, "perl_construct");
  static void (*perl_parse)(pTHX, void*, int, char**, char**);
  perl_parse = (void(*)(pTHX, void*, int, char**, char**)) dlsym(handle, "perl_parse");
  static int (*perl_run)(pTHX);
  perl_run = (int(*)(pTHX)) dlsym(handle, "perl_run");
  static void(*perl_destruct)(pTHX);
  perl_destruct = (void(*)(pTHX)) dlsym(handle, "perl_destruct");
  static void(*perl_free)(pTHX);
  perl_free = (void(*)(pTHX)) dlsym(handle, "perl_free");
  /* End of entry points fetching. */
  /* The rest should look rather familiar now. */

  /* Start perl environment. */
  //PERL_SYS_INIT3( &argc, &argv, &env );
  (*Perl_sys_init3)(&argc, &argv, &env);

  /* Create a perl interpreter. */
  my_perl = (*perl_alloc)();

  /* perl_construct */
  (*perl_construct)(aTHX);

  /* Strip unwanted environment variables. */
  static char **ourenv = NULL;
  if ( env ) {
    int envc = 0;
    while ( env[envc] ) envc++;
    ourenv = (char **)calloc( envc+1, sizeof(char**) );
    int j = 0;
    for ( int i=0; i<envc; ++i ) {
      if ( strncmp(env[i], "PERL", 4) && strncmp(env[i], "LD_", 3) ) {
	ourenv[j++] = env[i];
      }
    }
    ourenv[j] = NULL;
    env = ourenv;
  }

  /* For argument fiddling. */
  static char **ourarg = NULL;

  /* If we're "perl", behave like perl. */
  if ( !strncmp( scriptname, "perl", 4 ) ) {
    (*perl_parse)( aTHX, xs_init, argc, argv, env );
  }
  else {

    /* Insert script name in argv. */
    char scriptpath[PATH_MAX];	/* /foo/bar/SCRIPTPREFIXblech.pl */
    strcpy( scriptpath, selfpath );
#ifdef SCRIPTPREFIX
    strcat( scriptpath, "script/" );
#endif
    strcat( scriptpath, scriptname );
    strcat( scriptpath, ".pl" );
#ifdef DEBUG
    fprintf( stderr, "scriptpath: %s\n", scriptpath );
#endif

#   define EXTRA_ARGS 1
    char **ourarg = (char **)calloc( argc+1+EXTRA_ARGS, sizeof(char**) );
    ourarg[0] = scriptpath;	/* for FindBin and friends */
    ourarg[1] = scriptpath;	/* script to execute */
    for ( int i=1; i<=argc; ++i ) {
      ourarg[i+EXTRA_ARGS] = argv[i];
    }
    (*perl_parse)(aTHX, xs_init, argc+EXTRA_ARGS, ourarg, env);
  }

  /* Run... */
  int result = (*perl_run)(aTHX);

  /* Cleanup. */
  (*perl_destruct)(aTHX);
  (*perl_free)(aTHX);

  if (ourarg) free(ourarg);
  if (ourenv) free(ourenv);

  return result;
}

void xs_init(pTHX) {
    static const char file[] = __FILE__;
    // dXSUB_SYS;			/* dNOOP */
    // PERL_UNUSED_CONTEXT;

    /* This is probably a terrible abuse of xs_init, but it seems
       to be the only place where @INC can be set.
       Before perl_parse is too early (@INC doesn't exist yet),
       after perl_parse is too late. */

    char *cmd = (char*)calloc( 4+strlen(selfpath), sizeof(char) );
    strcpy( cmd, selfpath );
    strcat( cmd, "lib" );

    /* One-shot calls. */
    void Perl_av_clear(pTHX, AV* gv) {
      static void (*imp)(pTHX, AV* gv);
      imp = (void(*)(pTHX, AV* gv)) dlsym( handle, "Perl_av_clear" );
      (*imp)(aTHX, gv);
    }
    void Perl_av_push(pTHX, AV* gv, SV* sv) {
      static void (*imp)(pTHX, AV* gv, SV* sv);
      imp = (void(*)(pTHX, AV* gv, SV* sv)) dlsym( handle, "Perl_av_push" );
      (*imp)(aTHX, gv, sv);
    }
    GV* Perl_gv_add_by_type(pTHX, GV* gv, int flags) {
      static GV* (*imp)(pTHX, GV* gv, int);
      imp = (GV*(*)(pTHX, GV* gv, int)) dlsym( handle, "Perl_gv_add_by_type" );
      return (*imp)(aTHX, gv, flags);
    }
    SV* Perl_newSVpvn(pTHX, char* sv, STRLEN len) {
      static SV* (*imp)(pTHX, char* sv, STRLEN len);
      imp = (SV*(*)(pTHX, char* sv, STRLEN len)) dlsym( handle, "Perl_newSVpv" );
      return (*imp)(aTHX, sv, len);
    }
    av_clear(GvAVn(PL_incgv));
    av_push(GvAVn(PL_incgv), newSVpvn(cmd, strlen(cmd)));
    free(cmd);

    /* And now for the intended purpose of xs_init... */
    
    /* boot_DynaLoader */
    static void (*boot_DynaLoader_dyn)(pTHX, CV* cv);
    boot_DynaLoader_dyn = (void (*)(pTHX, CV* cv)) dlsym(handle, "boot_DynaLoader");
    if ( !boot_DynaLoader_dyn ) {
      fprintf( stderr, "(boot_DynaLoader) %s\n", dlerror() );
      exit(EXIT_FAILURE);
    }

    /* newXS is just Perl_newXS(aTHX, ...) */
    CV* Perl_newXS(pTHX, const char* c, XSUBADDR_t x, const char* s) {
      static CV* (*imp)(pTHX, const char*, XSUBADDR_t, const char*);
      imp = (CV*(*)(pTHX, const char*, XSUBADDR_t, const char*)) dlsym( handle, "Perl_newXS" );
      return (*imp)(aTHX, c, x, s);
    }
 
    /* Note the following comment is mandatory. */
    /* DynaLoader is a special case */
    newXS( "DynaLoader::boot_DynaLoader", *boot_DynaLoader_dyn, file );
}
