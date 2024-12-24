"""\
Code generator functions for wxRearrangeCtrl objects

@license: MIT (see LICENSE.txt) - THIS PROGRAM COMES WITH NO WARRANTY
"""

import common, compat
import wcodegen

class PythonRearrangeCtrlGenerator(wcodegen.PythonWidgetCodeWriter):
    tmpl = '%(name)s = %(klass)s(%(parent)s, %(id)s' \
        ', wx.DefaultPosition, wx.DefaultSize' \
        ', %(order)s, %(items)s' \
        '%(style)s)\n'
    prefix_style = False
    set_default_style = True

    import_modules = ['import wx\n']

    def _prepare_tmpl_content(self, obj):
        wcodegen.PythonWidgetCodeWriter._prepare_tmpl_content(self, obj)
        self.has_setdefault = int(obj.properties.get('default', 0))
        items = ("Select and rearrange items",)
        self.tmpl_dict['order'] = len(items) * (-1,)
        self.tmpl_dict['items'] = items
        return


class PerlRearrangeCtrlGenerator(wcodegen.PerlWidgetCodeWriter):
    tmpl = '%(name)s = %(klass)s->new(%(parent)s, %(id)s' \
        ', wxDefaultPosition, wxDefaultSize' \
        ', %(order)s, %(items)s' \
        '%(style)s);\n'
    prefix_style = False
    set_default_style = False

    def _prepare_tmpl_content(self, obj):
        wcodegen.PerlWidgetCodeWriter._prepare_tmpl_content(self, obj)
        self.has_setdefault = int(obj.properties.get('default', 0))
        items = ("Select and rearrange items",)
        self.tmpl_dict['order'] = list(len(items) * (-1,))
        self.tmpl_dict['items'] = list(items)
        return


def initialize():
    klass = 'wxRearrangeCtrl'
    common.class_names['EditRearrangeCtrl'] = klass
    common.register('python', klass, PythonRearrangeCtrlGenerator(klass))
    common.register('perl',   klass, PerlRearrangeCtrlGenerator(klass))
