import { e2e } from '../../.codex/e2e/lib.mjs';
import { checkIssue } from '../e2e_helpers/helpers.mjs';
const t = await e2e('parent_description');
const base = { subject: 'DM A feature' };

await checkIssue(t, { ...base, user: 'manager', has: ['parent_description:', 'Parent description with bold text.'],
  shot: 'manager', caption: 'Manager: the description of the parent is inserted, formatted (bold)' });
const bold = await t.page.locator('div.description .wiki strong, div.description .wiki em', { hasText: 'bold' }).count();
if (!bold) t.problems.push('parent description is not formatted');
await checkIssue(t, { ...base, user: 'reporter', has: ['Parent description with bold text.'],
  shot: 'reporter', caption: 'Reporter (no plugin permissions exist): same result' });
await checkIssue(t, { subject: 'DM lonely', user: 'manager', has: ['no parent found'],
  shot: 'no-parent', caption: 'Failure path: issue without a parent shows "no parent found"' });
await checkIssue(t, { subject: 'DM private parent child', user: 'reporter', has: ['parent not visible'], hasNot: ['SECRET'],
  shot: 'parent-private-reporter', caption: 'Failure path: a parent the user may not see shows "parent not visible", no content' });
await checkIssue(t, { subject: 'DM private parent child', user: 'manager', has: ['SECRET description of a private parent.'],
  shot: 'parent-private-manager', caption: 'Manager may see the private parent, so its description is inserted' });
await t.done();
