"""\
Code generator functions for wxFilePickerCtrl objects
"""

import common
import wcodegen


class LispFilePickerCtrlGenerator(wcodegen.LispWidgetCodeWriter):
    tmpl = '(setf %(name)s (%(klass)s_Create %(parent)s %(id)s -1 -1 -1 -1 %(style)s))\n'


def initialize():
    klass = 'wxFilePickerCtrl'
    common.class_names['EditFilePickerCtrl'] = klass
    common.register('lisp', klass, LispFilePickerCtrlGenerator(klass))
