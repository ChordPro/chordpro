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

static char selfpath[PATH_MAX];	/* /foo/bar */

int main( int argc, char **argv, char **env ) {

  // Make ourselves known.
  putenv( "PPL_PACKAGED=1.00" );

  /* Assuming the program binary   /foo/bar/blech */
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
#ifdef DEBUG
    fprintf( stderr, "scriptpath: %s\n", scriptpath );
#endif

#   define EXTRA_ARGS 1
    ourarg = (char **)calloc( argc+1+EXTRA_ARGS, sizeof(char**) );
    /* Set argv0 to scriptpath for FindBin and friends. */
    ourarg[0] = scriptpath;
    /* Insert scriptpath for perl to execute. */
    ourarg[1] = scriptpath;
    /* Copy rest of the arguments. */
    for ( int i=1; i<=argc; ++i ) {
      ourarg[i+EXTRA_ARGS] = argv[i];
    }
    (*perl_parse)(aTHX, xs_init, argc+EXTRA_ARGS, ourarg, env);
  }

  /* Run.... */
  int result = perl_run(my_perl);

  /* Cleanup. */
  perl_destruct(my_perl);
  perl_free(my_perl);

  /* Terminate perl environment. */
  PERL_SYS_TERM();

  if (ourarg) free(ourarg);
  if (ourenv) free(ourenv);

  exit(result);
}

void boot_DynaLoader (pTHX, CV* cv);

void xs_init(pTHX) {
    static const char file[] = __FILE__;
    dXSUB_SYS;
    PERL_UNUSED_CONTEXT;

    /* This is probably a terrible abuse of xs_init, but it seems
       to be the only place where @INC can be set.
       Before perl_parse is too early (@INC doesn't exist yet),
       after perl_parse is too late. */

    char *cmd = (char*)calloc(5+strlen(selfpath),sizeof(char));
    strcpy( cmd, selfpath );
    strcat( cmd, "lib" );
    av_clear(GvAVn(PL_incgv));
    av_push(GvAVn(PL_incgv), newSVpv(cmd, strlen(cmd)));
    free(cmd);

    /* And now for the intended purpose of xs_init... */
    /* Note the following comment is mandatory. */
    /* DynaLoader is a special case */
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

