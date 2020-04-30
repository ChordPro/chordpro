/* Portable Perl Loader (Linux version) */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <EXTERN.h>
#include <perl.h>
#include "XSUB.h"

static PerlInterpreter *my_perl;

/* Set up DynaLoader so modules cna load modules. */

void boot_DynaLoader (pTHX_ CV* cv);

void xs_init(pTHX) {
    static const char file[] = __FILE__;
    dXSUB_SYS;
    PERL_UNUSED_CONTEXT;
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

/* Main. */

int main( int argc, char **argv, char **env ) {

  char selfpath[PATH_MAX];
  char scriptpath[PATH_MAX];
  char scriptname[PATH_MAX];
  memset (selfpath,   0, PATH_MAX);
  memset (scriptpath, 0, PATH_MAX);
  memset (scriptname, 0, PATH_MAX);

  if ( readlink ("/proc/self/exe", selfpath, PATH_MAX-1 ) > 0 ) {
    char *p = rindex( selfpath, '/' );
    if ( p ) {
      strcpy( scriptname, p+1 );
      *p = 0;
    }
    else
      strcpy( scriptname, selfpath );
  }
  else {
    strncpy( selfpath, argv[0], PATH_MAX-1 );
    char *p = rindex( selfpath, '/' );
    if ( p ) {
      strcpy( scriptname, p+1 );
      *p = 0;
    }
    else {
      p = getcwd( selfpath, PATH_MAX-1 );
      strncpy( scriptname, argv[0], PATH_MAX-1 );
    }
  }

  strcat( selfpath, "/" );
  strcpy( scriptpath, selfpath );
#ifdef SCRIPTPREFIX
  strcat( scriptpath, "script/" );
#endif

  strcat( scriptpath, scriptname );
  strcat( scriptpath, ".pl" );

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
    char **ourargv = (char **)calloc( argc+2, sizeof(char**) );
    ourargv[0] = argv[0];
    ourargv[1] = scriptpath;
    for ( int i=1; i<=argc; ++i ) {
      ourargv[i+1] = argv[i];
    }
    perl_parse( my_perl, xs_init, argc+1, ourargv, env );
    /* Don't bother to free ourargv. */
  }

  /* Set @INC to just our stuff. */
  char cmd[PATH_MAX+100];
  sprintf( cmd, "@INC = (q{%slib});", selfpath );
  eval_pv( cmd, TRUE );
  
  /* Run.... */
  int result = perl_run(my_perl);

  /* Cleanup. */
  perl_destruct(my_perl);
  perl_free(my_perl);

  /* Terminate perl environment. */
  PERL_SYS_TERM();

  exit(result);
}

