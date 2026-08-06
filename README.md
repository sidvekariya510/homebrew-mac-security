# mac-security — check your Mac for supply-chain malware

Read-only macOS health check for the **PolinRider / Contagious-Interview** npm supply-chain worm (and
general compromise). It scans with `grep` / `git log` / `gh` only — never installs, builds, lints, or runs
your code — writes a dated report, and notifies you **only on a finding**.

> Public tap, anyone can install. The source repo stays private.

**Requirements:** macOS (Apple Silicon or Intel) + [Homebrew](https://brew.sh).

---

## 1. Set up a Mac

### Install

```bash
brew tap sidvekariya510/mac-security
brew trust sidvekariya510/mac-security    # Homebrew 6.x: trust the tap once
brew install mac-security                 # pulls gh, jq, osv-scanner, terminal-notifier
```

### Grant Full Disk Access to `/bin/bash`

> [!IMPORTANT]
> **Most Macs need this.** Without it the scheduled scan cannot read your folders and would silently
> report "clean."
>
> System Settings → Privacy & Security → **Full Disk Access** → **+** → ⌘⇧G → `/bin/bash` → toggle **on**.

### Look before you baseline

```bash
madhavtech-sec healthcheck
```

Read-only. It installs nothing, schedules nothing, and records no baseline — it just tells you what is on
this Mac right now. Takes a few minutes.

Do this **before** the next step. `setup` records the machine's current state as its definition of normal,
and it refuses to do that on a Mac that looks compromised. Meeting that refusal on purpose, with the report
in front of you, is much easier than meeting it halfway through handing someone a laptop.

### Finish setup

```bash
madhavtech-sec setup      # launchd scans at 10:00 + 18:00, clone guard, baseline. Writes to $HOME only.
```

Re-run it until the self-test prints **✓ agent runs unattended**. If it says the agent is TCC-blocked, the
Full Disk Access step above is missing or was granted after the last run.

<details>
<summary><b>If <code>setup</code> refuses (exit 2)</b></summary>

It found something it will not record as normal. That is the tool working, not a bug.

1. Read the report it points at.
2. Fix what is real.
3. For anything legitimate on this machine, record the decision:
   ```bash
   madhavtech-sec ack <finding_id> --reason "why this is expected here"
   ```
   An acknowledgement expires after 90 days and stops applying if the finding disappears and comes back,
   so it silences a finding without hiding it.
4. Re-run `madhavtech-sec setup`.

There is a `MADHAVTECH_FORCE_BASELINE=1` override. Using it on a Mac you have not read the report for
defeats the point of the gate.
</details>

---

## 2. Update a Mac that already has it

```bash
brew update && brew trust sidvekariya510/mac-security && brew upgrade mac-security && madhavtech-sec setup
```

The final `setup` re-baselines and re-tests. It can refuse for the same reasons as above — see the details
box.

---

## 3. See how a Mac is doing

```bash
madhavtech-sec dashboard          # opens a local page
madhavtech-sec dashboard --print  # or a one-screen summary in the terminal
```

Generated from state already on disk and written only to your home directory — it never leaves the machine
and never runs a scan.

**The headline is the age of the answer, not the verdict.** "Nobody has checked this Mac in six days" and
"this Mac was checked and is clean" must not look alike, so a missing or unreadable state file, a report
that never finished, and a stale run all show up louder than any verdict.

---

## 4. Get told when a Mac goes quiet

Optional, and the only part that sends anything off the machine. A Mac that has stopped scanning looks
exactly like a healthy one from the outside — this is what closes that gap.

At [healthchecks.io](https://healthchecks.io) (free tier is enough for a small fleet), create **two** checks
for each Mac:

| name | period | grace |
|---|---|---|
| `<mac> liveness` | 12 hours | 6 hours |
| `<mac> hard-stop` | 12 hours | 6 hours |

Use **Simple**, not Cron — laptops sleep, and a missed run that lands late should not page you. On a laptop
set grace to **12 hours**.

Put both ping URLs in `~/.config/madhavtech-sec/config`:

```bash
HC_PING_URL="https://hc-ping.com/<liveness-uuid>"
HC_PING_URL_STOP="https://hc-ping.com/<hard-stop-uuid>"
```

> [!IMPORTANT]
> **Set both.** These services alert once, on the transition to "down". A flag and a hard-stop are both
> just "down", so with a single check a Mac that is already down for an ordinary flag and then acquires a
> root implant raises **no new alert**. Giving hard-stop its own check makes that escalation its own alert.

Then subscribe to notifications on the dashboard. A dead-man's switch nobody is subscribed to is a web page.

**What leaves the machine:** ten integers and short hashes — the run's fingerprint, how many checks ran, how
many findings are suppressed, and the baseline fingerprint. No hostname, no file paths, no finding text, no
repository names. The Mac is identified only by which URL it pinged, which the receiver already knows.

> [!WARNING]
> **A green row is weak evidence.** The ping URL lives on the machine it reports about, so anything that can
> read that file can post a clean ping. Silence and non-zero are the trustworthy halves. Use the dashboard to
> decide which Mac to open the report on — never to decide a Mac is fine.

---

## Everyday use

Scans run automatically at **10:00 + 18:00**. You are notified only on a finding; click the notification to
open the report.

```bash
madhavtech-sec healthcheck       # scan this Mac now
madhavtech-sec dashboard         # when was it last checked, and what changed
madhavtech-sec gh-sweep          # scan every GitHub repo your account(s) can reach
madhavtech-sec gh-sweep --deep   # also search full git history (slower)
madhavtech-sec ack --list        # standing acknowledgements and their age
madhavtech-sec version           # version + install mode
madhavtech-sec selftest          # confirm the indicator list loads
```

- `gh-sweep` needs GitHub auth — run `gh auth login` once if you are not signed in.
- A **clone guard** auto-sweeps any repo the moment you `git clone` / `gh repo clone` it.
- Reports land in `~/.local/state/madhavtech-sec/reports/` (90-day retention).

## What the results mean

**A scan** (`healthcheck`, and the scheduled runs):

| Result | Exit | Meaning |
|---|---|---|
| **✓ CLEAN** | 0 | nothing found (silent) |
| **⚠ FLAG** | 1 | review — e.g. a new launch agent / SSH key / config obfuscation, **or a repo `gh-sweep` could not access**. A FLAG is a *lead*, not confirmed malware. |
| **■ HARD-STOP** | 2 | critical: live payload, C2, `node -e` implant, or a `MAL-` package |

**`setup`** answers a different question, so it has its own codes:

| Exit | Meaning |
|---|---|
| **0** | installed, and its first scan was clean |
| **2** | **refused** — nothing was recorded. Deal with the finding, then re-run. |
| **3** | installed fine, but the Mac is not clean. Read the verdict. |

## Troubleshooting

- **`setup` says the agent is TCC-blocked** → grant Full Disk Access to `/bin/bash` (step 1), then re-run
  `madhavtech-sec setup`.
- **`brew update` fails — a tap "does not exist"** → a deprecated tap is blocking all updates. Remove it (the
  name is in the error), then retry: `brew untap homebrew/homebrew-cask-versions`
- **"already installed and up-to-date" but on an old version** → use the update command in step 2, not
  `brew install`.
- **The dashboard says `NEVER SCANNED` or `STALE`** → the scheduled agent is not running. Re-run
  `madhavtech-sec setup` and check the self-test line.
- **`gh-sweep` shows many `⚠ FLAG … repo UNSCANNED (needs an account with access)`** → **this is not malware.**
  The tool could neither clone nor read those repos, so it flags them as *unscanned* rather than pretending
  they are clean. Your GitHub sign-in is missing access:
  ```bash
  gh auth status            # logged in? does it say an org needs SSO authorization?
  gh auth login             # if you are not signed in
  gh auth refresh -s repo   # then authorize SSO for the org(s) in the browser
  ```
  For repos you clone over SSH, make sure your SSH key is added to GitHub. A line like
  `• … API-fallback scanned … CLEAN` is fine — the clone failed but the API read succeeded and found nothing.

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.madhavtech.healthcheck.*.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.madhavtech.healthcheck.*.plist
brew uninstall mac-security && brew untap sidvekariya510/mac-security
# then remove the 'madhavtech-sec clone guard' lines from ~/.zshrc
```

## Why you can trust it

The formula pins the **sha256** of an asset built by `git archive` from a **signed** git tag, so you get
exactly what was tagged. You can check it yourself:

```bash
curl -fsSL -o /tmp/ms.tgz https://github.com/sidvekariya510/homebrew-mac-security/releases/download/v0.2.3/mac-security-0.2.3.tar.gz
shasum -a 256 /tmp/ms.tgz     # must match the sha256 in Formula/mac-security.rb
```

The tap requires signed commits and PR review; only the owner can push.
