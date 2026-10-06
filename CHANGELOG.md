# CHANGELOG
## Unreleased
* Tested on Redmine 7.0 (PostgreSQL and MariaDB).
* Security: parent_issue, child_issue and sibling_issue no longer show the subject of issues the user may not see.
* The *_issue macros return the issue link directly: it works with Textile and keeps its CSS classes.
* sibling_issue matches the tracker name case-insensitively, like the other macros.
* Fixed the issue stack being popped too often (loop detection, macros inside macros).
* Added tests (test/helpers) and end-to-end scenarios (test/e2e).
## 0.0.1
* Initial commit
