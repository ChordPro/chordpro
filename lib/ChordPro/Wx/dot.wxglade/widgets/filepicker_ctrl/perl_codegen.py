"""\
Code generator functions for wxFilePickerCtrl objects
"""

import common
import wcodegen


class PerlFilePickerCtrlGenerator(wcodegen.PerlWidgetCodeWriter):
    tmpl = '%(name)s = %(klass)s->new(%(parent)s, %(id)s, ' \
           '%(path)s, %(message)s, %(wildcard)s' \
           '%(style)s);\n'
    set_default_style = True

    def _prepare_tmpl_content(self, obj):
        wcodegen.PerlWidgetCodeWriter._prepare_tmpl_content(self, obj)
        self.has_setdefault = int(obj.properties.get('default', 0))
        self.tmpl_dict['path'] = self.codegen.quote_str(obj.path)
        self.tmpl_dict['wildcard'] = self.codegen.quote_str(obj.wildcard)
        self.tmpl_dict['message'] = self.codegen.quote_str(obj.message)
        return


def initialize():
    klass = 'wxFilePickerCtrl'
    common.class_names['EditFilePickerCtrl'] = klass
    common.register('perl', klass, PerlFilePickerCtrlGenerator(klass))
