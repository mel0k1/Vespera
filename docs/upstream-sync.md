# Vespera and upstream Horizon

Vespera is a fork of [horizon-rust/horizon](https://github.com/horizon-rust/horizon): the native
Rust rewrite of Minecraft and its launcher. Horizon's engine work — the renderer, the protocol,
the 281 vanilla-parity tests — arrives there first, so Vespera tracks upstream and rides those
fixes. This document says how the fork stays open to their updates without giving up its own.

## How this repo stays mergeable

**The history is real.** Vespera's commits sit directly on top of Horizon's own history (no
squashed import), so `git merge upstream/main` is an ordinary three-way merge with a common
ancestor. Most upstream updates merge with no conflicts at all.

**Vespera's work lives in Vespera's files.** Upstream never edits these, so they never conflict:

- `launcher/src/dock.rs` — the floating dock that replaced the top bar
- the icon set, the README banner, `docs/upstream-sync.md` (this file)
- `README.md`'s Vespera sections and this fork's roadmap

**The touch points on upstream files are small and known.** When upstream changes one of these,
the merge may conflict; the fix is always to reapply our one-line intent:

| File | Vespera's change |
|---|---|
| `launcher/src/main.rs` | the render tree hosts the dock instead of the top bar; page bottom padding 92 (was 48) |
| `launcher/src/switch_page.rs` | the account menu opens over the chip (the dock sits at the bottom) |
| `launcher/src/titlebar.rs` | the drag-region brand says "Vespera" |
| `crates/horizon-release-sign/release-keys.txt` | our signing key, not Horizon's |
| `.github/CODEOWNERS` | our maintainer reviews |
| `launcher/links.json` | our download and website addresses |

**Conflict policy, one sentence each:** engine and game code — take theirs. Vespera identity
(keys, branding, links, docs) — keep ours. Where both touched the same lines (the top bar area),
reapply the small Vespera diff on top of their version.

**The engine contracts stay intact.** Vespera does not rename the `horizon-*` crates, the
`horizon-client` / `horizon-server` / `horizon-ctl` binaries, the `HORIZON_*` environment
variables or the log strings the launcher parses. Upstream refactors of those keep applying
cleanly; Vespera's surface sits beside them, not under them.

## Syncing

By hand, or let the workflow do it:

```sh
git remote add upstream https://github.com/horizon-rust/horizon.git
git fetch upstream main
git merge upstream/main
# resolve per the policy above, then push
```

The `sync upstream` workflow (`.github/workflows/sync-upstream.yml`) merges `upstream/main`
every Monday and on demand: a clean merge pushes to `main`, dispatches the `checks` workflow and
opens nothing; a conflicted merge aborts and opens an issue listing the files.

A note on CI triggers: upstream's `ci.yml` push filter matches a branch named `ain]` (theirs
runs on pull requests and through the release crons instead), so a plain push to `main` starts
no checks in this fork either. The sync workflow dispatches `checks` after every clean merge;
for your own pushes, run it once from the Actions tab, or fix the filter to `[main]` knowing
that one-character diff will reappear in future merges.

## Vespera's future features and where they slot in

**Playing without a licensed copy in the loop.** Offline names already exist
(`Accounts::offline`, `Player::Offline` in `launcher/src/account.rs`), and the launcher prepares
the game only from the player's own copy. What keeps offline play tied to a licensed account
today is the owner gate: `OFFLINE_NEEDS_OWNER` and `Launch`'s `owner` requirement in
`account.rs`, surfaced by `owner_page.rs`. A later Vespera build relaxes that gate at those two
spots; upstream rarely touches them, so the change survives merges. New account kinds go
through the `Player` enum — never a parallel auth path.

**The launcher stays on GPUI.** No port is planned. Vespera's interface work happens in its own
files (`dock.rs` and friends) so upstream's layout keeps merging underneath.

**Releases and keys.** Vespera signs with its own Ed25519 key (the `release` environment's
`RELEASE_SIGNING_KEY`; the public half is in `release-keys.txt`). Rotation: generate a pair,
append the public key as a second line, set the private half as `RELEASE_SIGNING_KEY_NEXT`,
release once, then swap the two secrets.
