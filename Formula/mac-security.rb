# Homebrew formula for the MadhavTech mac-security health check.
# Tap: sidvekariya510/homebrew-mac-security  →  `brew tap sidvekariya510/mac-security`
# The PUBLIC asset below is built from a SIGNED tag on the private source repo
# (sidvekariya510/mac-security) and hosted here on the tap, so install needs no token. The
# pinned sha256 means what you install is byte-for-byte what was tagged (scripts/cut-release.sh).
class MacSecurity < Formula
  desc "Read-only daily PolinRider / supply-chain health check for the MadhavTech team"
  homepage "https://github.com/sidvekariya510/homebrew-mac-security"
  url "https://github.com/sidvekariya510/homebrew-mac-security/releases/download/v0.1.4/mac-security-0.1.4.tar.gz"
  sha256 "870e3a2a34b3256708a934efb08081432a4f8fc07559ea034899043ebe929f3b"
  license :cannot_represent # internal tool, not publicly licensed

  depends_on "gh"
  depends_on "jq"
  depends_on "osv-scanner"
  depends_on "terminal-notifier" # makes the alert clickable → opens the report (else osascript fallback opens a blank Script Editor)

  def install
    # install the whole tree under libexec (preserves bin/ data/ shell/ launchd/ weekly/),
    # then symlink only the user-facing commands. The scripts resolve their own location, so
    # they find data/ at libexec/data — no wrapper/env needed.
    libexec.install Dir["*"]
    %w[madhavtech-sec madhavtech-healthcheck madhavtech-gh-sweep].each do |cmd|
      bin.install_symlink libexec/"bin/#{cmd}"
    end
  end

  def caveats
    <<~EOS
      One-time per-Mac setup (installs the launchd daily agent + clone-guard; writes to $HOME only):
        madhavtech-sec setup

      To pin a refreshed IoC list that survives `brew upgrade`, drop it at
      ~/.config/madhavtech-sec/iocs.txt (it takes precedence over the bundled copy).

      Security lead only (the weekly IoC-refresh pass commits): keep a git clone and run
      `./install.sh --weekly` from it — a read-only Homebrew keg can't commit.
    EOS
  end

  test do
    assert_match "madhavtech-sec", shell_output("#{bin}/madhavtech-sec version")
  end
end
