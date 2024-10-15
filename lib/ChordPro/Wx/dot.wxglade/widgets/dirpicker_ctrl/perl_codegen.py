"""\
Code generator functions for wxDirPickerCtrl objects

@license: MIT (see LICENSE.txt) - THIS PROGRAM COMES WITH NO WARRANTY
"""

import common
import wcodegen


class PerlDirPickerCtrlGenerator(wcodegen.PerlWidgetCodeWriter):
    tmpl = '%(name)s = %(klass)s->new(%(parent)s, %(id)s, ' \
           '%(path)s, %(message)s%(style)s);\n'
#    prefix_style = False
#    set_default_style = True

    def _prepare_tmpl_content(self, obj):
        wcodegen.PerlWidgetCodeWriter._prepare_tmpl_content(self, obj)
        self.has_setdefault = int(obj.properties.get('default', 0))
        self.tmpl_dict['path'] = self.codegen.quote_str(obj.path)
        self.tmpl_dict['message'] = self.codegen.quote_str(obj.message)
        return


def initialize():
    klass = 'wxDirPickerCtrl'
    common.class_names['EditDirPickerCtrl'] = klass
    common.register('perl', klass, PerlDirPickerCtrlGenerator(klass))
