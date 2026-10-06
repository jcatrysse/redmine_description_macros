import { e2e } from '../../.codex/e2e/lib.mjs';
import { previewText, issueId, expect } from '../e2e_helpers/helpers.mjs';
const t = await e2e('macro_list');
const NAMES = ['child_description', 'child_issue', 'parent_description', 'parent_issue', 'sibling_description', 'sibling_issue'];

await t.login('manager');
await t.go('/projects/e2e-project/wiki/Wiki');
await t.go('/help/en/wiki_syntax_textile.html', { status: 404 }).catch(() => {});
// {{macro_list}} on a wiki page edit preview: use the preview endpoint through the edit form
await t.go('/projects/e2e-project/wiki/Macro_list_check/edit');
await t.page.fill('#content_text', '{{macro_list}}');
await t.page.click('a.tab-preview, #preview_content_text, a[href*="preview"]').catch(() => {});
await t.settle();
t.check('preview macro_list');
const preview = await previewText(t);
for (const n of NAMES) expect(t, preview.includes(n), `macro_list does not mention ${n}`);
await t.shot('macro-list', 'Manager: {{macro_list}} lists the six macros of the plugin with their descriptions');

// the settings page links the same hint
await t.login('admin');
await t.sudo();
await t.go('/settings/plugin/redmine_description_macros');
expect(t, (await t.page.locator('fieldset small').first().innerText()).includes('macro_list'), 'settings hint does not mention macro_list');
await t.shot('settings-hint', 'Settings page: the hint explains how to get the list of macros');
await t.done();
