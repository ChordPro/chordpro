"""\
wxRearrangeCtrl objects
"""

import wx
from edit_windows import ManagedBase, EditStylesMixin
import common, compat, config
import decorators
import new_properties as np
from ChoicesProperty import *

from wx import RearrangeCtrl

class EditRearrangeCtrl(ManagedBase, EditStylesMixin):
    "Class to handle wxRearrangeCtrl objects"

    WX_CLASS = "wxRearrangeCtrl"
    _PROPERTIES = ["Widget","items"]
    PROPERTIES = ManagedBase.PROPERTIES + _PROPERTIES + ManagedBase.EXTRA_PROPERTIES
    _PROPERTY_HELP = {
        "items":"Default items in the list."
    }
    recreate_on_style_change = True

    def __init__(self, name, parent, index):
        # Initialise parent classes
        ManagedBase.__init__(self, name, parent, index)
        EditStylesMixin.__init__(self)
        self.style = 0
        self.items = ("one","two","three")

    def create_widget(self):
        if compat.IS_GTK: wx.Yield()  # avoid problems where the widget is consuming all events
        self.widget = RearrangeCtrl(self.parent_window.widget, wx.ID_ANY,
                                    wx.DefaultPosition, wx.DefaultSize,
                                    len(self.items)*(-1,), self.items,
                                    style=self.style)

    def _properties_changed(self, modified, actions):
        if False and "items" in modified and self.widget:
            self.widget.GetList.Set(self.items)
        EditStylesMixin._properties_changed(self, modified, actions)
        ManagedBase._properties_changed(self, modified, actions)


def builder(parent, index):
    "factory function for EditRearrangeCtrl objects"
    name = parent.toplevel_parent.get_next_contained_name('rearrange_ctrl_%d')
    with parent.frozen():
        editor = EditRearrangeCtrl(name, parent, index)
        editor.properties["style"].set_to_default()
        editor.check_defaults()
        if parent.widget: editor.create()
    return editor

def xml_builder(parser, base, name, parent, index):
    "factory to build EditRearrangeCtrl objects from a XML file"
    return EditRearrangeCtrl(name, parent, index)

def initialize():
    "initialization function for the module: returns a wxBitmapButton to be added to the main palette"
    common.widget_classes['EditRearrangeCtrl'] = EditRearrangeCtrl
    common.widgets['EditRearrangeCtrl'] = builder
    common.widgets_from_xml['EditRearrangeCtrl'] = xml_builder

    return common.make_object_button('EditRearrangeCtrl', 'list_box.png')
