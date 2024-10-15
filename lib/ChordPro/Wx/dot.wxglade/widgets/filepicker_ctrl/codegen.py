"""\
Code generator functions for wxFilePickerCtrl objects
"""

import common, compat
import wcodegen

class PythonFilePickerCtrlGenerator(wcodegen.PythonWidgetCodeWriter):
    tmpl = '%(name)s = %(klass)s(%(parent)s, %(id)s' \
        ', %(path)s, %(message)s, %(wildcard)s' \
        '%(style)s)\n'

    import_modules = ['import wx\n']

    def _prepare_tmpl_content(self, obj):
        wcodegen.PythonWidgetCodeWriter._prepare_tmpl_content(self, obj)
        self.has_setdefault = int(obj.properties.get('default', 0))
        self.tmpl_dict['path'] = self.codegen.quote_str(obj.path)
        self.tmpl_dict['wildcard'] = self.codegen.quote_str(obj.wildcard)
        self.tmpl_dict['message'] = self.codegen.quote_str(obj.message)
        return



class CppFilePickerCtrlGenerator(wcodegen.CppWidgetCodeWriter):
    import_modules = ['<wx/dirctrl.h>']
    tmpl = '%(name)s = new %(klass)s(%(parent)s, %(id)s' \
           ', %(path)s, %(message)s, %(wildcard)s' \
           '%(style)s);\n'

    prefix_style = False
    set_default_style = True

    def _prepare_tmpl_content(self, obj):
        wcodegen.CppWidgetCodeWriter._prepare_tmpl_content(self, obj)
        self.has_setdefault = int(obj.properties.get('default', 0))
        self.tmpl_dict['path'] = self.codegen.quote_str(obj.path)
        self.tmpl_dict['wildcard'] = self.codegen.quote_str(obj.wildcard)
        self.tmpl_dict['message'] = self.codegen.quote_str(obj.message)
        return



def xrc_code_generator(obj):
    xrcgen = common.code_writers['XRC']

    class FilePickerCtrlXrcObject(xrcgen.DefaultXrcObject):
            xrcgen.DefaultXrcObject.write_property(self, name, val, output, tabs)

    return FilePickerCtrlXrcObject(obj)


def initialize():
    klass = 'wxFilePickerCtrl'
    common.class_names['EditFilePickerCtrl'] = klass
    common.register('python', klass, PythonFilePickerCtrlGenerator(klass))
    common.register('C++',    klass, CppFilePickerCtrlGenerator(klass))
#    common.register('XRC',    klass, xrc_code_generator)
