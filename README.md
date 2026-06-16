# mac-security — check your Mac for supply-chain malware

A small, **read-only** macOS health check that scans your machine for signs of the **PolinRider /
Contagious-Interview** npm supply-chain worm (and general compromise), writes a dated report, and
notifies you **only when something looks wrong**. It never installs, builds, lints, or runs your
project code — it only reads (`grep` / `git log` / `gh`). Built for the MadhavTech team; useful for
any macOS developer.

> Anyone can install it — this tap and its install asset are **public**. (The source repo, incident
> notes, and internal allowlist stay private in `sidvekariya510/mac-security`.)

## Requirements
- macOS (Apple Silicon or Intel)
- [Homebrew](https://brew.sh) — if you don't have it, install it first (review the script at the link).

## Install (once)
```bash
brew tap sidvekariya510/mac-security
brew trust sidvekariya510/mac-security    # Homebrew 6.x requires trusting a third-party tap once
brew install mac-security                 # pulls gh, jq, osv-scanner, terminal-notifier
madhavtech-sec setup                      # installs checks at 10:00 + 18:00 + clone-guard; writes to $HOME only
```

> [!IMPORTANT]
> **Most Macs need one manual step after `setup`: grant Full Disk Access to `/bin/bash`.**
>
> `setup` finishes with a **launchd self-test**. On a default-configured Mac it reports the scheduled
> scan is **TCC-blocked** — the 10:00/18:00 check still runs, but macOS won't let it read your folders,
> so it would silently report "clean" while scanning nothing. To fix it:
>
> 1. System Settings → Privacy & Security → **Full Disk Access**
> 2. Click **+**, press **⌘⇧G**, type `/bin/bash`, select it, and toggle it **on**
> 3. Re-run `madhavtech-sec setup` — the self-test should now print **✓ agent runs unattended**
>
> If the self-test already shows **✓**, your Mac doesn't need this — skip it. One grant also covers the weekly check.

## Check your Mac's health
A scan runs automatically twice a day (10:00 and 18:00) and notifies you only on a finding. To run one yourself:
```bash
madhavtech-sec healthcheck      # scans now; prints a report
madhavtech-sec version          # shows version + that it's in Homebrew-managed mode
madhavtech-sec selftest         # confirms the IoC list loads
```
| Result | Exit | Meaning |
|---|---|---|
| **✓ CLEAN** | 0 | nothing found (silent — no notification) |
| **⚠ FLAG** | 1 | review: new launch agent / SSH key / config obfuscation / etc. |
| **■ HARD-STOP** | 2 | critical: live payload, C2 connection, `node -e` implant, or a malicious (`MAL-`) package |

Reports are saved (90-day retention) to `~/.local/state/madhavtech-sec/reports/health-YYYY-MM-DD.txt`.
When a notification fires, **click it** to open that day's report.

## Sweep your GitHub repos
Beyond the local machine, sweep every repo your GitHub account(s) can reach for the same indicators
(payload at any branch tip, propagation markers, and commits that look like an attacker push):
```bash
gh auth login                    # once, if not already signed in
madhavtech-sec gh-sweep          # read-only sweep of all repos across your gh accounts
madhavtech-sec gh-sweep --deep   # also pickaxe full git history (slower, more thorough)
```
Each repo is shallow-cloned and `git grep`'d; if a repo won't clone, it's scanned via the GitHub API
(never silently skipped). Same exit codes as above; never executes repo code. It also STOPs on commits
made outside your team's timezone — set `TEAM_TZ_ISO` (default `+05:30`) in `~/.config/madhavtech-sec/config`.

**Clone guard:** `setup` adds a shell hook that auto-sweeps any repo the moment you `git clone` /
`gh repo clone` it — so freshly-pulled code is checked before you `cd` in or install.

## What it checks (read-only)
- **Host:** scan-root readability, live `node -e` implant, live C2 connection, new LaunchAgents/cron vs a
  clean baseline, shell-startup injection, SSH-key encryption + new keys + git hooks, VS Code extensions.
- **Code (auto-discovered repos, incl. `node_modules`):** PolinRider payload signatures, obfuscated
  executable configs, known trojan npm package names, **`osv-scanner` malicious-package gate** on every
  lockfile, and propagation-marker files.

It auto-discovers repos under your home folder, so repos you clone later are covered automatically.

## Update
```bash
brew update && brew trust sidvekariya510/mac-security && brew upgrade mac-security && madhavtech-sec setup
```
(Homebrew 6.x re-checks trust when the formula changes, so the `brew trust` keeps upgrades from being refused.
Re-running `setup` re-baselines and re-tests.)

## Troubleshooting

**`brew update` fails: `homebrew/homebrew-cask-versions does not exist!`** (or any other tap "does not
exist"). A deprecated Homebrew tap is still registered on your Mac and blocks `brew update` from
refreshing *any* tap — including this one — so you'd be stuck on an old version. Remove the dead tap, then retry:
```bash
brew untap homebrew/homebrew-cask-versions   # remove the deprecated tap (exact name is in the error)
brew update && brew upgrade mac-security
```
It's safe — `cask-versions` was folded into the default `homebrew/cask`. (`brew tap` lists all your taps.)

**`brew install` says "already installed and up-to-date" but you're on an old version.** `install`
won't upgrade an existing install, and without `brew update` your local formula is stale. Use the Update
command above (`brew update && … brew upgrade …`), not `brew install`.

**`setup` warns the agent is TCC-blocked.** The scheduled scan can't read your folders. Grant **Full Disk
Access to `/bin/bash`** (System Settings → Privacy & Security → Full Disk Access → ⌘⇧G → `/bin/bash`), then
re-run `madhavtech-sec setup`.

## Uninstall
```bash
launchctl unload ~/Library/LaunchAgents/com.madhavtech.healthcheck.*.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.madhavtech.healthcheck.*.plist
brew uninstall mac-security && brew untap sidvekariya510/mac-security
# also remove the 'madhavtech-sec clone guard' line from ~/.zshrc
```

## Why you can trust the install
The formula pins the **sha256** of a release asset built by `git archive` from a **signed** git tag —
so what you install is byte-for-byte what was tagged, not whatever a branch happens to hold. This tap
requires signed commits + PR review, and only the owner can push to it.
