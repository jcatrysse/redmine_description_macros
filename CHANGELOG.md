# CHANGELOG
## Unreleased
* Tested on Redmine 7.0 (PostgreSQL and MariaDB).
* Security: parent_issue, child_issue and sibling_issue no longer show the subject of issues the user may not see.
* The *_issue macros return the issue link directly: it works with Textile and keeps its CSS classes.
* sibling_issue matches the tracker name case-insensitively, like the other macros.
* Fixed the issue stack being popped too often (loop detection, macros inside macros).
* Added tests (test/helpers) and end-to-end scenarios (test/e2e).
* Fixed: the settings were checked by truthiness, so a value of "0" (or "false") set by a script counted as on. On is now what the settings form stores ("1") or the default (true); anything else is off. Also for the debug messages setting.
## 0.0.1
* Initial commit
