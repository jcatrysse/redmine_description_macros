import { e2e } from '../../.codex/e2e/lib.mjs';
import { previewText, issueId, expect } from '../e2e_helpers/helpers.mjs';
const t = await e2e('note');

await t.login('manager');
await t.go(`/issues/${await issueId(t, 'DM note issue')}`);
const journal = await t.page.locator('#history .journal .wiki').first().innerText();
expect(t, journal.includes('DM note parent') && journal.includes('Description of the parent seen from a note.'),
  `macros in a note are not expanded to their issue:\n${journal}`);
await t.shot('note-seeded', 'Note with {{parent_issue}} and {{parent_description}}: both resolve through the journal to its issue');

// create a note through the form, with a macro on a plain-text field of another kind
await t.go(`/issues/${await issueId(t, 'DM note issue')}/edit`);
await t.page.fill('#issue_notes', 'Fresh note {{parent_issue(tracker=false)}}');
await t.page.click('#issue-form input[name=commit]');
await t.settle();
t.check('add note');
const notes = await t.page.locator('#history .journal .wiki').allInnerTexts();
expect(t, notes.some(n => n.includes('Fresh note #') && n.includes('DM note parent')), `fresh note not expanded:\n${notes.join('\n---\n')}`);
await t.shot('note-created', 'A note typed through the form: the macro is expanded in the saved note');

// preview of a note
await t.go(`/issues/${await issueId(t, 'DM note issue')}/edit`);
await t.page.fill('#issue_notes', 'Preview {{parent_description}}');
await t.page.locator('.jstTabs >> text=Preview').last().click();
await t.settle();
const prev = await previewText(t);
expect(t, prev.includes('Description of the parent seen from a note.'), `preview does not expand the macro: "${prev}"`);
await t.shot('note-preview', 'Preview of a note: the macro is expanded (the preview has no journal yet, so the issue comes from the form)');
await t.done();
