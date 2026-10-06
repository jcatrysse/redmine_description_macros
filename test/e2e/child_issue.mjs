import { e2e } from '../../.codex/e2e/lib.mjs';
import { checkIssue } from '../e2e_helpers/helpers.mjs';
const t = await e2e('child_issue');
const subject = 'DM B parent';

await checkIssue(t, { subject, user: 'manager', has: ['child_issue: Feature #', 'DM B feature', 'E2E project - #', 'child_issue secret: Bug #', 'DM B secret'],
  shot: 'manager', caption: 'Manager: child link (lower case tracker), project=true tracker=false, and the private child' });
if (!(await t.page.locator('div.description .wiki a.issue').count())) t.problems.push('child link lost its a.issue class');
await checkIssue(t, { subject, user: 'reporter', has: ['child_issue: Feature #', 'no children found of tracker Bug'], hasNot: ['DM B secret'],
  shot: 'reporter', caption: 'Reporter: private child not linked (was a leak)' });
await checkIssue(t, { subject, user: 'outsider', has: ['DM B feature'], hasNot: ['DM B secret'],
  shot: 'outsider', caption: 'Non-member: same' });
await checkIssue(t, { subject, user: 'reporter', has: ['tracker name should be given as argument to macro child_issue'],
  shot: 'no-argument', caption: 'Failure path: no argument' });
await t.done();
