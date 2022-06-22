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
    content = "*tracker name should be given as argument to macro sibling_description*";
    if args and !args.empty? and !args.nil?
      content = textilizable("*no sibling found of tracker "+args[0]+"*")
      tracker = args[0]
      if obj.parent and !obj.parent.nil? and !obj.parent.empty?
        parent = Issue.find(obj.parent.id)
        parent.children.each do |child|
          if child.tracker.name == tracker
            content = textilizable("**##{child.id}: #{child.subject}**")+"\r\n"+child.description+textilizable("-----")
          end
        end
      end
    end
    return content
  end
end

Redmine::WikiFormatting::Macros.register do
  desc "Insert the description of the ticket's first found child of the given tracker"
  macro :child_description do |obj, args|
    content = "*tracker name should be given as argument to macro child_description*";
    if !args.empty? and !args.nil?
      content = textilizable("*no child found of tracker "+args[0]+"*")
      tracker = args[0]
      obj.children.each do |child|
        if child.tracker.name == tracker
          content = textilizable("**##{child.id}: #{child.subject}**")+"\r\n"+child.description+textilizable("-----")
        end
      end
    end
    return content
  end
end


