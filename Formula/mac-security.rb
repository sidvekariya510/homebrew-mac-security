# Homebrew formula for the MadhavTech mac-security health check.
# Tap: sidvekariya510/homebrew-mac-security  →  `brew tap sidvekariya510/mac-security`
# Source + releases live at Princy-Madhavtech/mac-security (private). The url below pins the
# sha256 of a self-built, signed-tag release asset — what you install is byte-for-byte what
# was tagged (see scripts/cut-release.sh in the source repo).
class MacSecurity < Formula
  desc "Read-only daily PolinRider / supply-chain health check for the MadhavTech team"
  homepage "https://github.com/Princy-Madhavtech/mac-security"
  url "https://github.com/Princy-Madhavtech/mac-security/releases/download/v0.1.0/mac-security-0.1.0.tar.gz"
  sha256 "abfc078dac56631d6af7ac43416cdde9cae8fa1e16949e0f92e86d2ab35cc8e5"
  license :cannot_represent # internal tool, not publicly licensed

  depends_on "gh"
  depends_on "jq"
  depends_on "osv-scanner"

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

      The source repo + release asset are PRIVATE — Homebrew needs a GitHub token with read
      access to Princy-Madhavtech/mac-security. If the download 404s:
        export HOMEBREW_GITHUB_API_TOKEN=$(gh auth token)

      Security lead only (the weekly IoC-refresh pass commits): keep a git clone and run
      `./install.sh --weekly` from it — a read-only Homebrew keg can't commit.
    EOS
  end

  test do
    assert_match "madhavtech-sec", shell_output("#{bin}/madhavtech-sec version")
  end
end
