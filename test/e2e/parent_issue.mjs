import { e2e } from '../../.codex/e2e/lib.mjs';
import { checkIssue } from '../e2e_helpers/helpers.mjs';
const t = await e2e('parent_issue');

await checkIssue(t, { subject: 'DM A feature', user: 'manager', has: ['parent_issue: Bug #', 'DM A parent', 'parent_issue short: E2E project - #'],
  shot: 'manager', caption: 'Manager: link to the parent, and the project=true tracker=false subject=false variant' });
const link = t.page.locator('div.description .wiki a.issue').first();
if (!(await link.count())) t.problems.push('the parent link is not an a.issue (class lost)');
else if (!/\/issues\/\d+$/.test(await link.getAttribute('href'))) t.problems.push('parent link has a wrong href');
await checkIssue(t, { subject: 'DM lonely', user: 'manager', has: ['no parent found'],
  shot: 'no-parent', caption: 'Failure path: no parent' });
await checkIssue(t, { subject: 'DM private parent child', user: 'reporter', has: ['parent not visible'], hasNot: ['DM private parent', 'Bug #'],
  shot: 'parent-private-reporter', caption: 'Failure path (was a leak): invisible parent no longer shows its number or subject' });
await checkIssue(t, { subject: 'DM private parent child', user: 'manager', has: ['DM private parent'],
  shot: 'parent-private-manager', caption: 'Manager sees the link to the private parent' });
await t.done();
