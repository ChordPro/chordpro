#include <time.h>
#include "wx/wx.h"
#include "wx/wxprec.h"

class DnDHandler : public wxApp {

public:
    virtual bool OnInit();
    virtual void MacOpenFiles(const wxArrayString &fileNames);
    virtual void MacNewFile();
};

DECLARE_APP(DnDHandler)
IMPLEMENT_APP(DnDHandler)

wxFrame *frame;
const char *argfile;

#ifdef DEBUG
FILE *f;
#endif

static char selfpath[PATH_MAX];	/* /foo/bar */

int _main( int argc, char **argv  ) {

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

  /* Insert script name in argv. */
  char scriptpath[PATH_MAX];	/* /foo/bar/SCRIPTPREFIXblech.pl */
  strcpy( scriptpath, selfpath );
  strcat( scriptpath, "wxchordpro" );
#ifdef DEBUG
  fprintf( stderr, "scriptpath: %s\n", scriptpath );
#endif

  static char **ourarg = NULL;
  ourarg = (char **)calloc( argc+2, sizeof(char**) );
  /* Set argv0 to scriptpath for FindBin and friends. */
  ourarg[0] = scriptpath;
  /* Copy rest of the arguments. */
  for ( int i=1; i<argc; ++i ) {
    ourarg[i] = argv[i];
  }
  if ( argfile ) {
    ourarg[argc] = (char*) argfile;
    argc++;
  }
#ifdef DEBUG
  fprintf( f, "+ %s\n", scriptpath );
  fprintf( f, "& %s\n", argfile );
  for ( int i=0; i<argc; ++i ) {
    fprintf( f, "++ %s\n", ourarg[i] );
  }
  fclose(f);
#endif
  return execv( scriptpath, ourarg );
}

bool DnDHandler::OnInit() {

#ifdef DEBUG
  f = fopen( "/Users/jv/tmp/xx.log", "a" );
  time_t t;
  time(&t);
  fprintf( f, "%s", ctime(&t) );
  fprintf( f, "& %s\n", argfile );
#endif

#if 0

  frame = new wxFrame( (wxFrame*) NULL, -1,
		       "Hello wxWidgets World" );
  frame->CreateStatusBar();
  frame->SetStatusText( "Hello World" );
  frame->Show(true);
  SetTopWindow(frame);

#endif

  return true;
}

void DnDHandler::MacOpenFiles(const wxArrayString &fileNames) {
  if ( fileNames.GetCount() > 0 ) {
    argfile = fileNames.Item(0).c_str();
  }
  _main( wxGetApp().argc, wxGetApp().argv );
}

void DnDHandler::MacNewFile() {
  _main( wxGetApp().argc, wxGetApp().argv );
}

