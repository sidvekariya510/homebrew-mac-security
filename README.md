# homebrew-mac-security

Homebrew tap for **mac-security** — the MadhavTech team's read-only daily PolinRider /
supply-chain health check. This tap and its release asset are **public** (just the read-only
scripts + the PolinRider IoC indicators); the source repo, incident docs, and internal allowlist
stay private in `sidvekariya510/mac-security`.

## Install

```bash
brew tap sidvekariya510/mac-security
brew install mac-security

# one-time per-Mac setup (launchd daily agent + clone-guard; writes to $HOME only)
madhavtech-sec setup
```

## Update

```bash
brew update && brew upgrade mac-security
```

A new release ships when the security lead cuts one from the source repo
(`scripts/cut-release.sh --publish`, signed tag + sha256-pinned asset). To refresh IoCs faster
than a release cadence, drop an updated list at `~/.config/madhavtech-sec/iocs.txt` — it takes
precedence over the bundled copy and survives `brew upgrade`.

## What's in the formula

`Formula/mac-security.rb` pins the sha256 of a self-built release asset produced from a **signed**
git tag — so an install is byte-for-byte what was tagged, not whatever a branch holds. Formula
bumps go through a signed PR (this repo requires signed commits + PR review).
