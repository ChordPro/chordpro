/* Drag'n'Drop and Finder command handling.
 *
 * This small Wx program intercepts the initial Finder calls and
 * then execs the real program.
 */

#include "wx/wx.h"
#include "wx/wxprec.h"
#include "wx/event.h"

#ifdef DEBUG

#include <time.h>
FILE *dbgf;

void openlog() {
  if ( !dbgf ) {
    dbgf = fopen( DEBUG, "a" );
    time_t t;
    time(&t);
    fprintf( dbgf, "%s", ctime(&t) );
  }
}

#endif

class DnDHandler : public wxApp {

public:
  // The usual...
  virtual bool OnInit();

  // We're going to override these to catch Finder calls.
  virtual void MacPrintFile(const wxString &fileName);
  virtual void MacOpenFiles(const wxArrayString &fileNames);
  virtual void MacNewFile();
  virtual void MacReopenApp();

  // Our Idle handler.
  // As soon as the app becomes idle, we are done and we'll
  // exec the real program.
  void DoIdle(wxIdleEvent &event);

  DECLARE_EVENT_TABLE()
};

// Standard Wx stuff.
DECLARE_APP(DnDHandler)

BEGIN_EVENT_TABLE( DnDHandler, wxApp )
  EVT_IDLE( DnDHandler::DoIdle )
END_EVENT_TABLE()

IMPLEMENT_APP(DnDHandler)

/* Alternatively:
int main( int argc, char **argv ) {
  // MyWxApp derives from wxApp
  wxApp::SetInstance( new DnDHandler() );
  wxEntryStart( argc, argv );
  wxTheApp->CallOnInit();
  fprintf( dbgf, "OnRun...\n" );
  wxTheApp->OnRun();
  fprintf( dbgf, "OnExit...\n" );
  wxTheApp->OnExit();
  fprintf( dbgf, "Cleanup...\n" );
  wxEntryCleanup();
}
*/

// Register Finder calls.
const char *calltype = "Normal";
char argfile[PATH_MAX] = "";

// Chain handler.
int chain( int argc, char **argv );

// Wx init function. Must return 'true'.
bool DnDHandler::OnInit() {

#ifdef DEBUG
  openlog();
  fprintf( dbgf, "OnInit entry\n" );
#endif

#if 0

  // A frame to show...
  wxFrame* frame = new wxFrame( (wxFrame*) NULL, -1,
				"Drag'n'Drop Handler" );
  frame->Show(true);
  SetTopWindow(frame);

#endif

#ifdef DEBUG
  fprintf( dbgf, "OnInit return\n" );
#endif

  return true;
}

// Handlers for Finder calls.
void DnDHandler::MacPrintFile(const wxString &fileName) {
  calltype = "Print";
  strcpy( argfile, fileName.c_str() );
#ifdef DEBUG
  openlog();
  fprintf( dbgf, "MacPrintFile called (%s)\n", argfile );
#endif
}

void DnDHandler::MacOpenFiles(const wxArrayString &fileNames) {
#ifdef DEBUG
  openlog();
  fprintf( dbgf, "MacOpenFiles called, %lu args\n", fileNames.GetCount() );
#endif
  if ( fileNames.GetCount() > 0 ) {
    strcpy( argfile, fileNames.Item(0).c_str() );
  }
  calltype = "Open";
}

void DnDHandler::MacNewFile() {
#ifdef DEBUG
  openlog();
  fprintf( dbgf, "MacNewFile called\n" );
#endif
  // Always called. Ignore.
}

void DnDHandler::MacReopenApp() {
#ifdef DEBUG
  openlog();
  fprintf( dbgf, "MacReopenApp called\n" );
#endif
  // Ignore.
}

// Event(ually).
void DnDHandler::DoIdle( wxIdleEvent& evt ) {

#ifdef DEBUG
  openlog();
  fprintf( dbgf, "DoIdle called\n" );
#endif

  // The app is set up. Pass control to the chain routine.
  chain( wxTheApp->argc, wxTheApp->argv );
  // We'll not supposed to get here.
}

/**************** Chain Handler ****************/

static char selfpath[PATH_MAX];	/* /foo/bar */

int chain( int argc, char **argv ) {

#ifdef DEBUG
  fprintf( dbgf, "entry: %s (%s)\n", calltype, argfile );
#endif

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
    fprintf( dbgf, "selfpath:   %s\n", selfpath );
    fprintf( dbgf, "scriptname: %s\n", scriptname );
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
    fprintf( dbgf, "cwdpath:    %s\n", selfpath );
    fprintf( dbgf, "scriptname: %s\n", scriptname );
#endif
  }

  /* Insert script name in argv. */
  char scriptpath[PATH_MAX];	/* /foo/bar/SCRIPTPREFIXblech.pl */
  strcpy( scriptpath, selfpath );
  strcat( scriptpath, "wxchordpro" );
#ifdef DEBUG
  fprintf( dbgf, "scriptpath: %s\n", scriptpath );
#endif

  static char **ourarg = NULL;
  ourarg = (char **)calloc( argc+2, sizeof(char**) );
  /* Set argv0 to scriptpath for FindBin and friends. */
  ourarg[0] = scriptpath;
  /* Copy rest of the arguments. */
  for ( int i=1; i<argc; ++i ) {
    ourarg[i] = argv[i];
  }
  if ( argfile[0] ) {
    ourarg[argc] = (char*) argfile;
    argc++;
  }

#ifdef DEBUG
  fprintf( dbgf, "+ %s\n", scriptpath );
  for ( int i=0; i<argc; ++i ) {
    fprintf( dbgf, "++ %s\n", ourarg[i] );
  }
  fclose(dbgf);
#endif

  // Here we go...
  return execv( scriptpath, ourarg );
}
