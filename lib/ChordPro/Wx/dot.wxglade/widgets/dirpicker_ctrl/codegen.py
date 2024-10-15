"""\
Code generator functions for wxDirPickerCtrl objects

@license: MIT (see LICENSE.txt) - THIS PROGRAM COMES WITH NO WARRANTY
"""

import common, compat
import wcodegen

class PythonDirPickerCtrlGenerator(wcodegen.PythonWidgetCodeWriter):
    tmpl = '%(name)s = %(klass)s(%(parent)s, %(id)s' \
        ', %(path)s, %(message)s' \
        '%(style)s)\n'

    import_modules = ['import wx\n']

    def _prepare_tmpl_content(self, obj):
        wcodegen.PythonWidgetCodeWriter._prepare_tmpl_content(self, obj)
        self.has_setdefault = int(obj.properties.get('default', 0))
        self.tmpl_dict['path'] = self.codegen.quote_str(obj.path)
        self.tmpl_dict['message'] = self.codegen.quote_str(obj.message)
        return


class CppDirPickerCtrlGenerator(wcodegen.CppWidgetCodeWriter):
    import_modules = ['<wx/dirctrl.h>']
    tmpl = '%(name)s = new %(klass)s(%(parent)s, %(id)s, ' \
        ', %(path)s, %(message)s' \
        '%(style)s);\n'

#    prefix_style = False
#    set_default_style = True

    def _prepare_tmpl_content(self, obj):
        wcodegen.CppWidgetCodeWriter._prepare_tmpl_content(self, obj)
        self.has_setdefault = int(obj.properties.get('default', 0))
        self.tmpl_dict['path'] = self.codegen.quote_str(obj.path)
        self.tmpl_dict['message'] = self.codegen.quote_str(obj.message)
        return



def xrc_code_generator(obj):
    xrcgen = common.code_writers['XRC']

    class DirPickerCtrlXrcObject(xrcgen.DefaultXrcObject):
        def write_property(self, name, val, output, tabs):
            xrcgen.DefaultXrcObject.write_property(self, name, val, output, tabs)

    return DirPickerCtrlXrcObject(obj)


def initialize():
    klass = 'wxDirPickerCtrl'
    common.class_names['EditDirPickerCtrl'] = klass
    common.register('python', klass, PythonDirPickerCtrlGenerator(klass))
    common.register('C++',    klass, CppDirPickerCtrlGenerator(klass))
#    common.register('XRC',    klass, xrc_code_generator)
