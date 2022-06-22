Redmine::WikiFormatting::Macros.register do
  desc "Insert the description of the parent"
  macro :parent_description do |obj, args|
    if obj.parent and !obj.parent.nil? and !obj.parent.empty?
      parent = Issue.find(obj.parent.id)
      return parent.description
    else
      return textilizable("*no parent found*")
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
      all = (args.length > 1 and args[1])
      if obj.parent and obj.parent.present?
        parent = Issue.find(obj.parent.id)
        parent.children.each do |child|
          if child.tracker.name == tracker
            break unless all or siblings_found == 0
            unless obj.id == child.id
              content += textilizable("**##{child.id}: #{child.subject}**")+"\r\n"+child.description+textilizable("----------")+"\r\n"
              siblings_found += 1
            end
          end
        end
      end
    end
    if siblings_found == 0
      content = textilizable("*no sibling found of tracker "+args[0]+"*")
    end
    return content.html_safe
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
      all = (args.length > 1 and args[1])
      obj.children.each do |child|
        if child.tracker.name.downcase.strip == tracker.downcase.strip
          break unless all or children_found == 0
          content += textilizable("**##{child.id}: #{child.subject}**")+"\r\n"+child.description+textilizable("----------")+"\r\n"
          children_found += 1
        end
      end
    end
    if children_found == 0
      content = textilizable("*no child found of tracker "+args[0]+"*")
    end
    return content.html_safe
  end
end


