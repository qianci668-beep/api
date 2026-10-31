import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import { createDecipheriv, createHash } from 'node:crypto';
import { join } from 'node:path';

const home = join(process.env.USERPROFILE, '.agent2api');
const db = new DatabaseSync(join(home, 'agent2api.db'), { readOnly: true });
const get = key => db.prepare('SELECT value FROM kv WHERE key = ?').get(key)?.value;
const rawKeys = get('apiKeys');
const settings = JSON.parse(get('desktopSettings'));
const keys = JSON.parse(rawKeys);
const accountCount = db.prepare('SELECT count(*) AS count FROM accounts').get().count;
db.close();
const secret = readFileSync(join(home, 'account.key'));
function open(value) {
  if (!value.startsWith('enc1:')) return value;
  const blob = Buffer.from(value.slice(5), 'base64');
  const cipher = createDecipheriv('aes-256-gcm', secret, blob.subarray(0, 12));
  cipher.setAuthTag(blob.subarray(-16));
  return Buffer.concat([cipher.update(blob.subarray(12, -16)), cipher.final()]).toString();
}
const access = open(settings.panelSession.access);
const result = {
  accountCount,
  keyCount: keys.length,
  keysDigest: createHash('sha256').update(rawKeys).digest('hex'),
  sessionDigest: createHash('sha256').update(access).digest('hex'),
  management: {},
};
for (const endpoint of ['/api/accounts', '/api/stats/summary', '/api/sidebar-layout']) {
  const response = await fetch('http://127.0.0.1:3065' + endpoint, {
    headers: { 'x-panel-token': access }, signal: AbortSignal.timeout(10000),
  });
  result.management[endpoint] = response.status;
  await response.body?.cancel();
}
const restricted = keys.find(key => key.enabled && (key.allowedModels?.length || key.allowedProviders?.length));
if (restricted) {
  const response = await fetch('http://127.0.0.1:3065/api/accounts', {
    headers: { 'x-api-key': open(restricted.key) }, signal: AbortSignal.timeout(10000),
  });
  result.restrictedKeyManagementStatus = response.status;
  await response.body?.cancel();
}
console.log(JSON.stringify(result));
