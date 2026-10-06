require_relative '../test_helper'

class MacrosTest < Redmine::HelperTest
  include ApplicationHelper
  include ERB::Util

  DEFAULTS = {
    'enable_child_description_macro' => true,
    'enable_child_issue_macro' => true,
    'enable_parent_description_macro' => true,
    'enable_parent_issue_macro' => true,
    'enable_sibling_description_macro' => true,
    'enable_sibling_issue_macro' => true,
    'enable_macro_debug_messages' => true
  }.freeze

  def setup
    super
    @saved_settings = Setting.plugin_redmine_description_macros
    Setting.plugin_redmine_description_macros = DEFAULTS.dup
    Thread.current[:issue_obj_stack] = nil
    @project = Project.find(1)
    User.current = User.find(2)
    @parent = create_issue('Parent subject', 'Parent *bold* text', tracker: 1)
    @feature = create_issue('Feature child', 'feature body', tracker: 2, parent: @parent)
    @bug = create_issue('Bug child', 'bug body', tracker: 1, parent: @parent)
    @private_child = create_issue('Secret child subject', 'secret body', tracker: 3, parent: @parent, is_private: true,
                                  author: User.find(1))
  end

  def teardown
    Setting.plugin_redmine_description_macros = @saved_settings
    Thread.current[:issue_obj_stack] = nil
    User.current = nil
    super
  end

  def create_issue(subject, description, tracker:, parent: nil, **attrs)
    issue = Issue.new(project: @project, tracker_id: tracker, subject: subject, description: description,
                      author: attrs.delete(:author) || User.find(2), priority: IssuePriority.first)
    issue.parent_issue_id = parent.id if parent
    attrs.each { |k, v| issue.send("#{k}=", v) }
    issue.save!
    issue
  end

  def render_description(issue, text)
    Issue.where(id: issue.id).update_all(description: text)
    textilizable(Issue.find(issue.id), :description)
  end

  def with_formatting(name)
    saved = Setting.text_formatting
    Setting.text_formatting = name
    yield
  ensure
    Setting.text_formatting = saved
  end

  def test_parent_description_renders_parent_description
    out = render_description(@feature, '{{parent_description}}')
    assert_include '<em>bold</em>', out
  end

  def test_parent_description_without_parent
    out = render_description(@parent, '{{parent_description}}')
    assert_include 'no parent found', out
  end

  def test_parent_description_hides_invisible_parent
    Issue.where(id: @parent.id).update_all(is_private: true)
    User.current = User.anonymous
    out = render_description(@feature, '{{parent_description}}')
    assert_include 'parent not visible', out
    assert_not_include 'bold', out
  end

  def test_parent_issue_links_to_parent
    out = render_description(@feature, '{{parent_issue}}')
    assert_select_in out, 'a[href=?]', "/issues/#{@parent.id}"
    assert_include 'Parent subject', out
  end

  def test_parent_issue_options
    out = render_description(@feature, '{{parent_issue(subject=false, tracker=false)}}')
    assert_include "##{@parent.id}", out
    assert_not_include ': Parent subject', out
  end

  def test_parent_issue_hides_invisible_parent
    Issue.where(id: @parent.id).update_all(is_private: true)
    User.current = User.anonymous
    out = render_description(@feature, '{{parent_issue}}')
    assert_not_include 'Parent subject', out
    assert_not_include "/issues/#{@parent.id}", out
    assert_include 'parent not visible', out
  end

  def test_child_description_by_tracker_is_case_insensitive
    out = render_description(@parent, '{{child_description(feature request)}}')
    assert_include 'feature body', out
  end

  def test_child_description_without_match
    out = render_description(@parent, '{{child_description(Support)}}')
    assert_include 'no children found of tracker Support', out
  end

  def test_child_description_skips_invisible_child
    User.current = User.anonymous
    out = render_description(@parent, "{{child_description(#{@private_child.tracker.name})}}")
    assert_not_include 'secret body', out
  end

  def test_child_description_without_argument
    out = render_description(@parent, '{{child_description}}')
    assert_include 'tracker name should be given as argument to macro child_description', out
  end

  def test_child_issue_links_to_child
    out = render_description(@parent, '{{child_issue(Feature request)}}')
    assert_select_in out, 'a[href=?]', "/issues/#{@feature.id}"
  end

  def test_child_issue_options
    out = render_description(@parent, '{{child_issue(Feature request, tracker=false, subject=false)}}')
    assert_include "##{@feature.id}", out
    assert_not_include ': Feature child', out
  end

  def test_child_issue_does_not_leak_invisible_child
    User.current = User.anonymous
    out = render_description(@parent, "{{child_issue(#{@private_child.tracker.name})}}")
    assert_not_include 'Secret child subject', out
    assert_not_include "/issues/#{@private_child.id}", out
  end

  def test_child_issue_link_is_a_link_in_textile
    with_formatting('textile') do
      out = render_description(@parent, '{{child_issue(Feature request)}}')
      assert_select_in out, 'a[href=?]', "/issues/#{@feature.id}"
      assert_not_include '&lt;a', out
    end
  end

  def test_child_issue_link_keeps_css_class
    with_formatting('common_mark') do
      out = render_description(@parent, '{{child_issue(Feature request)}}')
      assert_select_in out, 'a.issue[href=?]', "/issues/#{@feature.id}"
    end
  end

  def test_sibling_description
    out = render_description(@feature, '{{sibling_description(Bug)}}')
    assert_include 'bug body', out
  end

  def test_sibling_description_skips_self
    out = render_description(@feature, '{{sibling_description(Feature request)}}')
    assert_include 'no sibling found of tracker Feature request', out
  end

  def test_sibling_description_skips_invisible_sibling
    User.current = User.anonymous
    out = render_description(@feature, "{{sibling_description(#{@private_child.tracker.name})}}")
    assert_not_include 'secret body', out
  end

  def test_sibling_issue_links_to_sibling
    out = render_description(@feature, '{{sibling_issue(Bug)}}')
    assert_select_in out, 'a[href=?]', "/issues/#{@bug.id}"
  end

  def test_sibling_issue_tracker_is_case_insensitive
    out = render_description(@feature, '{{sibling_issue(bug)}}')
    assert_select_in out, 'a[href=?]', "/issues/#{@bug.id}"
  end

  def test_sibling_issue_does_not_leak_invisible_sibling
    User.current = User.anonymous
    out = render_description(@feature, "{{sibling_issue(#{@private_child.tracker.name})}}")
    assert_not_include 'Secret child subject', out
    assert_not_include "/issues/#{@private_child.id}", out
  end

  def test_sibling_issue_without_argument_names_its_own_macro
    out = render_description(@feature, '{{sibling_issue}}')
    assert_include 'macro sibling_issue', out
  end

  def test_disabled_macro_is_left_alone
    Setting.plugin_redmine_description_macros = DEFAULTS.merge('enable_child_issue_macro' => false)
    out = render_description(@parent, '{{child_issue(Feature request)}}')
    assert_not_include "/issues/#{@feature.id}", out
    assert_include 'child_issue', out
  end

  def test_macro_on_plain_text_without_issue
    out = textilizable('{{parent_description}}')
    assert_include 'object for macro is not initialized', out
  end

  def test_debug_messages_off_hides_messages
    Setting.plugin_redmine_description_macros = DEFAULTS.merge('enable_macro_debug_messages' => false)
    out = textilizable('{{parent_description}}')
    assert_not_include 'not initialized', out
  end

  def test_macro_on_a_non_issue_object
    out = textilizable(Project.find(1), :description, object: Project.find(1))
    assert_kind_of String, out
    out = textilizable('{{parent_description}}', object: Project.find(1))
    assert_include 'macro must be used on an issue or a note', out
  end

  def test_macro_in_a_journal_note_uses_its_issue
    journal = Journal.create!(journalized: @feature, user: User.find(2), notes: '{{parent_issue}}')
    out = textilizable(journal, :notes)
    assert_select_in out, 'a[href=?]', "/issues/#{@parent.id}"
  end

  def test_recursive_loop_is_detected
    Issue.where(id: @parent.id).update_all(description: '{{child_description(Feature request)}}')
    out = render_description(@feature, '{{parent_description}}')
    assert_include 'recursive loop detected', out
  end

  def test_early_exit_does_not_pop_the_entry_of_an_outer_macro
    outer = Issue.find(@parent.id)
    Thread.current[:issue_obj_stack] = [outer]
    textilizable('{{parent_description}}', object: Project.find(1))
    assert_equal [outer], Thread.current[:issue_obj_stack]
  end

  def test_issue_stack_is_empty_after_rendering
    render_description(@feature, '{{parent_description}} {{sibling_issue(Bug)}} {{child_issue(Feature request)}}')
    assert_empty Thread.current[:issue_obj_stack].to_a
  end

  def test_issue_stack_keeps_outer_issue_while_nested_macros_run
    # the description of the parent holds a macro itself; rendering it must not
    # pop the entry of the issue being rendered
    Issue.where(id: @parent.id).update_all(description: '{{child_issue(Bug)}}')
    out = render_description(@feature, '{{parent_description}} {{sibling_issue(Bug)}}')
    assert_select_in out, 'a[href=?]', "/issues/#{@bug.id}"
    assert_empty Thread.current[:issue_obj_stack].to_a
  end

  private

  def assert_select_in(html, *args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(html), *args, &block)
  end
end
