"""\
wxDirPickerCtrl objects
"""

import wx
from edit_windows import ManagedBase, EditStylesMixin
import common, compat, config
import decorators
import new_properties as np

from wx import DirPickerCtrl

class EditDirPickerCtrl(ManagedBase, EditStylesMixin):
    "Class to handle wxDirPickerCtrl objects"

    WX_CLASS = "wxDirPickerCtrl"
    _PROPERTIES = ["Widget", "path", "message", "style"]
    PROPERTIES = ManagedBase.PROPERTIES + _PROPERTIES + ManagedBase.EXTRA_PROPERTIES
    _PROPERTY_HELP = {
        "path": 'Initial path.',
        "message": 'Descriptive text shown in the dialog.'
    }
    recreate_on_style_change = True

    def __init__(self, name, parent, index):
        # Initialise parent classes
        ManagedBase.__init__(self, name, parent, index)
        EditStylesMixin.__init__(self)

        # initialize instance properties
        self.path = np.TextProperty("")
        self.message = np.TextProperty("Select folder")

    def create_widget(self):
        if compat.IS_GTK: wx.Yield()  # avoid problems where the widget is consuming all events
        self.widget = DirPickerCtrl(self.parent_window.widget, wx.ID_ANY,
                                    path = self.path, message = self.message,
                                    style=self.style)

    def _properties_changed(self, modified, actions):
        if self.widget:
            if "path" in modified or "message" in modified:
                # Cannot change properties, recreate.
                self.recreate_widget2()

        EditStylesMixin._properties_changed(self, modified, actions)
        ManagedBase._properties_changed(self, modified, actions)


def builder(parent, index):
    "factory function for EditDirPickerCtrl objects"
    name = parent.toplevel_parent.get_next_contained_name('dirpicker_ctrl_%d')
    with parent.frozen():
        editor = EditDirPickerCtrl(name, parent, index)
        editor.properties["style"].set_to_default()
        editor.check_defaults()
        if parent.widget: editor.create()
    return editor


def xml_builder(parser, base, name, parent, index):
    "factory to build EditDirPickerCtrl objects from a XML file"
    return EditDirPickerCtrl(name, parent, index)


def initialize():
    "initialization function for the module: returns a wxBitmapButton to be added to the main palette"
    common.widget_classes['EditDirPickerCtrl'] = EditDirPickerCtrl
    common.widgets['EditDirPickerCtrl'] = builder
    common.widgets_from_xml['EditDirPickerCtrl'] = xml_builder

    return common.make_object_button('EditDirPickerCtrl', 'dirpicker_ctrl.png')
