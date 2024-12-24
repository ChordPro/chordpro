"""\
wxFilePickerCtrl widget configuration
"""

config = {
    'wxklass': 'wxFilePickerCtrl',
    'style_defs': {
        'wxFLP_DEFAULT_STYLE': {
            'desc': _('The default style: includes wxFLP_OPEN | wxFLP_FILE_MUST_EXIST and, under wxMSW and wxOSX, wxFLP_USE_TEXTCTRL.'),
        },
        'wxFLP_USE_TEXTCTRL': {
            'desc': _('Creates a text control to the left of the picker button which is completely managed by the wx.FilePickerCtrl and which can be used by the user to specify a path (see SetPath). The text control is automatically synchronized with button’s value. Use functions defined in wx.PickerBase to modify the text control.'),
        },
        'wxFLP_OPEN': {
            'desc': _('Creates a picker which allows the user to select a file to open.'),
        },
        'wxFLP_SAVE': {
            'desc': _('Creates a picker which allows the user to select a file to save.'),
        },
        'wxFLP_OVERWRITE_PROMPT': {
            'desc': _('n be combined with wxFLP_SAVE only: ask confirmation to the user before selecting a file.'),
        },
        'wxFLP_FILE_MUST_EXIST': {
            'desc': _('Can be combined with wxFLP_OPEN only: the file selected in the popup wxFileDialog must be an existing file. Notice that it still remains possible for the user to enter a non-existent file name in the text control if wxFLP_USE_TEXTCTRL is also used, this flag is a hint for the user rather than a guarantee that the selected file does exist for the program.'),
        },
        'wxFLP_CHANGE_DIR': {
            'desc': _('Change current working directory on each user directory selection change.'),
        },
        'wxFLP_SMALL': {
            'desc': _('Use smaller version of the control with a small “…” button instead of the normal “Browse” one.'),
        },
    },
    'default_style': 'wxFLP_DEFAULT_STYLE',
    'style_list': ['wxFLP_USE_TEXTCTRL', 'wxFLP_OPEN', 'wxFLP_SAVE', 'wxFLP_FILE_MUST_EXIST', 'wxFLP_CHANGE_DIR', 'wxFLP_SMALL'],
    'events': {
        'EVT_FILEPICKER_CHANGED': {'type': 'wxFileFilePickerEvent',},
    },
}





