# Plugin data for the end-to-end scenarios, run by start_server.sh after the
# generic seed. Idempotent. Issues are found by subject ("DM ...").
User.current = User.find_by!(login: 'admin')
project = Project.find_by!(identifier: 'e2e-project')
bug = Tracker.find_by!(name: 'Bug')
feature = Tracker.find_by!(name: 'Feature')
support = Tracker.find_by!(name: 'Support')

Setting.plugin_redmine_description_macros = {
  'enable_child_description_macro' => '1', 'enable_child_issue_macro' => '1',
  'enable_parent_description_macro' => '1', 'enable_parent_issue_macro' => '1',
  'enable_sibling_description_macro' => '1', 'enable_sibling_issue_macro' => '1',
  'enable_macro_debug_messages' => '1'
}

def dm_issue(project, tracker, subject, description, parent: nil, is_private: false)
  issue = Issue.find_by(project_id: project.id, subject: subject)
  if issue
    Issue.where(id: issue.id).update_all(description: description)
    return issue
  end
  issue = Issue.new(project: project, tracker: tracker, subject: subject, description: description,
                    author: User.current, priority: IssuePriority.default || IssuePriority.first,
                    is_private: is_private)
  issue.status = tracker.default_status
  issue.parent_issue_id = parent.id if parent
  issue.save!
  issue
end

# Family A: macros in the children, looking up
a = dm_issue(project, bug, 'DM A parent', "Parent description with **bold** text.")
dm_issue(project, feature, 'DM A feature', <<~TEXT, parent: a)
  parent_description: {{parent_description}}

  parent_issue: {{parent_issue}}

  parent_issue short: {{parent_issue(project=true, tracker=false, subject=false)}}

  sibling_description: {{sibling_description(Support)}}

  sibling_issue: {{sibling_issue(support)}}

  sibling_issue project: {{sibling_issue(Support, project=true, subject=false)}}

  sibling_description secret: {{sibling_description(Bug)}}

  sibling_issue secret: {{sibling_issue(Bug)}}

  sibling_description none: {{sibling_description(Feature)}}

  sibling_description no argument: {{sibling_description}}

  sibling_issue no argument: {{sibling_issue}}
TEXT
dm_issue(project, support, 'DM A support', 'Support sibling description text.', parent: a)
dm_issue(project, bug, 'DM A secret', 'SECRET description of a private sibling.', parent: a, is_private: true)

# Family B: macros in the parent, looking down
b = dm_issue(project, bug, 'DM B parent', <<~TEXT)
  child_description: {{child_description(Feature)}}

  child_issue: {{child_issue(Feature)}}

  child_issue project: {{child_issue(feature, project=true, tracker=false)}}

  child_description secret: {{child_description(Bug)}}

  child_issue secret: {{child_issue(Bug)}}

  child_description none: {{child_description(Support)}}

  child_issue none: {{child_issue(Support)}}

  child_description no argument: {{child_description}}

  child_issue no argument: {{child_issue}}
TEXT
dm_issue(project, feature, 'DM B feature', 'Child feature description text.', parent: b)
dm_issue(project, bug, 'DM B secret', 'SECRET description of a private child.', parent: b, is_private: true)

# Issue without relations
dm_issue(project, bug, 'DM lonely', <<~TEXT)
  {{parent_description}} / {{parent_issue}} / {{sibling_description(Bug)}} / {{child_issue(Bug)}}
TEXT

# Private parent with a visible child
pp = dm_issue(project, bug, 'DM private parent', 'SECRET description of a private parent.', is_private: true)
dm_issue(project, feature, 'DM private parent child', "{{parent_description}} / {{parent_issue}}", parent: pp)

# Loop: parent shows its child, the child shows its parent
l = dm_issue(project, bug, 'DM loop parent', '{{child_description(Feature)}}')
dm_issue(project, feature, 'DM loop child', '{{parent_description}}', parent: l)

# Macro in a note, and an unrelated macro on plain text
np = dm_issue(project, bug, 'DM note parent', 'Description of the parent seen from a note.')
n = dm_issue(project, feature, 'DM note issue', 'Issue that gets a note with a macro.', parent: np)
if n.journals.none?
  n.init_journal(User.find_by!(login: 'manager'), 'Note: {{parent_issue}} and {{parent_description}}')
  n.save!
end

puts "Plugin seed: #{Issue.where(project_id: project.id).where('subject LIKE ?', 'DM %').count} DM issues"
