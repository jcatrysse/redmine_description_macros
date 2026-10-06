# parent_description

Run 2026-10-06T19:37:20.935Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](parent_description-manager.png) | manager | `/issues/8` | Manager: the description of the parent is inserted, formatted (bold) |
| ![](parent_description-reporter.png) | reporter | `/issues/8` | Reporter (no plugin permissions exist): same result |
| ![](parent_description-no-parent.png) | manager | `/issues/14` | Failure path: issue without a parent shows "no parent found" |
| ![](parent_description-parent-private-reporter.png) | reporter | `/issues/16` | Failure path: a parent the user may not see shows "parent not visible", no content |
| ![](parent_description-parent-private-manager.png) | manager | `/issues/16` | Manager may see the private parent, so its description is inserted |
