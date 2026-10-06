import { e2e } from '../../.codex/e2e/lib.mjs';
import { checkIssue } from '../e2e_helpers/helpers.mjs';
const t = await e2e('child_description');
const subject = 'DM B parent';

await checkIssue(t, { subject, user: 'manager', has: ['child_description:', 'Child feature description text.', 'SECRET description of a private child.', 'no children found of tracker Support'],
  shot: 'manager', caption: 'Manager: description of the Feature child, the private Bug child, and the no-match message' });
await checkIssue(t, { subject, user: 'reporter', has: ['Child feature description text.', 'no children found of tracker Bug'], hasNot: ['SECRET'],
  shot: 'reporter', caption: 'Reporter: the private child is skipped' });
await checkIssue(t, { subject, user: 'outsider', has: ['Child feature description text.'], hasNot: ['SECRET'],
  shot: 'outsider', caption: 'Non-member on a public project: same as reporter, nothing leaks' });
await checkIssue(t, { subject, user: 'reporter', has: ['tracker name should be given as argument to macro child_description'],
  shot: 'no-argument', caption: 'Failure path: no argument' });
await t.done();
