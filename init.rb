Redmine::WikiFormatting::Macros.register do
  desc "Insert the description of the parent"
  macro :parent_description do |obj, args|
    if obj&.parent&.present?
      parent = Issue.visible.find_by(id: obj.parent.id)
      return textilizable(parent.description) if parent
    else
      return textilizable("*no parent found*")
    end
  end
end

Redmine::WikiFormatting::Macros.register do
  desc "Displays an issue link including additional information for the issue's parent. Examples:\n\n" +
             "{{parent_issue(tracker1)}}                              -- Issue #123: Enhance macro capabilities\n" +
             "{{parent_issue(tracker1, project=true)}}                -- Andromeda - Issue #123: Enhance macro capabilities\n" +
             "{{parent_issue(tracker1, tracker=false)}}               -- #123: Enhance macro capabilities\n" +
             "{{parent_issue(tracker1, subject=false, project=true)}} -- Andromeda - Issue #123\n"
  macro :parent_issue do |obj, args|
    children_found = 0
    issue = nil
    content = ""
    options = {}
    if obj&.parent&.present?
      parent = Issue.visible.find_by(id: obj.parent.id)
      issue = parent
    else
      return textilizable("*no parent found*")
    end

    if issue
      # remove invalid options
      options.delete_if {|k, v| v != 'true' && v != 'false'}

      # turn string values into boolean
      options.each do |k, v|
        options[k] = v == 'true'
      end

      link_to_issue(issue, options)
    else
      # Fall back to regular issue link format to indicate, that there
      # should have been something.
      "##{id}"
    end
  end
end

Redmine::WikiFormatting::Macros.register do
  desc "Insert the description of the ticket's first found sibling of the given tracker"
  macro :sibling_description do |obj, args|
    content = ""
    siblings_found = 0
    if args.empty? or args.nil?
      content = "*tracker name should be given as argument to macro sibling_description*";
    else
      tracker = args[0]
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
      end
    end
    if siblings_found == 0
      content = "no sibling found of tracker "+args[0]
    end
    return content.html_safe
  end
end

Redmine::WikiFormatting::Macros.register do
  desc "Displays an issue link including additional information for the issue's first found sibling of the given tracker. Examples:\n\n" +
             "{{sibling_issue(tracker1)}}                              -- Issue #123: Enhance macro capabilities\n" +
             "{{sibling_issue(tracker1, project=true)}}                -- Andromeda - Issue #123: Enhance macro capabilities\n" +
             "{{sibling_issue(tracker1, tracker=false)}}               -- #123: Enhance macro capabilities\n" +
             "{{sibling_issue(tracker1, subject=false, project=true)}} -- Andromeda - Issue #123\n"
  macro :sibling_issue do |obj, args|
    siblings_found = 0
    issue = nil
    content = ""
    options = {}
    if args.empty? or args.nil?
      content = "*tracker name should be given as argument to macro sibling_issue*";
    else
      args, options = extract_macro_options(args, :project, :tracker, :subject)

      tracker = args[0]
      if obj&.parent&.present?
        parent = Issue.visible.find_by(id: obj.parent.id)
        parent.children.each do |child|
          if child.tracker.name == tracker
            break unless siblings_found == 0
            unless obj.id == child.id
              issue = Issue.visible.find_by(id: child.id)
              siblings_found += 1
            end
          end
        end if parent
      end
    end
    if siblings_found == 0
      content = "no sibling found of tracker "+args[0]
    else
      # remove invalid options
      options.delete_if {|k, v| v != 'true' && v != 'false'}

      # turn string values into boolean
      options.each do |k, v|
        options[k] = v == 'true'
      end

      link_to_issue(issue, options)
    end
  end
end

Redmine::WikiFormatting::Macros.register do
  desc "Insert the description of the ticket's first found child of the given tracker"
  macro :child_description do |obj, args|
    content = ""
    children_found = 0
    if args.empty? or args.nil?
      content = "*tracker name should be given as argument to macro child_description*";
    else
      tracker = args[0]
      obj.children.each do |child|
        if child.tracker.name.downcase.strip == tracker.downcase.strip
          break unless children_found == 0
          content += textilizable(child.description)
          children_found += 1
        end
      end
    end
    if children_found == 0
      content = "no child found of tracker "+args[0]
    end
    return content.html_safe
  end
end

Redmine::WikiFormatting::Macros.register do
  desc "Displays an issue link including additional information for the issue's first found child of the given tracker. Examples:\n\n" +
             "{{child_issue(tracker1)}}                              -- Issue #123: Enhance macro capabilities\n" +
             "{{child_issue(tracker1, project=true)}}                -- Andromeda - Issue #123: Enhance macro capabilities\n" +
             "{{child_issue(tracker1, tracker=false)}}               -- #123: Enhance macro capabilities\n" +
             "{{child_issue(tracker1, subject=false, project=true)}} -- Andromeda - Issue #123\n"
  macro :child_issue do |obj, args|
    children_found = 0
    issue = nil
    content = ""
    options = {}
    if args.empty? or args.nil?
      content = "*tracker name should be given as argument to macro child_issue*";
    else
      args, options = extract_macro_options(args, :project, :tracker, :subject)

      tracker = args[0]
      obj.children.each do |child|
        if child.tracker.name.downcase.strip == tracker.downcase.strip
          break unless children_found == 0
          issue = Issue.visible.find_by(id: child.id)
          children_found += 1
        end
      end
    end
    if children_found == 0
      content = "no child found of tracker "+args[0]
    else
      # remove invalid options
      options.delete_if {|k, v| v != 'true' && v != 'false'}

      # turn string values into boolean
      options.each do |k, v|
        options[k] = v == 'true'
      end

      link_to_issue(issue, options)
    end
  end
end


