"""\
wxFilePickerCtrl objects
"""

import wx
from edit_windows import ManagedBase, EditStylesMixin
import common, compat, config
import decorators
import new_properties as np

from wx import FilePickerCtrl

class EditFilePickerCtrl(ManagedBase, EditStylesMixin):
    "Class to handle wxFilePickerCtrl objects"
    # XXX unify with EditCalendarCtrl?

    WX_CLASS = "wxFilePickerCtrl"
    _PROPERTIES = ["Widget", "path", "wildcard", "message", "style"]
    PROPERTIES = ManagedBase.PROPERTIES + _PROPERTIES + ManagedBase.EXTRA_PROPERTIES
    _PROPERTY_HELP = {
        "path": 'Initial path.',
        "wildcard": 'Patterns for file selection.',
        "message": 'Descriptive text shown in the dialog.'
    }
    recreate_on_style_change = True

    def __init__(self, name, parent, index):
        # Initialise parent classes
        ManagedBase.__init__(self, name, parent, index)
        EditStylesMixin.__init__(self)

        # initialize instance properties
        self.path = np.TextProperty("")
        self.wildcard = np.TextProperty("Text files (*.txt)|*.txt|All files|*.*")
        self.message = np.TextProperty("Select file")

    def create_widget(self):
        self.widget = FilePickerCtrl(self.parent_window.widget, wx.ID_ANY,
                                     self.path, self.message, self.wildcard,
                                     style=self.style)

    def _properties_changed(self, modified, actions):
        if self.widget:
            if "path" in modified:
                self.widget.SetPath(self.path)
            if "wildcard" in modified or "message" in modified:
                # Cannot change properties, recreate.
                self.recreate_widget2()

        EditStylesMixin._properties_changed(self, modified, actions)
        ManagedBase._properties_changed(self, modified, actions)


def builder(parent, index):
    "factory function for EditFilePickerCtrl objects"
    name = parent.toplevel_parent.get_next_contained_name('filepicker_ctrl_%d')
    with parent.frozen():
        editor = EditFilePickerCtrl(name, parent, index)
        editor.properties["style"].set_to_default()
        editor.check_defaults()
        if parent.widget: editor.create()
    return editor


def xml_builder(parser, base, name, parent, index):
    "factory to build EditFilePickerCtrl objects from a XML file"
    return EditFilePickerCtrl(name, parent, index)


def initialize():
    "initialization function for the module: returns a wxBitmapButton to be added to the main palette"
    common.widget_classes['EditFilePickerCtrl'] = EditFilePickerCtrl
    common.widgets['EditFilePickerCtrl'] = builder
    common.widgets_from_xml['EditFilePickerCtrl'] = xml_builder

    return common.make_object_button('EditFilePickerCtrl', 'filepicker_ctrl.png')
