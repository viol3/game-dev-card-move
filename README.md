# ays::game_dev_card — API reference (source: `gamedevcard.move`)

This document summarizes the public structs and entry functions defined in
`gamedevcard.move` and explains their parameters, behaviour and important
constraints. It focuses only on the functions and types used by the
frontend/backend integration.

Module: `ays::game_dev_card`

## Summary

- Provides a simple profile object (`GameDevCardProfile`) which holds a
  collection of games. Each game is a separate on-chain object (`GameItem`).
- Uses a shared `DonkeySaddle` object as the namespace for dynamic fields
  (profile lookup by username).

## Key structs

- `DonkeySaddle` (has key)
  - Fields: `id: UID`
  - Purpose: A globally shared object used as the root for dynamic fields
    (acts like a registry / name-index). Call `init_saddle` once to create and
    share it.

- `GameItem` (has key, store)
  - Fields: `id: UID`, `game_name: String`, `game_link: String`,
    `description: String`, `image_url: String`, `platform: String`
  - Purpose: Each game is represented by a distinct on-chain object. Because
    `GameItem` has the `key` ability, it must be deleted explicitly (see
    `remove_game`).

- `GameDevCardProfile` (has key, store)
  - Fields: `id: UID`, `name: String`, `games: vector<ID>`
  - Purpose: Profile object that stores user name and a vector of game IDs
    (the object IDs for `GameItem`s). Note: only IDs are stored in the
    profile's `games` vector (not embedded objects).

## Important entry functions

### `init_saddle(ctx: &mut TxContext)`
Creates a new `DonkeySaddle` object and calls `transfer::share_object` to
make it shareable. Call once during initialization.

### `create_game_dev_profile(name: String, saddle: &mut DonkeySaddle, ctx: &mut TxContext)`

- Creates a new `GameDevCardProfile` with the provided `name` and an empty
  `games` vector.
- Validations:
  - `name` length must be between 3 and 40 characters. Fails with codes
    `1` (too short) or `2` (too long).
  - Asserts that `df::exists_(&saddle.id, name) == false` (error code `99`)
    so duplicate usernames are prevented.
- Behaviour:
  - Adds the profile id into dynamic fields under the saddle with
    `df::add(&mut saddle.id, name, profile_id)`.
  - Transfers the created profile to the transaction sender.

### `add_game(mut profile: GameDevCardProfile, game_name: String, game_link: String, description: String, image_url: String, platform: String, ctx: &mut TxContext)`

- Adds a new game to the provided `profile`.
- Validations (each throws with distinct error codes):
  - `game_name` length [3,250] (codes 1/2)
  - `game_link` length [3,1000] (codes 3/4)
  - `description` length [3,1000] (codes 5/6)
  - `image_url` length [10,1000] (codes 7/8)
  - `platform` length [1,250] (codes 9/10)
- Behaviour:
  - Creates a `GameItem` object (`object::new(ctx)`) and obtains its inner
    UID via `object::uid_to_inner(&new_game.id)`.
  - Pushes the new game's ID into `profile.games` (a `vector<ID>`).
  - Transfers the modified profile and the newly created `GameItem` to the
    transaction sender. The `GameItem` becomes a standalone on-chain object.

### `update_profile_name(mut profile: GameDevCardProfile, new_name: String, ctx: &mut TxContext)`

- Updates `profile.name` to `new_name`.
- Validations: `new_name` length [3,40] (codes 100/101).
- Behaviour: transfers the updated profile back to the sender.

### `update_game(mut profile: GameDevCardProfile, mut game_to_update: GameItem, game_name: String, game_link: String, description: String, image_url: String, platform: String, ctx: &mut TxContext)`

- Updates fields of an existing `GameItem` and ensures the game ID is
  present in the `profile.games` vector.
- Validations: similar length checks as `add_game` (same error codes 1..10).
- Checks that the `game_to_update` id exists in `profile.games`; if not,
  assertion fails with code `202`.
- Behaviour: updates the `GameItem` fields and transfers both the profile
  and the updated `GameItem` to the sender.

### `remove_game(mut profile: GameDevCardProfile, game: GameItem, ctx: &mut TxContext)`

- Removes a `GameItem` from a profile and deletes the `GameItem` object.
- Behaviour:
  - Retrieves the target object's ID with `object::id(&game)`.
  - Deconstructs the `GameItem` and calls `object::delete(id)` to delete
    the on-chain object (required because `GameItem` has `key`).
  - Iterates `profile.games` and swap-removes the matching ID.
  - Transfers the updated `profile` back to the sender.

## Notes & implementation details

- Dynamic fields: the module uses `sui::dynamic_field` (`df`) to map usernames
  (strings) to profile IDs. The `DonkeySaddle` object acts as the root for
  those dynamic fields. `df::exists_(&saddle.id, name)` checks for an
  existing username; `df::add(&mut saddle.id, name, profile_id)` registers a
  new mapping.
- Object IDs vs UIDs: `GameDevCardProfile.games` stores `ID` values (object
  addresses). When creating a `GameItem`, the code obtains its inner UID with
  `object::uid_to_inner(&new_game.id)` and stores that in the profile's vector.
- Deletion: Because `GameItem` has the `key` ability, it is deleted with
  `object::delete(id)` instead of being dropped. The profile's vector is
  updated using `vector::swap_remove` to remove the ID efficiently.

## Usage examples (Move calls)

Initialize saddle (admin / one-time):

```move
Script::init_saddle();
```

Create profile (user transaction):

```move
Script::create_game_dev_profile("alice".to_string(), &mut saddle_ref);
```

Add a game to a profile:

```move
Script::add_game(profile_obj, "My Game".to_string(), "https://...".to_string(), "A fun game".to_string(), "https://.../cover.png".to_string(), "web".to_string());
```

Update a game's metadata (pass the `GameItem` object and profile):

```move
Script::update_game(profile_obj, game_obj, "New Name".to_string(), ...);
```

Remove a game (deletes the `GameItem` object):

```move
Script::remove_game(profile_obj, game_obj);
```

## Error codes

- The module embeds numeric error codes in assertions; when an assertion
  fails the transaction aborts with the provided numeric code. See each
  function's validation section above for codes and their meaning.

## License / Authors

- Source: `gamedevcard.move` in this repository.
