---
name: nakama-server-modules
description: "Expert guidance for Nakama server-side module development using the JavaScript runtime. Use when writing or modifying Nakama runtime modules in the nakama/ folder — RPC handlers, Before/After hooks, user account management, storage reads/writes, and wallet updates. Trigger keywords: InitModule, registerRpc, registerReqBefore, registerReqAfter, authenticate, storageWrite, walletUpdate, account, metadata, module."
---

# Nakama Server Modules

> **Preferred runtime:** JavaScript. Nakama also supports Lua and Go — Lua notes are included where the API shape differs.

## Module Loading

Every JavaScript module exports an `InitModule` function, which Nakama calls once at startup.

```javascript
// All nk APIs are injected — do not import or require anything.
function InitModule(ctx, logger, db, nk, initializer) {
    initializer.registerRpc('my_rpc', myRpcHandler);
    initializer.registerReqBefore('AuthenticateDevice', beforeAuthenticate);
    initializer.registerReqAfter('AuthenticateDevice', afterAuthenticate);
}
```

The file must end with the bare function declaration — no `module.exports`. Nakama discovers `InitModule` by name.

**Rules:**
- Register everything inside `InitModule`. Code at module scope runs at load time with no access to `nk`.
- RPC IDs passed to `registerRpc` must exactly match the string the client sends.
- Nakama injects `nk` into every handler — never cache or import it.

---

## Authentication Hooks

Use Before/After hooks to inject logic around Nakama's built-in auth endpoints.

```javascript
// Before hook — can modify or reject the request.
function beforeAuthenticate(ctx, logger, db, nk, request) {
    logger.info('Auth attempt: ' + (request.username ?? 'unknown'));
    return request;
}

// After hook — runs after auth succeeds; ctx.userId is now populated.
function afterAuthenticate(ctx, logger, db, nk, out, request) {
    nk.accountUpdateId(ctx.userId, null, null, null, null, null, null,
        JSON.stringify({ last_login: Date.now() }));
}
```

**Rules:**
- Before hooks return the (possibly mutated) request object. Throw an error to reject.
- After hooks receive the response object (`out`) in addition to the request — do not return a value.
- Session variables set inside a hook survive for the life of the session and are readable from `ctx.vars` in any subsequent RPC.

> **Lua note:** Lua hooks use `return nil` to reject; JS uses `throw`. Lua uses `ctx.user_id` (snake_case); JS uses `ctx.userId` (camelCase).

---

## User Accounts

```javascript
// Read account
const account = nk.accountGetId(userId);
const publicMeta  = JSON.parse(account.user.metadata);
const privateCustomId = account.customId;

// Update account fields (null = leave unchanged)
nk.accountUpdateId(
    userId,
    null,           // username
    null,           // displayName
    null,           // timezone
    null,           // location
    null,           // langTag
    null,           // avatarUrl
    JSON.stringify({ guild_rank: 'officer' })  // metadata (public)
);

// Wallet update (server-authoritative currency)
nk.walletUpdate(userId, { gold: 100, gems: -5 }, { reason: 'quest_reward' }, true);
```

**Rules:**
- `account.user.metadata` is public (visible to other users via the Users API).
- `account.customId` is server-only and not directly exposed to clients.
- Always use `nk.walletUpdate` for currency — never write currency into metadata.
- Pass `updateLedger: true` to keep an auditable transaction log.

---

## Storage Engine

```javascript
// Write
nk.storageWrite([{
    collection:      'player_data',
    key:             'settings',
    userId:          userId,
    value:           JSON.stringify({ sfx_volume: 0.8 }),
    version:         '*',
    permissionRead:  1,
    permissionWrite: 0,
}]);

// Read
const objects = nk.storageRead([
    { collection: 'player_data', key: 'settings', userId: userId }
]);
if (objects.length > 0) {
    const data = JSON.parse(objects[0].value);
}

// Delete
nk.storageDelete([{ collection: 'player_data', key: 'settings', userId: userId }]);
```

**Permission constants:**
| Value | Read | Write |
|-------|------|-------|
| 0 | Server-only | Server-only |
| 1 | Owner only | Owner only |
| 2 | Public read | — |

**Optimistic concurrency:**
- Pass `version: objects[0].version` on writes to enforce "only update if unchanged."
- Pass `version: '*'` to upsert unconditionally.
- A version mismatch throws — wrap with `try/catch`.

---

## RPC Handlers

```javascript
function getPlayerStats(ctx, logger, db, nk, payload) {
    const input = payload ? JSON.parse(payload) : {};
    const result = { level: 5, xp: 1200 };
    return JSON.stringify(result);
}

// In InitModule:
initializer.registerRpc('get_player_stats', getPlayerStats);
```

**Rules:**
- Wrap external calls in `try/catch`; uncaught errors return a 500 to the client.
- Return a JSON string — `JSON.stringify(obj)`, not a plain object.
- Guard against empty payload: `payload ? JSON.parse(payload) : {}`.
