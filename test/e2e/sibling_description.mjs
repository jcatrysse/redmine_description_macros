import { e2e } from '../../.codex/e2e/lib.mjs';
import { checkIssue } from '../e2e_helpers/helpers.mjs';
const t = await e2e('sibling_description');
const subject = 'DM A feature';

await checkIssue(t, { subject, user: 'manager', has: ['sibling_description:', 'Support sibling description text.', 'SECRET description of a private sibling.'],
  shot: 'manager', caption: 'Manager: description of the sibling of tracker Support; the private Bug sibling is visible to a manager' });
await checkIssue(t, { subject, user: 'reporter', has: ['Support sibling description text.', 'no sibling found of tracker Bug'], hasNot: ['SECRET'],
  shot: 'reporter', caption: 'Reporter: the private sibling is skipped, nothing leaks' });
await checkIssue(t, { subject, user: 'reporter', has: ['tracker name should be given as argument to macro sibling_description'],
  shot: 'no-argument', caption: 'Failure path: macro without tracker argument names the macro' });
await checkIssue(t, { subject: 'DM lonely', user: 'manager', has: ['no sibling found of tracker Bug'],
  shot: 'no-parent', caption: 'Failure path: issue without parent has no siblings' });
await t.done();
