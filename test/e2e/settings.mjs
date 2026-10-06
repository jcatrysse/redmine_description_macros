import { e2e } from '../../.codex/e2e/lib.mjs';
import { checkIssue, issueId, description, expect } from '../e2e_helpers/helpers.mjs';
const t = await e2e('settings');
const PATH = '/settings/plugin/redmine_description_macros';
const MACROS = ['child_description', 'child_issue', 'parent_description', 'parent_issue', 'sibling_description', 'sibling_issue'];

async function save(boxes) {
  await t.go(PATH);
  for (const m of MACROS) await t.page.setChecked(`#settings_enable_${m}_macro`, boxes[m] !== false);
  await t.page.setChecked('#settings_enable_macro_debug_messages', boxes.debug !== false);
  await t.page.click('#settings-form input[type=submit], form input[name=commit]');
  await t.settle();
  t.check('save settings');
}

await t.login('admin');
t.currentUser = 'admin';
await t.sudo();
await t.go(PATH);
await t.shot('defaults', 'Admin: plugin settings, a checkbox per macro and one for the debug messages, all on');
for (const m of MACROS) expect(t, await t.page.isChecked(`#settings_enable_${m}_macro`), `${m} should be on by default`);

await save({ parent_issue: false, child_issue: false });
await t.sudo();
await t.shot('saved', 'After saving with parent_issue and child_issue off');
await checkIssue(t, { subject: 'DM A feature', user: 'admin', has: ['{{parent_issue}}', 'parent_description:', 'Parent description with bold text.'], hasNot: ['parent_issue: Bug #'],
  shot: 'parent-issue-off', caption: 'parent_issue off: the macro text stays as it was typed, the other macros still work' });
await checkIssue(t, { subject: 'DM B parent', user: 'admin', has: ['{{child_issue(Feature)}}', 'Child feature description text.'],
  shot: 'child-issue-off', caption: 'child_issue off: left as typed, child_description still works' });

await save({ parent_description: false, sibling_description: false, child_description: false });
await checkIssue(t, { subject: 'DM A feature', user: 'admin', has: ['{{parent_description}}', '{{sibling_description(Support)}}', 'parent_issue: Bug #'],
  shot: 'description-off', caption: 'The three description macros off, the issue macros on again' });

await save({ debug: false });
await checkIssue(t, { subject: 'DM loop child', user: 'admin', hasNot: ['recursive loop', 'not initialized'],
  shot: 'debug-off', caption: 'Debug messages off: the loop notice is not shown (empty description)' });
await checkIssue(t, { subject: 'DM lonely', user: 'admin', has: ['no parent found'],
  shot: 'debug-off-lonely', caption: 'Debug messages off: functional messages ("no parent found") stay' });

await save({});
await checkIssue(t, { subject: 'DM loop child', user: 'admin', has: ['recursive loop detected'],
  shot: 'restored', caption: 'Everything on again: the loop notice is back' });

await t.login('manager');
await t.go(PATH, { status: 403 });
await t.shot('manager-refused', 'Failure path: a project manager (not admin) is refused the settings page');
await t.login('reporter');
await t.go(PATH, { status: 403 });
await t.shot('reporter-refused', 'Failure path: reporter refused');
await t.anonymous();
await t.go(PATH, { status: 200 }).catch(() => {});
await t.shot('anonymous', 'Failure path: anonymous is sent to the login form');
if (!/\/login/.test(t.page.url())) t.problems.push(`anonymous ended on ${t.page.url()}`);
await t.done();
