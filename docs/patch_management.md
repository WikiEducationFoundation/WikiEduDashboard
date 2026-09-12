# Patch management

How security fixes and other updates reach the Wiki Education Dashboard's production server
(`dashboard.wikiedu.org`) and its staging server (`dashboard-testing.wikiedu.org`). This is
the process the HECVAT's PPPR-01 answer refers to. The Programs & Events Dashboard on
Wikimedia Cloud runs the same code but is operated separately and is not covered here.

**Owner:** the CTO. Anyone with production access may run a step; the owner is responsible
for the cadence being kept and for deciding exceptions.

## Layers and what patches each of them

| Layer | Examples | How updates arrive | Cadence |
|---|---|---|---|
| Operating system security fixes | Debian security advisories for the kernel, OpenSSL, Apache, MariaDB, OpenSSH, and everything else installed from Debian | `unattended-upgrades`, restricted to the Debian security suite | Automatic, daily |
| Other operating-system packages | Debian point-release updates; Redis from the redis.io repository | `apt update && apt full-upgrade` by hand | Monthly |
| Ruby gems and JavaScript packages | Rails, Sidekiq, React, build tooling | GitHub Dependabot alerts (alerts only, no automatic PRs); `bundler-audit` fails CI when a gem in the lockfile has a published advisory | Monthly triage to zero open alerts; a failing CI build is fixed before the affected change merges |
| Language runtimes | Ruby (installed through RVM, so not covered by apt), Node.js | Manual, following [Upgrading dependencies](upgrade_dependencies.md) | Reviewed monthly; upgraded when a security release or end-of-life approaches |
| Operating-system release | Debian 12 → 13 and later | A written, rehearsed runbook (the 2026 upgrade rehearsed on a clone of the production Linode first) | Before the running release leaves Debian security support |
| The application itself | The Dashboard's own code | Merged to `master` after code review and a green CI build, then deployed with Capistrano from the `production` branch (see [Deployment](deploy.md)) | Several times a week |

## Automatic security updates

`unattended-upgrades` runs daily from the `apt-daily-upgrade.timer` (about 06:00 server
time plus a random delay of up to an hour) and installs whatever the Debian security
suite offers for the installed release. It does **not** install point-release updates or
packages from third-party repositories, does **not** reboot, and does **not** remove
packages; those are left to the monthly manual run so that a person is watching when they
happen. Packages whose maintainer scripts restart their service (Apache, MariaDB) will do so
during the automatic run; that is a few seconds of interruption for a security fix, and is
accepted. Its log is `/var/log/unattended-upgrades/unattended-upgrades.log`.

Setup on a Debian server, done once (the configuration lives in a separate file so that
package upgrades never prompt about it):

```bash
sudo apt install -y unattended-upgrades

sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'CONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONF

sudo tee /etc/apt/apt.conf.d/52unattended-upgrades-local > /dev/null <<'CONF'
// Local policy, documented in docs/patch_management.md of the Dashboard repository:
// apply only Debian security updates automatically. Point-release updates and the
// redis.io repository are applied in the monthly manual run.
#clear Unattended-Upgrade::Origins-Pattern;
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,codename=${distro_codename},label=Debian-Security";
        "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "false";
CONF

apt-config dump Unattended-Upgrade::Origins-Pattern      # only the two Debian-Security lines
sudo unattended-upgrade --dry-run --debug 2>&1 | grep -E 'Allowed origins|Checking|pkgs that look like|No packages found|Packages that will be upgraded'
systemctl list-timers 'apt-daily*' --no-pager
```

The dry run lists the allowed origins and any security updates it would install right now.
To apply them immediately rather than waiting for the timer, `sudo unattended-upgrade -v`.

## Monthly run

Done by hand, at a quiet time, not on a Sunday evening (the weekly database backup runs at
20:00). Record the date and anything notable on the office wiki's security page.

1. On each server: `sudo apt update && sudo apt full-upgrade`, then `sudo apt autoremove`
   (never `--purge`). Read what it proposes before confirming; conffile prompts are answered
   per the notes in the most recent upgrade runbook.
2. If a kernel or libc update was installed (`ls /boot | tail`, or `needrestart` if
   installed), schedule a reboot: confirm `grep root= /boot/grub/grub.cfg` shows
   `root=UUID=` first, then reboot and run the post-change checks below.
3. In GitHub, bring the repository's Dependabot alerts to zero: upgrade, or record why an
   alert does not apply (a `.bundler-audit.yml` ignore entry with a justification for gems).
   AI-assisted audits are fine; a person reviews the resulting pull request.
4. Check the horizons: the Debian release's security-support end date, Ruby and Rails
   end-of-life dates, Node.js LTS status. Anything within six months gets a scheduled task.
5. Post-change checks on each server: the site loads (including a database-backed page),
   `systemctl list-units --failed` is empty, `sudo ss -tulpn | grep -Ev '127\.0\.0\.1|\[::1\]'`
   lists only sshd (22) and Apache (80, 443), `systemctl is-enabled mariadb.socket` is
   `disabled`, the IPv6 address check from Phase 0 of
   [`server_config/firewall.md`](../server_config/firewall.md) passes, and Sentry is quiet.

## Out-of-band fixes

A critical vulnerability in something reachable from the internet (Apache, OpenSSH, Rails,
the LTI or OAuth code paths) or one with a public exploit is patched as soon as it is known,
without waiting for the monthly run. Debian security fixes for such components arrive
automatically; application-level fixes ship through the normal deploy after CI passes.

## Verification and record

- The automatic run's log: `/var/log/unattended-upgrades/unattended-upgrades.log`, and
  `apt list --upgradable` should show no security updates pending on any given day.
- The monthly run: a dated entry on the office wiki's security page.
- Dependency state: the GitHub Dependabot alerts page and the `bundle-audit` step in every
  CI run.
- Firewall and listener state after any change: the checks in
  [`server_config/firewall.md`](../server_config/firewall.md).

## Current exceptions

- Staging (`dashboard-testing.wikiedu.org`) is on Debian 10, which is past end of life, and
  is to be rebuilt on a current release. It holds no production data and sits behind the
  same firewall rules as production.

(Document written by Claude Code.)
