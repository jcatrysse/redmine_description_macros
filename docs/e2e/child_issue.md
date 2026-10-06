# child_issue

Run 2026-10-06T19:33:36.179Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](child_issue-manager.png) | manager | `/issues/11` | Manager: child link (lower case tracker), project=true tracker=false, and the private child |
| ![](child_issue-reporter.png) | reporter | `/issues/11` | Reporter: private child not linked (was a leak) |
| ![](child_issue-outsider.png) | outsider | `/issues/11` | Non-member: same |
| ![](child_issue-no-argument.png) | reporter | `/issues/11` | Failure path: no argument |
