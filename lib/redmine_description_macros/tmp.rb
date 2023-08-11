Redmine::WikiFormatting::Macros.register do
  desc "Insert the description of the ticket's first found sibling of the given tracker"
  macro :sibling_description do |obj, args|
    next unless Setting.plugin_redmine_description_macros['enable_sibling_description_macro']

    debug_messages = Setting.plugin_redmine_description_macros['enable_macro_debug_messages']
    issue_stack = Thread.current[:issue_obj_stack] ||= [] # Initialize the issue object stack if it doesn't exist

    obj ||= issue_stack.last # Try to get the object from the top of the stack if obj is nil

    loop_detected_message = "Recursive loop detected for issue #{link_to_issue(Issue.find_by(id: obj.id))}"
    next textilizable(debug_messages ? loop_detected_message : nil) if issue_stack.map(&:id).count(obj.id) > 1 # Check for loops using the stack

    issue_stack.push(obj) # Push the current object onto the stack

    content = ""
    siblings_found = 0

    if args.empty? or args.nil?
      content = debug_messages ? "*tracker name should be given as argument to macro sibling_description*" : nil
    else
      tracker = args[0]
      if obj
        if obj&.parent&.present?
          parent = Issue.visible.find_by(id: obj.parent.id)
          parent.children.each do |child|
            if child.tracker.name == tracker
              break unless siblings_found == 0
              unless obj.id == child.id
                content += textilizable(child.description)
                siblings_found += 1
              end
            end
          end if parent
        else
          content += debug_messages ? textilizable("*no object defined*") : nil
        end
      end
    end

    content = debug_messages ? "no sibling found of tracker #{args[0]}" : nil if siblings_found == 0

    issue_stack.pop # Pop the current object off the stack since we're done with it
    content.html_safe
  ensure
    issue_stack.pop if issue_stack.any? # If the stack is empty, reset the processed issues set
  end
end
