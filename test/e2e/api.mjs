// REST API and webhooks: the plugin only changes how descriptions are rendered in
// HTML. The API (and core webhooks, which use the same issues/show.api.rsb) must
// keep delivering the description as typed, macros unexpanded.
import { e2e, BASE } from '../../.codex/e2e/lib.mjs';
import { issueId, expect } from '../e2e_helpers/helpers.mjs';
const t = await e2e('api');

await t.login('admin');
const auth = 'Basic ' + Buffer.from('admin:Redmine7Test!').toString('base64');
const id = await issueId(t, 'DM A feature');
const res = await t.page.request.get(`${BASE}/issues/${id}.json`, { headers: { Authorization: auth } });
expect(t, res.status() === 200, `API status ${res.status()}`);
const body = await res.json();
expect(t, body.issue.description.includes('{{parent_description}}'), 'API description should keep the macro unexpanded');
expect(t, !body.issue.description.includes('Parent description with bold'), 'API description must not contain expanded text');
console.log('API description starts:', JSON.stringify(body.issue.description.slice(0, 60)));
await t.page.goto(`${BASE}/issues/${id}.json`, { waitUntil: 'load' }).catch(() => {});
await t.page.setContent(`<pre style="font:13px monospace;white-space:pre-wrap">GET /issues/${id}.json (admin, Basic auth)\n\n${JSON.stringify({ id: body.issue.id, subject: body.issue.subject, description: body.issue.description }, null, 2).replace(/</g, '&lt;')}</pre>`);
await t.shot('api-json', 'REST API: the description is delivered as typed, macros unexpanded; webhooks use the same payload, so they are consistent and need no change');

const anon = await t.page.request.get(`${BASE}/issues/${await issueId(t, 'DM A secret')}.json`);
expect(t, anon.status() === 401 || anon.status() === 403 || anon.status() === 404, `anonymous API read of a private issue gave ${anon.status()}`);
await t.done();
