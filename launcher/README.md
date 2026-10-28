# Vespera launcher

A small desktop app that installs Vespera builds, prepares them from your own copy of
Minecraft, and starts the client or a dedicated server. Built with [GPUI](https://www.gpui.rs),
Zed's UI framework; it has its own Cargo workspace and is not part of the game's builds.

Vespera is a fork of [Horizon](https://github.com/horizon-rust/horizon): the launcher carries
the Vespera name, icon, twilight-violet theme and release channel
([mel0k1/Vespera](https://github.com/mel0k1/Vespera)); the engine crates keep their
`horizon-*` names and the game it installs is Horizon's native Rust client.

## What it does

- **Versions**: lists the published releases of mel0k1/Vespera, installs the build for
  this platform into its own folder, and removes it again.
- **Play**: prepares resources from your own copy of Minecraft (or downloads the pinned
  version from Mojang for an account that owns the game), then starts the client.
- **Mods**: search Modrinth for resource packs and modpacks, SHA-512 checked, marked
  *Works*, *Partly* or *Doesn't run*.
- **Modpacks**: import a Modrinth `.mrpack`, a CurseForge zip or a Prism/MultiMC instance
  folder, see a per-mod coverage report, and play the ported pack as its own profile.
- **Servers**: host a world with buttons — create, start, stop, back up, update, a console,
  and friends over the internet through Tailscale, all through `horizon-server` itself.
- **Instances**: separate game folders with their own worlds, options and packs, launch
  options, play time, and export to `.mrpack` or a zip. Drop a file anywhere to import it.
- **Agents**: a CLI and an MCP server (`vespera-launcher mcp`) that drive the launcher;
  `horizon-ctl` plays the game.
- **Self-update**: from this repository, through signed release checksums.

The user-facing documentation lives in [the root README](../README.md) and in
[docs/](../docs/). Horizon's full launcher feature list:
[the upstream launcher README](https://github.com/horizon-rust/horizon/blob/main/launcher/README.md).
