# homebrew-mac-security

Homebrew tap for **mac-security** — the MadhavTech team's read-only daily PolinRider /
supply-chain health check. Source + releases: [`Princy-Madhavtech/mac-security`](https://github.com/Princy-Madhavtech/mac-security) (private).

## Install

```bash
# private source/release → give brew a token with read access to Princy-Madhavtech/mac-security
export HOMEBREW_GITHUB_API_TOKEN=$(gh auth token)

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
