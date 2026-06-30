# mac-security — check your Mac for supply-chain malware

Read-only macOS health check for the **PolinRider / Contagious-Interview** npm supply-chain worm (and
general compromise). It scans with `grep` / `git log` / `gh` only — never installs, builds, lints, or runs
your code — writes a dated report, and notifies you **only on a finding**.

> Public tap, anyone can install. Source repo + incident notes stay private in `sidvekariya510/mac-security`.

## Requirements
macOS (Apple Silicon or Intel) + [Homebrew](https://brew.sh).

## Install (once)
```bash
brew tap sidvekariya510/mac-security
brew trust sidvekariya510/mac-security    # Homebrew 6.x: trust the tap once
brew install mac-security                 # pulls gh, jq, osv-scanner, terminal-notifier
madhavtech-sec setup                      # launchd scans (10:00 + 18:00) + clone-guard; writes to $HOME only
```

> [!IMPORTANT]
> **Most Macs need one more step: grant Full Disk Access to `/bin/bash`.** If `setup`'s self-test prints a
> **TCC-blocked** warning, the scheduled scan can't read your folders and would silently report "clean."
> Fix: System Settings → Privacy & Security → **Full Disk Access** → **+** → ⌘⇧G → `/bin/bash` → toggle **on**,
> then re-run `madhavtech-sec setup` until it prints **✓ agent runs unattended**. (If it already shows ✓, skip.)

## Update
> [!TIP]
> One command — upgrades to the latest version, then re-baselines and re-tests:
> ```bash
> brew update && brew trust sidvekariya510/mac-security && brew upgrade mac-security && madhavtech-sec setup
> ```

## Use it
Scans run automatically at **10:00 + 18:00** — you're notified only on a finding (click the notification to
open the report). To run things yourself:
```bash
madhavtech-sec healthcheck       # scan this Mac now
madhavtech-sec gh-sweep          # scan every GitHub repo your account(s) can reach
madhavtech-sec gh-sweep --deep   # optional: also search full git history (slower)
madhavtech-sec version           # version + install mode
madhavtech-sec selftest          # confirm the IoC list loads
```
- **Optional:** `gh-sweep` needs GitHub auth — run `gh auth login` once if you're not signed in.
- A **clone guard** auto-sweeps any repo the moment you `git clone` / `gh repo clone` it.
- Reports land in `~/.local/state/madhavtech-sec/reports/` (90-day retention).

| Result | Exit | Meaning |
|---|---|---|
| **✓ CLEAN** | 0 | nothing found (silent) |
| **⚠ FLAG** | 1 | review — e.g. new launch agent / SSH key / config obfuscation, **or a repo `gh-sweep` couldn't access** (see Troubleshooting). A FLAG is a *lead*, not confirmed malware. |
| **■ HARD-STOP** | 2 | critical: live payload, C2, `node -e` implant, or `MAL-` package |

## Troubleshooting
- **`brew update` fails — a tap "does not exist"** → a deprecated tap is blocking all updates. Remove it
  (the name is in the error), then retry the **Update** command:
  ```bash
  brew untap homebrew/homebrew-cask-versions
  ```
- **`setup` warns the agent is TCC-blocked** → grant Full Disk Access to `/bin/bash` (see Install), then
  re-run `madhavtech-sec setup`.
- **"already installed and up-to-date" but on an old version** → use the **Update** command, not `brew install`.
- **`gh-sweep` shows many `⚠ FLAG … repo UNSCANNED (needs an account with access)`** → **this is not malware.**
  It means the tool could neither clone nor read those repos, so it flags them as *unscanned* instead of
  pretending they're clean. Your GitHub sign-in is just missing access. Fix it, then re-run `madhavtech-sec gh-sweep`:
  ```bash
  gh auth status            # logged in? does it say an org needs SSO authorization?
  gh auth login             # if you're not signed in
  gh auth refresh -s repo   # then authorize SSO for the org(s) in the browser
  ```
  For repos you clone over SSH, make sure your SSH key is added to GitHub. A line like
  `• … API-fallback scanned … CLEAN` is fine — the clone failed but the API read succeeded and found nothing.

## Uninstall
```bash
launchctl unload ~/Library/LaunchAgents/com.madhavtech.healthcheck.*.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.madhavtech.healthcheck.*.plist
brew uninstall mac-security && brew untap sidvekariya510/mac-security
# then remove the 'madhavtech-sec clone guard' line from ~/.zshrc
```

## Why you can trust it
The formula pins the **sha256** of an asset built by `git archive` from a **signed** git tag — so you get
exactly what was tagged. The tap requires signed commits + PR review; only the owner can push.
