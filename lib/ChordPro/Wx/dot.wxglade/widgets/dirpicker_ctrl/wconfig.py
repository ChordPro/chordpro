"""\
wxDirPickerCtrl widget configuration
"""

config = {
    'wxklass': 'wxDirPickerCtrl',
    'style_defs': {
        'wxDIRP_DEFAULT_STYLE': {
            'desc': _('The default style: includes wxDIRP_DIR_MUST_EXIST and, under wxMSW only, wxDIRP_USE_TEXTCTRL. '),
        },
        'wxDIRP_USE_TEXTCTRL': {
            'desc': _('Creates a text control to the left of the picker button which is completely managed by the wx.DirPickerCtrl and which can be used by the user to specify a path (see SetPath). The text control is automatically synchronized with button’s value. Use functions defined in wx.PickerBase to modify the text control.'),
        },
        'wxDIRP_DIR_MUST_EXIST': {
            'desc': _('Creates a picker which allows selecting only existing directories in the popup wx.DirDialog. Notice that, as with FLP_FILE_MUST_EXIST , it is still possible to enter a non-existent directory even when this file is specified if DIRP_USE_TEXTCTRL style is also used. Also note that if DIRP_USE_TEXTCTRL is not used, the native wxGTK implementation always uses this style as it doesn’t support selecting non-existent directories.'),
        },
        'wxDIRP_CHANGE_DIR': {
            'desc': _('Change current working directory on each user directory selection change.'),
        },
        'wxDIRP_SMALL': {
            'desc': _('Use smaller version of the control with a small “…” button instead of the normal “Browse” one.'),
        },
    },
    'default_style': 'wxDIRP_DEFAULT_STYLE',
    'style_list': ['wxDIRP_USE_TEXTCTRL', 'wxDIRP_DIR_MUST_EXIST', 'wxDIRP_CHANGE_DIR', 'wxDIRP_SMALL'],
    'events': {
        'EVT_DIRPICKER_CHANGED': {'type': 'wxFileDirPickerEvent',},
    },
}





