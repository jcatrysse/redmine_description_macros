import { e2e } from '../../.codex/e2e/lib.mjs';
import { checkIssue } from '../e2e_helpers/helpers.mjs';
const t = await e2e('sibling_issue');
const subject = 'DM A feature';

await checkIssue(t, { subject, user: 'manager', has: ['sibling_issue: Support #', 'DM A support', 'E2E project - Support #', 'sibling_issue secret: Bug #', 'DM A secret'],
  shot: 'manager', caption: 'Manager: sibling link (tracker given in lower case), project=true variant, and the private sibling the manager may see' });
if (!(await t.page.locator('div.description .wiki a.issue').count())) t.problems.push('sibling link lost its a.issue class');
await checkIssue(t, { subject, user: 'reporter', has: ['sibling_issue: Support #', 'no sibling found of tracker Bug'], hasNot: ['DM A secret'],
  shot: 'reporter', caption: 'Reporter: the private sibling is not linked (was a leak: its subject was shown)' });
await checkIssue(t, { subject, user: 'reporter', has: ['tracker name should be given as argument to macro sibling_issue'],
  shot: 'no-argument', caption: 'Failure path: no argument, message names sibling_issue (it named sibling_description before)' });
await checkIssue(t, { subject: 'DM lonely', user: 'manager', has: ['no sibling found'], shot: 'no-parent', caption: 'Failure path: no parent' });
await t.done();
