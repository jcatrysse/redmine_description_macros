Redmine::Plugin.register :redmine_description_macros do
  name 'Redmine Description Macros'
  author 'Robin Bailleul and Jan Catrysse'
  description 'Add macros for related issues'
  version '0.0.1'
  url 'https://github.com/jcatrysse/redmine_description_macros'
  author_url 'https://github.com/jcatrysse'

  requires_redmine version_or_higher: '4.0'

  settings default: {
    'enable_child_description_macro' => true,
    'enable_child_issue_macro' => true,
    'enable_parent_description_macro' => true,
    'enable_parent_issue_macro' => true,
    'enable_sibling_description_macro' => true,
    'enable_sibling_issue_macro' => true,
    'enable_macro_debug_messages' => false
  }, partial: 'settings/redmine_description_macros_settings'
end

require File.dirname(__FILE__) + '/lib/redmine_description_macros'
require File.dirname(__FILE__) + '/lib/redmine_description_macros/macros'
