module RedmineDescriptionMacros
  # The settings form stores a ticked box as "1" and leaves an unticked one out; the defaults are
  # true. Anything else ("0", "false", false, "" set by a script) is off.
  def self.setting_enabled?(name)
    value = Setting.plugin_redmine_description_macros[name]
    value == true || value.to_s == '1'
  end
end
