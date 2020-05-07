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

int main( int argc, char **argv, char **env ) {

  /* Assuming the program binary   /foo/bar/blech */
  char selfpath[PATH_MAX];	/* /foo/bar */
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

  /* Start perl environment. */
  //PERL_SYS_INIT3( &argc, &argv, &env );
  void (*Perl_sys_init3)( int*, char***, char*** );
  Perl_sys_init3 = (void(*)(int*, char***, char***)) dlsym(handle, "Perl_sys_init3");
  (*Perl_sys_init3)(&argc, &argv, &env);

  /* Create a perl interpreter. */
  tTHX (*perl_alloc)();
  perl_alloc = (tTHX(*)()) dlsym(handle, "perl_alloc");
  my_perl = (*perl_alloc)();

  /* perl_construct */
  void (*perl_construct)(pTHX);
  perl_construct = (void(*)(pTHX)) dlsym(handle, "perl_construct");
  (*perl_construct)(aTHX);

  /* perl_parse */
  void (*perl_parse)(pTHX, void*, int, char**, char**);
  perl_parse = (void(*)(pTHX, void*, int, char**, char**)) dlsym(handle, "perl_parse");

  /* If we're "perl", behave like perl. */
  if ( !strncmp( scriptname, "perl", 4 ) )
    (*perl_parse)( aTHX, xs_init, argc, argv, env );

  else {

    /* Insert script name in argv. */
    char scriptpath[PATH_MAX];	/* /foo/bar/SCRIPTPREFIXblech.pl */
    strcpy( scriptpath, selfpath );
#ifdef SCRIPTPREFIX
    strcat( scriptpath, "script/" );
#endif
    strcat( scriptpath, scriptname );
    strcat( scriptpath, ".pl" );

    /* To get @INC right we execute it as a -E script. */
    char *cmd = (char*)calloc(25+strlen(selfpath)+strlen(scriptpath),sizeof(char));
    sprintf( cmd, "@INC=(q{%slib});do q{%s};", selfpath, scriptpath );
#ifdef DEBUG
    fprintf( stderr, "scriptpath: %s\n", scriptpath );
    fprintf( stderr, "cmd:        %s\n", cmd );
#endif

#   define EXTRA_ARGS 3    
    char **ourargv = (char **)calloc( argc+1+EXTRA_ARGS, sizeof(char**) );
    ourargv[0] = argv[0];
    ourargv[1] = "-E";
    ourargv[2] = cmd;
    ourargv[3] = "--";
    for ( int i=1; i<=argc; ++i ) {
      ourargv[i+EXTRA_ARGS] = argv[i];
    }
    (*perl_parse)(aTHX, xs_init, argc+EXTRA_ARGS, ourargv, env);
  }

  /* Set @INC to just our stuff. But it's too late. */
  //  char cmd[PATH_MAX+100];
  //  sprintf( cmd, "@INC = (q{%slib});", selfpath );
  //  SV* (*eval_pv)(pTHX, const char*, I32);
  //  eval_pv = (SV* (*)(pTHX, const char*, I32)) dlsym( handle, "Perl_eval_pv" );
  //  (*eval_pv)( aTHX, cmd, TRUE );

  /* Run... */
  int (*perl_run)(pTHX);
  perl_run = (int(*)(pTHX)) dlsym(handle, "perl_run");
  int result = (*perl_run)(aTHX);

  /* Cleanup. */
  void(*perl_destruct)(pTHX);
  perl_destruct = (void(*)(pTHX)) dlsym(handle, "perl_destruct");
  (*perl_destruct)(aTHX);
  void(*perl_free)(pTHX);
  perl_free = (void(*)(pTHX)) dlsym(handle, "perl_free");
  (*perl_free)(aTHX);

  return result;
}

void (*boot_DynaLoader_dyn)(pTHX, CV* cv);
CV* (*Perl_newXS_dyn)(pTHX, const char*, XSUBADDR_t, const char*);

void xs_init(pTHX) {
    static const char file[] = __FILE__;
    // dXSUB_SYS;			/* dNOOP */
    // PERL_UNUSED_CONTEXT;

    /* boot_DynaLoader */
    boot_DynaLoader_dyn = (void (*)(pTHX, CV* cv)) dlsym(handle, "boot_DynaLoader");
    if ( !boot_DynaLoader_dyn ) {
      fprintf( stderr, "(boot_DynaLoader) %s\n", dlerror() );
      exit(EXIT_FAILURE);
    }

    /* newXS is just Perl_newXS(aTHX, ...) */
    Perl_newXS_dyn = (CV* (*)(pTHX, const char*, XSUBADDR_t, const char*)) dlsym( handle, "Perl_newXS" );
 
    /* The following comment is mandatory. */
    /* DynaLoader is a special case */
    (*Perl_newXS_dyn)( aTHX, "DynaLoader::boot_DynaLoader", *boot_DynaLoader_dyn, file );
}
