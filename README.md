# Redmine Description Macros

Redmine Description Macros enhance your Redmine experience by allowing users to extend the functionality of descriptions and notes with a set of custom macros. The macros come with a range of options to provide flexibility in their application.  

One of the standout features is the ability to handle iterations and circular recursion issues seamlessly, ensuring the integrity and functionality of your Redmine setup.  

You can easily configure settings related to these macros via the plugin settings.

To get an overview of available macros, simply use the `{{macro_list}}` command.

## Features
parent_description

    Insert the description of the parent

parent_issue

    Displays an issue link including additional information for the issue's parent. Examples:

    {{parent_issue}}                              -- Issue #123: Enhance macro capabilities
    {{parent_issue(project=true)}}                -- Andromeda - Issue #123: Enhance macro capabilities
    {{parent_issue(tracker=false)}}               -- #123: Enhance macro capabilities
    {{parent_issue(subject=false, project=true)}} -- Andromeda - Issue #123

sibling_description

    Insert the description of the ticket's first found sibling of the given tracker

sibling_issue

    Displays an issue link including additional information for the issue's first found sibling of the given tracker. Examples:

    {{sibling_issue(tracker_name)}}                              -- Issue #123: Enhance macro capabilities
    {{sibling_issue(tracker_name, project=true)}}                -- Andromeda - Issue #123: Enhance macro capabilities
    {{sibling_issue(tracker_name, tracker=false)}}               -- #123: Enhance macro capabilities
    {{sibling_issue(tracker_name, subject=false, project=true)}} -- Andromeda - Issue #123

child_description

    Insert the description of the ticket's first found child of the given tracker

child_issue

    Displays an issue link including additional information for the issue's first found child of the given tracker. Examples:

    {{child_issue(tracker_name)}}                              -- Issue #123: Enhance macro capabilities
    {{child_issue(tracker_name, project=true)}}                -- Andromeda - Issue #123: Enhance macro capabilities
    {{child_issue(tracker_name, tracker=false)}}               -- #123: Enhance macro capabilities
    {{child_issue(tracker_name, subject=false, project=true)}} -- Andromeda - Issue #123


## Author
* Robin Bailleul (2022)
* Jan Catrysse (2023)

## Install
Type below commands:
* $ `cd $RAILS_ROOT/plugins`
* $ `git clone https://github.com/jcatrysse/redmine_description_macros.git`
* $ `bundle exec rake redmine:plugins:migrate NAME=redmine_description_macros RAILS_ENV=production`

Macros can be enabled in the Plugin Settings

Then, restart your Redmine.

## Requirements
* Redmine 4.x
* Redmine 5.x

## License
The MIT License (MIT)
Copyright (c) 2022 Robin Bailleul
Copyright (c) 2023 Jan Catrysse
