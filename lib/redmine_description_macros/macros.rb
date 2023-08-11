module RedmineDescriptionMacros
  module Macros
    Redmine::WikiFormatting::Macros.register do
      desc "Insert the description of the parent"
      macro :parent_description do |obj, args|
        next unless Setting.plugin_redmine_description_macros['enable_parent_description_macro']
        debug_messages = Setting.plugin_redmine_description_macros['enable_macro_debug_messages']
        issue_stack = Thread.current[:issue_obj_stack] ||= [] # Initialize the issue object stack if it doesn't exist
        obj ||= issue_stack.last # Try to get the object from the top of the stack if obj is nil

        if obj.nil?
          next textilizable(debug_messages ? "*object for macro is not initialized*" : nil)
        elsif !obj.kind_of?(Issue) && obj.respond_to?(:issue) && obj.issue
          obj = obj.issue
        end

        unless obj.kind_of?(Issue)
          next textilizable(debug_messages ? "*macro must be used on an issue or a note*" : nil)
        end

        loop_detected_message = "*recursive loop detected for issue #{link_to_issue(Issue.find_by(id: obj.id))}*"
        next textilizable(debug_messages ? loop_detected_message : nil) if issue_stack.map(&:id).count(obj.id) > 1 # Check for loops using the stack

        issue_stack.push(obj) # Push the current object onto the stack

        output = if obj.parent&.present?
                   if obj.parent.visible?
                     textilizable(obj.parent, :description)
                   else
                     textilizable("*parent not visible*")
                   end
                 else
                   textilizable("*no parent found*")
                 end

        issue_stack.pop # Pop the current object off the stack since we're done with it
        output
      ensure
        issue_stack.pop if issue_stack.any? # If the stack is empty, reset the processed issues set
      end
    end

    Redmine::WikiFormatting::Macros.register do
      desc "Displays an issue link including additional information for the issue's parent. Examples:\n\n" +
             "{{parent_issue}}                              -- Issue #123: Enhance macro capabilities\n" +
             "{{parent_issue(project=true)}}                -- Andromeda - Issue #123: Enhance macro capabilities\n" +
             "{{parent_issue(tracker=false)}}               -- #123: Enhance macro capabilities\n" +
             "{{parent_issue(subject=false, project=true)}} -- Andromeda - Issue #123\n"
      macro :parent_issue do |obj, args|
        next unless Setting.plugin_redmine_description_macros['enable_parent_issue_macro']
        debug_messages = Setting.plugin_redmine_description_macros['enable_macro_debug_messages']
        issue_stack = Thread.current[:issue_obj_stack] ||= [] # Initialize the issue object stack if it doesn't exist
        obj ||= issue_stack.last # Try to get the object from the top of the stack if obj is nil

        if obj.nil?
          next textilizable(debug_messages ? "*object for macro is not initialized*" : nil)
        elsif !obj.kind_of?(Issue) && obj.respond_to?(:issue) && obj.issue
          obj = obj.issue
        end

        unless obj.kind_of?(Issue)
          next textilizable(debug_messages ? "*macro must be used on an issue or a note*" : nil)
        end

        loop_detected_message = "*recursive loop detected for issue #{link_to_issue(Issue.find_by(id: obj.id))}*"
        next textilizable(debug_messages ? loop_detected_message : nil) if issue_stack.map(&:id).count(obj.id) > 1 # Check for loops using the stack

        issue_stack.push(obj) # Push the current object onto the stack

        output = if obj.parent&.present?
                   args, options = extract_macro_options(args, :project, :tracker, :subject)
                   options.delete_if {|k, v| v != 'true' && v != 'false'} # remove invalid options
                   options.each do |k, v| # turn string values into boolean
                     options[k] = v == 'true'
                   end
                   textilizable(link_to_issue(obj.parent, options))
                 else
                   textilizable("*no parent found*")
                 end

        issue_stack.pop # Pop the current object off the stack since we're done with it
        output
      ensure
        issue_stack.pop if issue_stack.any? # If the stack is empty, reset the processed issues set
      end
    end

    Redmine::WikiFormatting::Macros.register do
      desc "Insert the description of the ticket's first found sibling of the given tracker"
      macro :sibling_description do |obj, args|
        next unless Setting.plugin_redmine_description_macros['enable_sibling_description_macro']

        debug_messages = Setting.plugin_redmine_description_macros['enable_macro_debug_messages']
        issue_stack = Thread.current[:issue_obj_stack] ||= [] # Initialize the issue object stack if it doesn't exist

        obj ||= issue_stack.last # Try to get the object from the top of the stack if obj is nil

        if obj.nil?
          next textilizable(debug_messages ? "*object for macro is not initialized*" : nil)
        elsif !obj.kind_of?(Issue) && obj.respond_to?(:issue) && obj.issue
          obj = obj.issue
        end

        unless obj.kind_of?(Issue)
          next textilizable(debug_messages ? "*macro must be used on an issue or a note*" : nil)
        end

        loop_detected_message = "*recursive loop detected for issue #{link_to_issue(Issue.find_by(id: obj.id))}*"
        next textilizable(debug_messages ? loop_detected_message : nil) if issue_stack.map(&:id).count(obj.id) > 1 # Check for loops using the stack

        issue_stack.push(obj) # Push the current object onto the stack

        output = ""
        siblings_found = 0
        loop_detected = false

        if args.empty? or args.nil?
          output += textilizable("*tracker name should be given as argument to macro sibling_description*")
        else
          tracker = args[0]
          if obj.parent&.present?
            obj.parent.children.each do |child|
              if child.tracker.name.downcase.strip == tracker.downcase.strip
                if issue_stack.map(&:id).length != issue_stack.map(&:id).uniq.length
                  output += textilizable(debug_messages ? loop_detected_message : nil)
                  loop_detected = true
                end
                break if siblings_found == 1 || loop_detected === true
                unless obj.id == child.id
                  if child.visible?
                    output += textilizable(child,:description)
                    siblings_found += 1
                  end
                end
              end
            end
          end
          output += textilizable("*no sibling found of tracker #{tracker}*") if siblings_found == 0 && loop_detected === false
        end

        issue_stack.pop # Pop the current object off the stack since we're done with it
        output.html_safe if output
      ensure
        issue_stack.pop if issue_stack.any? # If the stack is empty, reset the processed issues set
      end
    end

    Redmine::WikiFormatting::Macros.register do
      desc "Displays an issue link including additional information for the issue's first found sibling of the given tracker. Examples:\n\n" +
             "{{sibling_issue(tracker_name)}}                              -- Issue #123: Enhance macro capabilities\n" +
             "{{sibling_issue(tracker_name, project=true)}}                -- Andromeda - Issue #123: Enhance macro capabilities\n" +
             "{{sibling_issue(tracker_name, tracker=false)}}               -- #123: Enhance macro capabilities\n" +
             "{{sibling_issue(tracker_name, subject=false, project=true)}} -- Andromeda - Issue #123\n"
      macro :sibling_issue do |obj, args|
        next unless Setting.plugin_redmine_description_macros['enable_sibling_issue_macro']

        debug_messages = Setting.plugin_redmine_description_macros['enable_macro_debug_messages']
        issue_stack = Thread.current[:issue_obj_stack] ||= [] # Initialize the issue object stack if it doesn't exist

        obj ||= issue_stack.last # Try to get the object from the top of the stack if obj is nil

        if obj.nil?
          next textilizable(debug_messages ? "*object for macro is not initialized*" : nil)
        elsif !obj.kind_of?(Issue) && obj.respond_to?(:issue) && obj.issue
          obj = obj.issue
        end

        unless obj.kind_of?(Issue)
          next textilizable(debug_messages ? "*macro must be used on an issue or a note*" : nil)
        end

        loop_detected_message = "*recursive loop detected for issue #{link_to_issue(Issue.find_by(id: obj.id))}*"
        next textilizable(debug_messages ? loop_detected_message : nil) if issue_stack.map(&:id).count(obj.id) > 1 # Check for loops using the stack

        issue_stack.push(obj) # Push the current object onto the stack

        output = ""
        siblings_found = 0
        loop_detected = false

        if args.empty? or args.nil?
          output += textilizable("*tracker name should be given as argument to macro sibling_description*")
        else
          tracker = args[0]
          if obj.parent&.present?
            obj.parent.children.each do |child|
              if child.tracker.name == tracker
                if issue_stack.map(&:id).length != issue_stack.map(&:id).uniq.length
                  output += textilizable(debug_messages ? loop_detected_message : nil)
                  loop_detected = true
                end
                break if siblings_found == 1 || loop_detected === true
                unless obj.id == child.id
                  args, options = extract_macro_options(args, :project, :tracker, :subject)
                  options.delete_if {|k, v| v != 'true' && v != 'false'} # remove invalid options
                  options.each do |k, v| # turn string values into boolean
                    options[k] = v == 'true'
                  end
                  output += textilizable(link_to_issue(child, options))
                  siblings_found += 1
                end
              end
            end
          end
          output += textilizable("*no sibling found of tracker #{tracker}*") if siblings_found == 0 && loop_detected === false
        end

        issue_stack.pop # Pop the current object off the stack since we're done with it
        output.html_safe if output
      ensure
        issue_stack.pop if issue_stack.any? # If the stack is empty, reset the processed issues set
      end
    end

    Redmine::WikiFormatting::Macros.register do
      desc "Insert the description of the ticket's first found child of the given tracker"
      macro :child_description do |obj, args|
        next unless Setting.plugin_redmine_description_macros['enable_child_description_macro']

        debug_messages = Setting.plugin_redmine_description_macros['enable_macro_debug_messages']
        issue_stack = Thread.current[:issue_obj_stack] ||= [] # Initialize the issue object stack if it doesn't exist

        obj ||= issue_stack.last # Try to get the object from the top of the stack if obj is nil

        if obj.nil?
          next textilizable(debug_messages ? "*object for macro is not initialized*" : nil)
        elsif !obj.kind_of?(Issue) && obj.respond_to?(:issue) && obj.issue
          obj = obj.issue
        end

        unless obj.kind_of?(Issue)
          next textilizable(debug_messages ? "*macro must be used on an issue or a note*" : nil)
        end

        loop_detected_message = "*recursive loop detected for issue #{link_to_issue(Issue.find_by(id: obj.id))}*"
        next textilizable(debug_messages ? loop_detected_message : nil) if issue_stack.map(&:id).count(obj.id) > 1 # Check for loops using the stack

        issue_stack.push(obj) # Push the current object onto the stack

        output = ""
        children_found = 0
        loop_detected = false

        if args.empty? or args.nil?
          output += textilizable("*tracker name should be given as argument to macro child_description*")
        else
          tracker = args[0]
          obj.children.each do |child|
            if child.tracker.name.downcase.strip == tracker.downcase.strip
              if issue_stack.map(&:id).length != issue_stack.map(&:id).uniq.length
                output += textilizable(debug_messages ? loop_detected_message : nil)
                loop_detected = true
              end
              break if children_found == 1 || loop_detected === true
              unless obj.id == child.id
                if child.visible?
                  output += textilizable(child,:description)
                  children_found += 1
                end
              end
            end
          end
          output += textilizable("*no children found of tracker #{tracker}*") if children_found == 0 && loop_detected === false
        end

        issue_stack.pop # Pop the current object off the stack since we're done with it
        output.html_safe if output
      ensure
        issue_stack.pop if issue_stack.any? # If the stack is empty, reset the processed issues set
      end
    end

    Redmine::WikiFormatting::Macros.register do
      desc "Displays an issue link including additional information for the issue's first found child of the given tracker. Examples:\n\n" +
             "{{child_issue(tracker_name)}}                              -- Issue #123: Enhance macro capabilities\n" +
             "{{child_issue(tracker_name, project=true)}}                -- Andromeda - Issue #123: Enhance macro capabilities\n" +
             "{{child_issue(tracker_name, tracker=false)}}               -- #123: Enhance macro capabilities\n" +
             "{{child_issue(tracker_name, subject=false, project=true)}} -- Andromeda - Issue #123\n"
      macro :child_issue do |obj, args|
        next unless Setting.plugin_redmine_description_macros['enable_child_issue_macro']

        debug_messages = Setting.plugin_redmine_description_macros['enable_macro_debug_messages']
        issue_stack = Thread.current[:issue_obj_stack] ||= [] # Initialize the issue object stack if it doesn't exist

        obj ||= issue_stack.last # Try to get the object from the top of the stack if obj is nil

        if obj.nil?
          next textilizable(debug_messages ? "*object for macro is not initialized*" : nil)
        elsif !obj.kind_of?(Issue) && obj.respond_to?(:issue) && obj.issue
          obj = obj.issue
        end

        unless obj.kind_of?(Issue)
          next textilizable(debug_messages ? "*macro must be used on an issue or a note*" : nil)
        end

        loop_detected_message = "*recursive loop detected for issue #{link_to_issue(Issue.find_by(id: obj.id))}*"
        next textilizable(debug_messages ? loop_detected_message : nil) if issue_stack.map(&:id).count(obj.id) > 1 # Check for loops using the stack

        issue_stack.push(obj) # Push the current object onto the stack

        output = ""
        children_found = 0
        loop_detected = false

        if args.empty? or args.nil?
          output += textilizable("*tracker name should be given as argument to macro child_issue*")
        else
          tracker = args[0]
          obj.children.each do |child|
            if child.tracker.name.downcase.strip == tracker.downcase.strip
              if issue_stack.map(&:id).length != issue_stack.map(&:id).uniq.length
                output += textilizable(debug_messages ? loop_detected_message : nil)
                loop_detected = true
              end
              break if children_found == 1 || loop_detected === true
              unless obj.id == child.id
                args, options = extract_macro_options(args, :project, :tracker, :subject)
                options.delete_if {|k, v| v != 'true' && v != 'false'} # remove invalid options
                options.each do |k, v| # turn string values into boolean
                  options[k] = v == 'true'
                end
                output += textilizable(link_to_issue(child, options))
                children_found += 1
              end
            end
          end
          output += textilizable("*no children found of tracker #{tracker}*") if children_found == 0 && loop_detected === false
        end

        issue_stack.pop # Pop the current object off the stack since we're done with it
        output.html_safe if output
      ensure
        issue_stack.pop if issue_stack.any? # If the stack is empty, reset the processed issues set
      end
    end
  end
end
