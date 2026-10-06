# Redmine 7 migration: redmine_description_macros

Start a Claude Code (or Codex) session on this repository, branch `redmine70-migration`, with:

> Read CLAUDE.md and docs/REDMINE7-MIGRATION.md, then carry out the Redmine 7 migration of this
> plugin as described there, on branch redmine70-migration. That includes the plugin's tests on
> PostgreSQL and MariaDB, every function exercised end to end on a real running Redmine in a
> browser (with and without permissions, failure paths included) with screenshots you looked at,
> and an OpenAI review of the diff when OPENAI_API_KEY is set. Report to me in Dutch at the end.

This file is the plan and the memory of that work. Update it as you go: verdicts, results,
what is left. Written 2026-10-06 from a measured analysis (report at the bottom).

## Status

| | |
|---|---|
| Plugin id | `redmine_description_macros` |
| GEOxyz runs today | `main` |
| Upstream | geen |
| Runs on Redmine 7 as is | JA (with the fixes below) |
| Upstream sync | GEEN UPSTREAM |
| After sync | n.v.t. |
| Complexity (1 trivial .. 5 rewrite) | 1 |
| Measured on | Redmine 7.0.1 (7.0-stable-GEOxyz + latest 7.0-stable), Rails 8.1.3.1, Ruby 3.3.6, PostgreSQL 16 and MariaDB 10.11 |
| Branch head when this file was written | `b63d521` |

## Already on this branch

- 9d59ddc tests (31, new) + fixes: visibility leaks in parent_issue/child_issue/sibling_issue, *_issue return the link directly (Textile, CSS classes), sibling_issue case-insensitive tracker and own message, issue stack popped too often.
- end-to-end scenarios and screenshots (docs/e2e, docs/e2e/before), changelog, README.

## Work list for the migration session

In this order: things that break, security, the GEOxyz changes, the open items, then the checks.

**Open items from the analysis** (Dutch; where they conflict with a decision or a priority item above, those win)

1. Textile: *_issue macros show the issue link as escaped raw HTML (textilizable(link_to_issue(...))); likely same on 5.1, CommonMark fine - optionally return link_to_issue directly
2. R7 CommonMark sanitizer strips the link classes (status/closed styling) from *_issue output - cosmetic

**Checks**

3. Run the plugin's whole test suite on Redmine 7.0-stable-GEOxyz with PostgreSQL AND MariaDB, and once on 5.1-stable if the branch is meant to stay 5.1-compatible.
4. Check Redmine 7 webhooks against this plugin (see "Rules"), and note the result here even if nothing is needed.
5. Verify every feature of the plugin by hand on a running Redmine 7 (screenshots).

## Result of the migration session (2026-10-06)

Work list: 1 done (link returned directly, also fixes Textile), 2 done (classes kept, e2e checks `a.issue`), 3 done on 7.0-stable-GEOxyz (5.1 not run: no 5.1 checkout/Ruby 3.3 mismatch; the fixes use only APIs that exist on 5.1), 4 done (see Webhooks), 5 done.

Additional findings fixed (not in the analysis): `parent_issue`, `child_issue`, `sibling_issue` showed number and subject of issues the user may not see (information leak); the `ensure` pop emptied the stack of outer macros.

**Baseline** (before changes): plugin had no tests; smoke 11/11 pages, core flows 6 screenshots, 0 problems, on PostgreSQL.

**Numbers**

| | PostgreSQL 16.15 | MariaDB 10.11.14 |
|---|---|---|
| plugin tests (`test/helpers/macros_test.rb`) | 31 runs, 53 assertions, 0 failures | 31 runs, 53 assertions, 0 failures |
| e2e (production mode) | smoke 11, core 6, 10 scenarios (api, child_description, child_issue, macro_list, note, parent_description, parent_issue, settings, sibling_description, sibling_issue): 0 problems, 59 screenshots | same, 0 problems (screenshots in docs/e2e-mariadb) |

Tests that fail without the fixes: 8 of the 31 (checked by stashing macros.rb). Migrations: none. Eager load: production server booted on both. Not run together with other GEOxyz plugins (only this plugin installed here).

OpenAI review (gpt-5, `docs/reviews/openai-2026-10-06-9c4cec1.md`): no findings. Own review: `output.html_safe` in the description macros only wraps `textilizable` and `link_to_issue` output (both escaped); no new settings, no schema change.

**Webhooks**: the plugin changes only HTML rendering. Core webhook payloads (issues/show.api.rsb) deliver the description as typed, macros unexpanded, same as the REST API (scenario `api`). Consistent, nothing needed.

**Inventory**

| function | how a user reaches it | scenario | screenshots (docs/e2e/) |
|---|---|---|---|
| parent_description | `{{parent_description}}` in description or note | parent_description | parent_description-* (manager, reporter, no-parent, parent-private-reporter/manager) |
| parent_issue (+ project/tracker/subject options) | `{{parent_issue(...)}}` | parent_issue | parent_issue-* |
| sibling_description | `{{sibling_description(Tracker)}}` | sibling_description | sibling_description-* (manager, reporter, no-argument, no-parent) |
| sibling_issue | `{{sibling_issue(Tracker, ...)}}` | sibling_issue | sibling_issue-* |
| child_description | `{{child_description(Tracker)}}` | child_description | child_description-* (manager, reporter, outsider, no-argument) |
| child_issue | `{{child_issue(Tracker, ...)}}` | child_issue | child_issue-* |
| settings page (6 toggles + debug) | Administration > Plugins > Configure | settings | settings-* (defaults, off states, manager/reporter 403, anonymous login) |
| macro_list / settings hint | `{{macro_list}}` in wiki preview | macro_list | macro_list-* |
| macros in notes and note preview | issue edit form | note | note-* |
| loop detection | parent/child macros referencing each other | settings (DM loop child) | settings-debug-off, settings-restored |
| REST API / webhooks | /issues/:id.json | api | api-api-json |
| mail, rake tasks, cron, routes | none in this plugin | n.v.t. | |

`docs/e2e/before/` holds the child_issue, sibling_issue and parent_issue scenarios against the old code (b63d521) on Redmine 7: they fail there (links stripped/leaked), which is the evidence for the fixes.

## Open questions for Jan

1. Textile vs CommonMark: I made the *_issue macros return the link directly (option from the analysis). Alternative: keep textilizable. Recommendation: keep (done), it is the only way the link survives Textile and keeps classes.
2. Hiding invisible issues in `*_issue` macros changes output for users without access (they now see "no ... found" / "parent not visible" instead of a link). Alternative: keep showing. Recommendation: keep hidden (done), the old output leaked private subjects.
3. 5.1/6.1 were not run. If the branch must stay 5.1-compatible, run `./.codex/redmine_clone.sh 5.1-stable` and the tests once.

## GEOxyz changes to review or re-apply

Own plugin: all of it is GEOxyz code, so there is nothing to re-apply. While migrating, hold the code you touch to the rules below; list larger quality problems you find in the work list instead of fixing them in passing.

## After the upgrade (production)

Actions the person doing the upgrade must take, or know about, for this plugin:

- None. No migrations, settings or data fixes. Restart Redmine after deploying the plugin. Output of `*_issue` macros is now hidden for users who cannot see the issue (see open question 2).

## How to test

```sh
./.codex/redmine_clone.sh 7.0-stable-GEOxyz      # or 5.1-stable / 6.1-stable / 7.0-stable
./.codex/test_setup.sh                                 # RMP_DB=mariadb for MariaDB, RMP_PROVISION_DB=0 if a server runs
./.codex/test_plugin.sh                                # minitest + rspec of this plugin
```

```sh
./.codex/start_server.sh       # real Redmine (production mode) with this plugin, seeded users and projects
./.codex/e2e.sh                # browser: smoke over the plugin's pages, core issue flows, test/e2e/*.mjs
./.codex/openai_review.sh      # independent OpenAI review of the diff, only when OPENAI_API_KEY is set
```
Write one scenario per function in `test/e2e/<function>.mjs` (example at the top of
`.codex/e2e/lib.mjs`); screenshots and a table per scenario land in `docs/e2e/`. Users:
`admin`, `manager` (every permission), `reporter` (no plugin permissions), `outsider` (no
membership); password `Redmine7Test!`. Needs Node with Playwright and Chromium
(`npm install -g playwright && npx playwright install --with-deps chromium`).

On GitHub the same runs by hand only: Actions > "Redmine tests (manual)" > Run workflow (tick
"e2e" for the browser run; screenshots come back as an artifact).

The coordinator's harness (`plugin-check.sh` in the migration kit, kept outside this repo) adds a
browser smoke test of every page the plugin adds and runs all GEOxyz plugins together; the
results quoted in the analysis come from it.

## How the migration session works (same for every plugin)

1. **Start**: `git fetch && git checkout redmine70-migration && git pull`. Read this whole file,
   including the analysis report at the bottom. Do not reopen decisions recorded here.
2. **Baseline, before you change anything**:
   - the plugin's tests on Redmine 7.0-stable-GEOxyz with PostgreSQL and with MariaDB;
   - a real running Redmine with this plugin (`./.codex/start_server.sh`) and the browser run
     (`./.codex/e2e.sh`: smoke over every page the plugin adds, plus the core issue flows).
   Write the numbers here. Something already broken now is a finding, not your regression.
3. **Inventory of functions**: list every function of the plugin in this file, in a table
   "function | how a user reaches it | scenario | screenshot". Take them from the README,
   `init.rb` (permissions, menus, settings, project modules), routes, hooks and view
   overrides, macros, mail handling, API endpoints, rake tasks and cron jobs. This table is the
   coverage list for step 8; a function that is not in it will not be tested.
4. **GEOxyz changes**: go through the table above, one item at a time. Each kept or re-made change
   is its own commit with a test that proves it. Record the verdict in the table.
5. **Work list**: then the numbered list, in order. One concern per commit.
6. **Portability**: everything must run on Redmine's supported databases (PostgreSQL,
   MySQL/MariaDB; SQLite where the plugin already supports it). Migrations must be reversible and
   are run down and up on PostgreSQL and MariaDB.
7. **Together**: run with the other GEOxyz plugins installed (the migration kit's harness, or
   `RMP_EXTRA_PLUGINS`). A failure that only appears in combination is a finding to record here.
8. **End to end, visually, every function**: on the real Redmine from `start_server.sh`
   (production mode, the way GEOxyz runs it), write one scenario per function in
   `test/e2e/<function>.mjs` with `.codex/e2e/lib.mjs` and run them with `./.codex/e2e.sh`.
   - Each function as the users that matter: `admin`, `manager` (every permission, the
     plugin's included), `reporter` (member without the plugin's permissions), `outsider`
     (no membership, private project must stay invisible).
   - The failure paths too: setting off, permission absent, empty state, invalid input, the
     value that used to raise. A refusal that is shown is evidence as much as a success.
   - One screenshot per function and per path, with a caption saying what it proves. Open
     every screenshot and look at it: a picture nobody looked at proves nothing. Commit them
     in `docs/e2e/` and list them in the inventory table.
   - Functions without a page (mail in and out, REST API, rake tasks, cron, webhooks): exercise
     them against the same running instance (mails land in `redmine/tmp/mails`, `t.mails()`
     reads them; API through `t.page.request`) and record command and result.
   - Before pictures where behaviour or layout changes: the branch GEOxyz runs today, on
     Redmine 5.1, same scenarios, `RMP_E2E_OUT=docs/e2e/before`.
   - Run the whole e2e set once on MariaDB as well (`RMP_DB=mariadb`, then `start_server.sh --reset`).
9. **Independent review**: first your own, adversarial: re-read the whole diff as if someone
   else wrote it and you are paid to reject it. Then, **when `OPENAI_API_KEY` is set in the
   session**, `./.codex/openai_review.sh`: it sends the diff of this branch to an OpenAI model
   and writes `docs/reviews/openai-<date>-<sha>.md`. Every finding gets a `Resolution:` line
   there (fixed in <commit>, with a test, or why not). Fix, re-run the tests and the e2e set,
   and run the review again until it has nothing new that you accept. Without the key: write
   "OpenAI review: skipped, no OPENAI_API_KEY" in the report; never send code anywhere else.
10. **After the upgrade**: anything the production upgrade must do for this plugin (data fixes,
    settings, cron, files, removed features) goes into the section "After the upgrade".
11. **Finish**: update "Status", the inventory and the work list in this file, push
    `redmine70-migration`, and report: what changed, test numbers on both databases, e2e
    numbers (scenarios, screenshots, problems), the review result, what is left, what needs Jan.

### Stop and ask Jan when
- a GEOxyz change would be lost or behave differently for users;
- a new gem, a new setting with user impact, or a schema change not required by Redmine 7 seems needed;
- the change would send data to an external service (the OpenAI review of the code diff is the
  one exception Jan approved, and only when the key is present);
- upstream and GEOxyz disagree on behaviour and both are defensible.

## Rules

- **Target**: Redmine 7.0-stable-GEOxyz (https://github.com/jcatrysse/redmine), Rails 8.1, Ruby 3.3+.
  Core sources for comparison: branches `5.1-stable`, `6.1-stable`, `7.0-stable`, `7.0-stable-GEOxyz`.
- **Evidence**: never report a test, lint, browser check or review as passed without having seen
  it. Quote the summary lines; list the screenshots. "Should work" is not a result, and a green
  test suite is not proof that a feature works in the browser.
- **Tests**: never skip, delete or weaken a test. A test that encodes Redmine 5 markup or
  behaviour is updated to Redmine 7, with the reason in the commit. Every fix gets a test that
  fails without it.
- **Minimal diffs** in the plugin's own style. No reformatting, no unrelated refactoring.
  Something wrong elsewhere: write it down here, do not fix it in passing.
- **Security**: authorization on every action and entry point; `safe_attributes`, never
  `to_unsafe_hash` into `update`; no SQL built from params; no secrets in logs; no `html_safe` on
  user input.
- **Webhooks (new in Redmine 7)**: core sends issue payloads (core `issues/show.api.rsb`, rendered
  as the webhook owner) to webhook endpoints, past plugin hooks and controller patches. If the
  plugin hides, adds or changes issue data, make webhooks consistent with that or record why not.
- **Redmine 7 conventions**: SVG icons through `sprite_icon` (the `icon icon-*` CSS is gone),
  Propshaft assets under `assets/` (`/assets/plugin_assets/<id>/...`), the new header and user menu,
  `ContextMenus::*Controller`, Loofah-based text formatting, Chart.js as an ES module, sudo mode
  (on by default: `t.sudo()` in a scenario). The breaker list is in the migration kit's CHECKLIST.md.
- **Locales**: keep the locales the plugin ships in sync; translate a new key by matching the
  closest existing key in the same file, not from scratch; do not add new languages.
- **5.1 compatibility**: prefer fixes that also run on Redmine 5.1 so they can be merged early;
  say so when a fix cannot.
- **Git**: work on `redmine70-migration` only; never push to the default branch; never force-push
  a branch someone else uses. Descriptive commit messages (what and why). Push after every
  commit, together with the updated status in this file: a cloud session can stop at a usage
  limit, and work that is not pushed is lost with its container.
- **GitHub Actions**: manual only (`workflow_dispatch`). Do not add push, pull_request or schedule
  triggers.

## Definition of done

- All items of the work list are done or explicitly deferred with a reason, in this file.
- The plugin's tests are green on Redmine 7.0-stable-GEOxyz with PostgreSQL and MariaDB
  (numbers in this file); boot, production-like eager load, migrations up/down OK.
- Every function in the inventory exercised end to end on a real running Redmine, with and
  without permissions and on its failure paths; `./.codex/e2e.sh` green; screenshots looked at,
  committed in `docs/e2e/` and listed.
- Review done: your own, and the OpenAI review when the key is present, every finding resolved
  in `docs/reviews/`.
- No new failure when run together with the other GEOxyz plugins.
- "After the upgrade" lists every action production needs; "Status" is current.


## Analysis report (2026-10-06, Dutch)

# redmine_description_macros
- Gebruikte branch: main @ 0dc2f6b (2026-01-27) - plugin id redmine_description_macros, versie 0.0.1
- Upstream: geen (eigen plugin, jcatrysse/redmine_description_macros)
- Fork t.o.v. upstream: n.v.t.
- Andere relevante branches: geen (alleen main)
- Opbouw: 6 macro's (`parent_description`, `parent_issue`, `sibling_description`, `sibling_issue`, `child_description`, `child_issue`) in `lib/redmine_description_macros/macros.rb`, instellingen-partial, locales. Geen Gemfile, migraties of tests.

## 1. Werkt out of the box op Redmine 7?   JA
- Harness (`results/1006-085209-s1-redmine_description_macros_origin_main`): boot OK, eager OK, migraties OK, smoke 60/60.
- Rendering in de browser (parent/child/sibling-issues aangemaakt, CommonMark):
  - child: `{{parent_description}}` toont de parent-description geformatteerd (`<strong>parent bold</strong> &amp; <i>raw</i>`), inclusief geneste macro's. `{{parent_issue(tracker=false)}}` -> link "#11: DM parent".
  - parent: `{{child_description(Feature)}}` en `{{child_issue(Feature, project=true)}}` -> "GEOxyz verification - Feature #12: DM child".
  - sibling: `{{sibling_description(Feature)}}` / `{{sibling_issue(Feature)}}` OK.
  - Recursiedetectie werkt ("recursive loop detected for issue Bug #11"). Macro in een journal-note (`{{parent_issue}}`) werkt.
- Textile: de description-macro's werken, maar `*_issue` toont de link als ruwe HTML-tekst (`&lt;a class="issue ..."&gt;`). `textilizable(link_to_issue(...))` laat HTML door Textile escapen. Dat mechanisme is in R7 niet veranderd, dus waarschijnlijk al zo op 5.1 (niet op 5.1 geverifieerd). Op CommonMark correct.

## 2. Upstream sync?   GEEN UPSTREAM

## 3. Werkt na sync op Redmine 7?   n.v.t.

## 4. Complexiteit en blokkers   score 1
- Blokkers: geen.
- Stille breuken: de CommonMark-sanitizer van R7 laat op `<a>` alleen `href/id/name` toe. De CSS-classes van `link_to_issue` (status, closed-doorhaling) vallen weg in de `*_issue`-macro's. Op 5.1 (html-pipeline-allowlist) waarschijnlijk gelijk, cosmetisch.
- Static scan: geen R7-breakers (geen serialize/enum/to_s(:db)/core-view-overrides/patches). `Thread.current[:issue_obj_stack]` wordt in `ensure` opgeruimd.
- Overlap met Redmine 7 core: geen.
- Open werk voor ansif:
  1. Optioneel: `*_issue`-macro's de link direct laten teruggeven (`link_to_issue(...)` zonder `textilizable`), dan werken ze ook op Textile en houden ze hun classes. Functionele wijziging, niet nodig voor R7.

## Branch redmine70-migration
- Basis: origin/main @ 0dc2f6b (geen wijzigingen nodig)
- Commits: geen (branch = origin/main)
- Eindresultaat harness (`results/1006-095808-s1-redmine_description_macros_redmine70-migration`): boot OK, eager OK, migraties OK, smoke 60/60 (geen tests in de plugin)
- Rollback migraties: n.v.t. (geen migraties)

