/* Portable Perl Loader (Linux version) */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <EXTERN.h>
#include <perl.h>
#include "XSUB.h"

static pTHX;

/* Set up DynaLoader so modules can load modules. */

void xs_init(pTHX);

/* Main. */

int main( int argc, char **argv, char **env ) {

  /* Assuming the program binary   /foo/bar/blech */
  char selfpath[PATH_MAX];	/* /foo/bar */
  char scriptname[PATH_MAX];	/* blech */
  memset (selfpath,   0, PATH_MAX);
  memset (scriptname, 0, PATH_MAX);

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

  /* Start perl environment. */
  PERL_SYS_INIT3( &argc, &argv, &env );

  /* Create a perl interpreter. */
  my_perl = perl_alloc();
  perl_construct(my_perl);

  /* If we're "perl", behave like perl. */
  if ( !strncmp( scriptname, "perl", 4 ) )
    perl_parse( my_perl, xs_init, argc, argv, env );

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

  /* Run.... */
  int result = perl_run(my_perl);

  /* Cleanup. */
  perl_destruct(my_perl);
  perl_free(my_perl);

  /* Terminate perl environment. */
  PERL_SYS_TERM();

  exit(result);
}

void boot_DynaLoader (pTHX, CV* cv);

void xs_init(pTHX) {
    static const char file[] = __FILE__;
    dXSUB_SYS;
    PERL_UNUSED_CONTEXT;
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

