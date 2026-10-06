// Shared by the scenarios: finds the seeded "DM ..." issues through the REST API.
import { BASE } from '../../.codex/e2e/lib.mjs';

export async function issueId(t, subject) {
  const auth = 'Basic ' + Buffer.from(`admin:${process.env.RMP_ADMIN_PASSWORD || 'Redmine7Test!'}`).toString('base64');
  const res = await t.page.request.get(`${BASE}/issues.json?status_id=*&subject=${encodeURIComponent(subject)}`,
    { headers: { Authorization: auth } });
  const body = await res.json();
  const hit = body.issues.find(i => i.subject === subject);
  if (!hit) throw new Error(`seeded issue not found: ${subject}`);
  return hit.id;
}

// Text of the issue description as rendered.
export async function description(t) {
  return (await t.page.locator('div.issue div.description .wiki').first().innerText());
}

export function expect(t, ok, message) {
  if (!ok) t.problems.push(message);
}

// Logs in (once per user change), opens the issue and checks its rendered description:
// every string in `has` must be there, none of `hasNot`. Takes the screenshot.
export async function checkIssue(t, { user, subject, has = [], hasNot = [], shot, caption }) {
  if (user && user !== t.currentUser) { await t.login(user); t.currentUser = user; }
  await t.go(`/issues/${await issueId(t, subject)}`);
  const text = await description(t);
  for (const s of has) expect(t, text.includes(s), `${subject} as ${user}: expected "${s}" in:\n${text}`);
  for (const s of hasNot) expect(t, !text.includes(s), `${subject} as ${user}: "${s}" must not be shown in:\n${text}`);
  await t.shot(shot, caption);
  return text;
}

// Text of the (asynchronously loaded) wiki preview once it is there.
export async function previewText(t) {
  const el = t.page.locator('div.wiki-preview:visible').last();
  await t.page.waitForFunction(() => [...document.querySelectorAll('div.wiki-preview')].some(e => e.offsetParent && e.innerText.trim()), null, { timeout: 10000 }).catch(() => {});
  return el.innerText().catch(() => '');
}
