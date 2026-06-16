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
madhavtech-sec setup                      # installs a daily 10:00 check + clone-guard; writes to $HOME only
```

`setup` ends with a **launchd self-test**. If it prints a TCC warning, your Mac is blocking the
background check from reading your folders — grant **Full Disk Access to `/bin/bash`**:

> System Settings → Privacy & Security → **Full Disk Access** → **+** → press **⌘⇧G**, type
> `/bin/bash`, add it, toggle it **on** — then run `madhavtech-sec setup` again. (One grant also
> covers the weekly check.)

## Check your Mac's health
A scan runs automatically every day at 10:00 and notifies you only on a finding. To run one yourself:
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
