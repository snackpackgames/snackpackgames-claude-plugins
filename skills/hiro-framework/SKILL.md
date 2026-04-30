---
name: hiro-framework
description: "Expert guidance for the Hiro framework layered on top of Nakama. Use when implementing or extending Hiro economy, inventory, energy, progression, or base-building systems in the nakama/ folder. Trigger keywords: hiro, economy, inventory, energy, base builder, unlockables, leaderboards, achievements, InitModule hiro."
---

# Hiro Framework

Hiro is a game framework that runs as a compiled Go plugin inside the Nakama process. It provides pre-built systems (economy, inventory, progression, base building) exposed as Nakama RPCs and storage objects.

Reference: https://heroiclabs.com/docs/hiro/

> **Runtime requirement:** Hiro server modules **must be written in Go** — Hiro is a Go binary plugin and has no JavaScript or Lua server-side API. The project prefers JS for general Nakama modules, but any file that calls Hiro APIs must be a Go module.

---

## Module Registration

Hiro is initialized in `InitModule`. It returns a `systems` object that holds references to all configured Hiro sub-systems.

```go
func InitModule(ctx context.Context, logger runtime.Logger, db *sql.DB,
    nk runtime.NakamaModule, initializer runtime.Initializer) error {

    systems, err := hiro.Init(ctx, logger, db, nk, initializer,
        "hiro.bin",     // platform binary (hiro-linux-arm64.bin on Linux)
        os.Getenv("HIRO_LICENSE"),
        hiro.WithEconomySystem("economy.json", true),
        hiro.WithInventorySystem("inventory.json", true),
        hiro.WithEnergySystem("energies.json", true),
    )
    if err != nil {
        return err
    }

    // Register extension hooks on the returned systems object
    systems.GetEconomySystem().SetOnStoreItemReward(onStoreItemReward)
    systems.GetInventorySystem().SetOnConsumeReward(onConsumeReward)

    return nil
}
```

**Rules:**
- `hiro.Init` takes the binary path (platform-specific filename), a license key, and `With*System` option calls — not a plain config struct.
- Always pass the binary path as a relative filename; Nakama resolves it relative to the data directory.
- Store the `systems` return value in a package-level variable if you need to call Hiro APIs from custom RPCs registered separately.

---

## Economy

Hiro's economy system manages currencies, store purchases, and donation mechanics.

```go
// Access the economy system
economy := systems.GetEconomySystem()

// Grant currency
_, _, err = economy.Grant(ctx, logger, nk, userID,
    map[string]int64{"gold": 100},   // currencies
    nil,                              // items
    nil,                              // energies
    nil,                              // event
)

// Store purchase
_, _, _, err = economy.PurchaseItem(ctx, logger, nk, userID, "sword_01", 1)
```

**Config shape (economy.json excerpt):**
```json
{
  "initialize_user": {
    "currencies": { "gold": 100, "gems": 0 },
    "items": {}
  },
  "store_items": {
    "sword_01": {
      "name": "Iron Sword",
      "category": "weapon",
      "cost": { "currencies": { "gold": 50 } },
      "reward": { "guaranteed": { "items": {} } }
    }
  }
}
```

**Rules:**
- Always use `economy.Grant` for currency — do not call `nk.WalletUpdate` directly on currencies Hiro manages.
- Store items are keyed directly at the top level of `store_items` (not nested under a store name).
- Initial currencies go inside `initialize_user.currencies` as a flat `name: amount` map, not objects with an `initial_amount` field.

---

## Inventory

Hiro manages item stacks, instance data, and item grants through a unified inventory system.

```go
inv := systems.GetInventorySystem()

// Grant items
_, err = inv.GrantItems(ctx, logger, nk, userID,
    []*hiro.InventoryGrantItem{{ItemID: "sword_01", Count: 1}},
    false, // ignoreLimits
)

// List items
items, err := inv.List(ctx, logger, nk, userID, "weapon")
```

**Config shape (inventory.json excerpt):**
```json
{
  "items": {
    "sword_01": {
      "name":        "Iron Sword",
      "description": "A basic iron sword.",
      "category":    "weapon",
      "stackable":   false,
      "max_count":   1,
      "string_properties": {},
      "numeric_properties": {}
    }
  }
}
```

**Rules:**
- Non-stackable items get unique instance IDs from Hiro — do not manage instance IDs manually.
- For fiber-specific item data (affixes, rolls), write them to Nakama storage keyed by the Hiro-assigned instance ID, retrieved via `inv.List`.
- Use `string_properties` and `numeric_properties` in the item config for static per-item metadata; use storage for mutable per-instance data.

---

## Energy

Energy gates time-limited actions (dungeon attempts, crafting slots).

```go
energySys := systems.GetEnergySystem()

// Spend energy (returns updated energies or error if insufficient)
energies, _, err := energySys.Spend(ctx, logger, nk, userID,
    map[string]int32{"stamina": 1},
)
if err != nil {
    // Insufficient energy — err is non-nil
    return nil, err
}
```

**Config shape (energies.json excerpt):**
```json
{
  "energies": {
    "stamina": {
      "start_count":    5,
      "max_count":      5,
      "max_overfill":   3,
      "refill_count":   1,
      "refill_time_sec": 600
    }
  }
}
```

**Rules:**
- Config uses **snake_case** field names: `start_count`, `max_count`, `refill_time_sec` — not camelCase.
- `Spend` returns an error when energy is insufficient — check `err`, not a `success` field.
- Grant bonus energy via `energySys.Grant(ctx, logger, nk, userID, map[string]int32{"stamina": 2})`.

---

## Extending Hiro with Custom Logic

Register hook setters on the system objects returned by `hiro.Init`, before returning from `InitModule`.

```go
// Called after any store purchase reward is computed — can modify the reward.
func onStoreItemReward(ctx context.Context, logger runtime.Logger,
    nk runtime.NakamaModule, userID, sourceID string,
    source *hiro.EconomyConfigStoreItem,
    rewardConfig *hiro.EconomyConfigReward,
    reward *hiro.Reward) (*hiro.Reward, error) {

    // e.g., add a guild shop bonus
    if sourceID == "guild_sword" {
        reward.Currencies["gold"] += 10
    }
    return reward, nil
}

// Called after an inventory item is consumed — can add side-effect rewards.
func onConsumeReward(ctx context.Context, logger runtime.Logger,
    nk runtime.NakamaModule, userID string,
    items []*hiro.InventoryItem, reward *hiro.Reward,
    rewardConfig *hiro.EconomyConfigReward) (*hiro.Reward, error) {
    return reward, nil
}

// In InitModule, after hiro.Init:
systems.GetEconomySystem().SetOnStoreItemReward(onStoreItemReward)
systems.GetInventorySystem().SetOnConsumeReward(onConsumeReward)
```

**Rules:**
- Hooks are registered via `Set*` methods on the system objects — not on a top-level `hiro` global.
- Always call `Set*` hooks after `hiro.Init` and before returning from `InitModule`.
- Hook functions must return the (possibly modified) reward and a Go error — return `nil` error on success.
- Do not call `inv.GrantItems` inside an inventory consume hook — it causes unbounded re-triggering.
