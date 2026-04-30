---
name: nakama-multiplayer
description: "Expert guidance for Nakama real-time multiplayer systems using the JavaScript runtime. Use when implementing authoritative match handlers, party management, or matchmaker integration in the nakama/ folder. Trigger keywords: matchInit, matchJoin, matchLoop, matchTerminate, matchCreate, parties, matchmaker, matchmakerMatched, registerMatchmakerMatched."
---

# Nakama Multiplayer

> **Preferred runtime:** JavaScript. Nakama also supports Lua and Go — Lua notes are included where the API shape differs.

## Authoritative Match Handlers

Authoritative matches run server-side. Implement six lifecycle functions and register them as a named match handler.

```javascript
const match = {
    matchInit(ctx, logger, db, nk, params) {
        const state = { players: {}, tick: 0, phase: 'waiting' };
        return { state, tickRate: 10, label: 'fiber_match' };
    },

    matchJoinAttempt(ctx, logger, db, nk, dispatcher, tick, state, presence, metadata) {
        const accept = Object.keys(state.players).length < 4;
        return { state, accept };
    },

    matchJoin(ctx, logger, db, nk, dispatcher, tick, state, presences) {
        for (const p of presences) {
            state.players[p.userId] = { username: p.username, ready: false };
        }
        return { state };
    },

    matchLoop(ctx, logger, db, nk, dispatcher, tick, state, messages) {
        state.tick = tick;
        for (const msg of messages) {
            const data = JSON.parse(nk.binaryToString(msg.data));
            // dispatch on data.opCode, data.payload
        }
        dispatcher.broadcastMessage(1, JSON.stringify({ tick, players: state.players }), null, null, true);
        return { state };
    },

    matchTerminate(ctx, logger, db, nk, dispatcher, tick, state, graceSeconds) {
        dispatcher.broadcastMessage(99, JSON.stringify({ reason: 'match_over' }), null, null, false);
        return { state };
    },

    matchLeave(ctx, logger, db, nk, dispatcher, tick, state, presences) {
        for (const p of presences) {
            delete state.players[p.userId];
        }
        return { state };
    },
};

// In InitModule:
initializer.registerMatch('fiber_match', match);
```

**Rules:**
- `matchLoop` is the hot path — avoid expensive calls (storage reads, account fetches) inside it; cache data in `state`.
- Return `null` from any handler to terminate the match immediately.
- `dispatcher.broadcastMessage(opCode, data, presences, sender, reliable)` — pass `null` for `presences` to broadcast to all; `null` for `sender` for server-originated messages.
- Op codes are integers agreed upon with the client; define them as named constants at the top of the file.

> **Lua note:** Lua uses `snake_case` function names (`match_init`, `match_loop`). Returns multiple values rather than an object.

---

## Parties

```javascript
function afterCreateParty(ctx, logger, db, nk, out, request) {
    logger.info('Party created: ' + out.partyId + ' by ' + ctx.userId);
}

function promotePartyLeader(ctx, logger, db, nk, payload) {
    const input = JSON.parse(payload);
    nk.partyLeaderPromote(input.partyId, {
        userId:    input.newLeaderId,
        sessionId: input.sessionId,
        node:      input.node,
    });
    return JSON.stringify({ ok: true });
}

// In InitModule:
initializer.registerReqAfter('CreateParty', afterCreateParty);
initializer.registerRpc('promote_party_leader', promotePartyLeader);
```

**Rules:**
- Max party size is set at creation and cannot be changed.
- Leader rotation must be handled explicitly — Nakama does not auto-promote on disconnect.
- Use party ID as a matchmaker ticket property to keep squads together.

---

## Matchmaker

```javascript
function onMatchmakerMatched(ctx, logger, db, nk, matches) {
    const matchId = nk.matchCreate('fiber_match', { matchedUsers: matches });
    return matchId;
}

function joinMatchmaker(ctx, logger, db, nk, payload) {
    const input = payload ? JSON.parse(payload) : {};
    const ticket = nk.matchmakerAdd(
        ctx.userId,
        ctx.sessionId,
        '+properties.mode:pvp',
        2,                         // min count
        4,                         // max count
        { mode: 'pvp' },
        { skill: input.skillRating ?? 1000 }
    );
    return JSON.stringify({ ticket });
}

// In InitModule:
initializer.registerMatchmakerMatched(onMatchmakerMatched);
initializer.registerRpc('join_matchmaker', joinMatchmaker);
```

**Query syntax cheatsheet:**
| Pattern | Meaning |
|---------|---------|
| `+properties.mode:pvp` | Must have mode = pvp |
| `+properties.skill:>=900 +properties.skill:<=1100` | Skill within range |
| `+properties.mode:pvp properties.region:eu` | Mode required, region preferred |

**Rules:**
- Returning a match ID from the hook routes all matched players there — returning `null` cancels this matched set and returns players' tickets to the pool.
- For squad matchmaking, submit one ticket per party with `partyId` in string properties.
- `ctx.sessionId` is only populated when the RPC is called from a connected client session.
