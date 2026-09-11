# Network firewall for dashboard.wikiedu.org

The production Dashboard runs on a single Linode (Akamai Cloud) in Fremont, CA. Until
September 2026 it had no firewall of any kind: the host ran Debian's default empty
netfilter rule set, and nothing filtered traffic upstream of the VM. This document is
the design, rollout runbook, and change procedure for the **Akamai Cloud Firewall**
attached to that Linode. It is the record the HECVAT firewall answers (FIDP-01, FIDP-02,
FIDP-05 in `docs/hecvat.md`) point to.

Status: **applied** to production and staging on 2026-09-11 (and to the rehearsal clone while it
exists). See the "Applied" table at the end.

## Why a Cloud Firewall rather than (or before) a host firewall

- **It is stateful and sits outside the VM.** Akamai describes Cloud Firewalls as
  "stateful network-based firewalls" that operate between the Linode and the internet.
  Return traffic for connections the server opens (DNS, NTP, HTTPS to Wikimedia and the
  other APIs, apt) is allowed automatically, so an outbound policy of ACCEPT plus a
  default-drop inbound policy is safe.
- **Nothing changes on the host.** No packages, no nftables rules, no reboot. Attaching
  and detaching takes effect within seconds and is done from Cloud Manager, the Linode
  CLI, or the API, so the rollback is a single click that does not depend on SSH working.
- **Changes are logged for us.** Every create, rule update, attach/detach, enable/disable
  is an event in the account's event history (`firewall_create`, `firewall_rules_update`,
  `firewall_device_add`, `firewall_device_remove`, `firewall_enable`, `firewall_disable`,
  `firewall_delete`) with the acting user and timestamp, retained 90 days. Together with
  this file's git history that is the audit trail.
- **It is free** in all regions.

Akamai's own guidance is to run both a Cloud Firewall and a host firewall; for inbound
traffic the Cloud Firewall is evaluated first. A host nftables rule set is a reasonable
later addition (see "Later hardening") but is not needed to close the HECVAT gap, and
doing one layer at a time keeps each change easy to reason about and to roll back.

Limits that matter: 25 rules per firewall (inbound and outbound combined), 255 addresses
per rule, 15 ports or port ranges per rule, one firewall per Linode. Rules apply to the
public and private interfaces but not to VLAN interfaces (we have none).

## Facts the design depends on

Confirmed during the September 2026 OS upgrade (`.claude/debian_upgrade_plan-2026-09-01.md`
inventory, and the live notes there) unless marked otherwise.

| Fact | Consequence for the rules |
|---|---|
| Public IPv4 `45.79.106.114` is **static** in `/etc/network/interfaces`. | No DHCP to allow. |
| Public IPv6 `2600:3c01::f03c:93ff:fe24:db1b` is a **SLAAC** address (`inet6 auto`, EUI-64), and Wikimedia allowlists reference it. Outbound calls to Wikimedia leave from this address. | SLAAC needs inbound ICMPv6 router advertisements and neighbor discovery. Akamai's IPv6 guide: "In order for your Linode to receive its SLAAC address, it must respond to IPv6's ping protocol" and the firewall must "allow ICMPv6". **The ICMP rule with source `::/0` is therefore mandatory**, and losing it would eventually drop the allowlisted address. |
| Public listeners as of the Phase 0 check on 2026-09-11: `sshd` on 22, Apache on 80 and 443, and **MariaDB on `*:3306`** (all interfaces, socket held by systemd as well as `mariadbd`), reachable from the internet over IPv4. Redis (`bind 127.0.0.1 -::1`) and memcached (`-l 127.0.0.1`) are loopback-only. Before the 2026-09-04 upgrade MariaDB was on `127.0.0.1` via `bind-address` in `50-server.cnf`; bookworm's packaging stopped honoring it (see Phase 0). | Only 22, 80, 443 get inbound rules. The firewall drops 3306 from outside the moment it is attached, which is the fast mitigation; binding MariaDB back to loopback is the durable fix and is done regardless. |
| TLS certificates come from Let's Encrypt via the certbot snap with the **Apache authenticator** (HTTP-01). | Port 80 must stay open to the whole internet; Let's Encrypt validates from multiple, unpublished addresses. |
| `backup.sh` (weekly, Sunday 20:00) calls `https://dashboard.wikiedu.org/system/can_start_backup.json` from the server itself. | Traffic to the server's own public address is delivered over loopback and never reaches the Cloud Firewall. Unaffected. |
| Deploys are Capistrano over SSH from a staff machine; LTI launches, Wikimedia OAuth callbacks, LTIAAS and Mailgun callbacks, the uptime monitor, and all users arrive over HTTPS. | Covered by rules 1 and 2. |
| Outbound dependencies: Wikimedia APIs (IPv6), the replica-revision Toolforge tools, Mailgun, Sentry, Salesforce, LTIAAS, Pangram and Originality.ai, Debian and redis.io package mirrors, snapd, NTP, DNS, the Linode metadata service. | Outbound policy ACCEPT. Restricting outbound is possible later but needs every one of these enumerated first. |
| Out-of-band access: LISH/Weblish in Cloud Manager works regardless of network rules. | The safety net if an SSH rule is ever wrong. |

## The rule set

The live firewall is `dashboard-web`, Cloud Firewall ID **163657050** (created 2026-09-11).

Default inbound policy **DROP**. Default outbound policy **ACCEPT**. Rules are evaluated
top to bottom; first match wins.

| # | Label | Protocol | Ports | Sources | Action | Why |
|---|---|---|---|---|---|---|
| 1 | `allow-ssh` | TCP | 22 | `0.0.0.0/0`, `::/0` | ACCEPT | Capistrano deploys and administration. Key-based authentication only (verify in Phase 0). Kept as its own rule so the sources can be narrowed later without touching the web rule. |
| 2 | `allow-web` | TCP | 80, 443 | `0.0.0.0/0`, `::/0` | ACCEPT | The site, and Let's Encrypt HTTP-01 validation on port 80 (Apache redirects everything else to HTTPS). |
| 3 | `allow-icmp` | ICMP | — | `0.0.0.0/0`, `::/0` | ACCEPT | IPv6 SLAAC, neighbor discovery, path-MTU discovery, and ping-based monitoring. **Do not remove**: the Wikimedia-allowlisted IPv6 depends on it. |

Everything else inbound is dropped. No outbound rules.

The same firewall is attached to **staging** (`dashboard-testing.wikiedu.org`, `45.33.77.39`)
and, while it exists, to the `dashboard-rehearsal` clone; they have the same three listeners.

### As an API / Linode CLI request body

Equivalent to the table above; usable with `linode-cli firewalls create` or
`POST /v4/networking/firewalls`. Create it **without** `devices` and attach Linodes
separately, phase by phase.

```json
{
  "label": "dashboard-web",
  "tags": ["dashboard"],
  "rules": {
    "inbound_policy": "DROP",
    "outbound_policy": "ACCEPT",
    "inbound": [
      {
        "label": "allow-ssh",
        "description": "SSH for Capistrano deploys and administration (key-based auth only)",
        "protocol": "TCP",
        "ports": "22",
        "addresses": { "ipv4": ["0.0.0.0/0"], "ipv6": ["::/0"] },
        "action": "ACCEPT"
      },
      {
        "label": "allow-web",
        "description": "HTTP (Let's Encrypt HTTP-01, redirect to HTTPS) and HTTPS",
        "protocol": "TCP",
        "ports": "80, 443",
        "addresses": { "ipv4": ["0.0.0.0/0"], "ipv6": ["::/0"] },
        "action": "ACCEPT"
      },
      {
        "label": "allow-icmp",
        "description": "ICMP/ICMPv6: SLAAC and neighbor discovery for the allowlisted IPv6, PMTU, ping",
        "protocol": "ICMP",
        "addresses": { "ipv4": ["0.0.0.0/0"], "ipv6": ["::/0"] },
        "action": "ACCEPT"
      }
    ],
    "outbound": []
  }
}
```

In Cloud Manager the same thing is: **Firewalls → Create Firewall** (label
`dashboard-web`, no services assigned yet) → on the firewall's **Rules** tab set the
default inbound policy to **Drop** and outbound to **Accept**, then **Add an Inbound Rule**
three times (the SSH, HTTP and HTTPS presets exist; HTTP and HTTPS can be one custom TCP
rule with ports `80, 443`; ICMP is a custom rule with protocol ICMP, no ports, sources
`0.0.0.0/0` and `::/0`) → **Save Changes**. Nothing is enforced until a Linode is attached
on the **Linodes** tab.

## Rollout runbook (no-disruption path)

Each phase is independently reversible. The only step that touches production is Phase 4,
and its rollback is detaching the firewall, which takes effect in seconds and needs no
reboot and no SSH.

### Phase 0: pre-flight (on prod, run by the operator; 10 minutes)

1. **Confirm the public listeners are exactly 22, 80, 443** (plus NTP, which needs no
   inbound rule):

   ```bash
   sudo ss -tulpn | grep -Ev '127\.0\.0\.1|\[::1\]|Netid'
   ```

   Anything else bound to `0.0.0.0` or `[::]` needs a decision before Phase 4: add a rule,
   or (better) bind it to loopback.

   **Result 2026-09-11: MariaDB was listening on `*:3306`**, and a TCP connect to
   `45.79.106.114:3306` from outside succeeded. Diagnosis (same day): bookworm's
   `mariadb-server` enabled **`mariadb.socket`** (systemd socket activation) during the
   upgrade. systemd creates the TCP socket on all interfaces and hands it to `mariadbd`,
   so the daemon's `bind_address = 127.0.0.1` from `50-server.cnf` is loaded but never
   used for the TCP listener. File permissions were fine (Debian bug #1042454 did not
   apply). Every account in `mysql.user` is `@localhost`, so remote authentication was
   impossible; the exposure was the unauthenticated surface only.

   Fix, which restores the bullseye behavior and makes `50-server.cnf` the single source
   of truth again (one MariaDB restart, a few seconds of database errors for the app and
   Sidekiq; pick a quiet moment):

   ```bash
   systemctl cat mariadb.socket                 # for the record: what systemd was listening on
   sudo systemctl disable --now mariadb.socket  # stop socket activation; survives package upgrades
   sudo systemctl restart mariadb.service       # mariadbd now binds per 50-server.cnf
   sudo ss -tlnp | grep 3306                    # must show only 127.0.0.1:3306
   ls -l /run/mysqld/mysqld.sock && sudo mariadb -e 'SELECT 1'   # unix socket still there
   systemctl is-enabled mariadb.socket          # disabled
   ```

   **Applied 2026-09-11.** After the restart `ss` showed only `127.0.0.1:3306`, the unix
   socket and `SELECT 1` worked, `mariadb.socket` reports `disabled`, a TCP connect to
   `45.79.106.114:3306` from outside was refused, and the site served database-backed
   pages normally. Re-check `systemctl is-enabled mariadb.socket` after the Debian 13
   hop, and put the `ss` listener check in every post-upgrade checklist from now on.
2. **Confirm SSH is key-only**, since port 22 stays open to the internet:

   ```bash
   sudo sshd -T | grep -Ei '^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin|pubkeyauthentication) '
   ```

   Expected: `passwordauthentication no`, `kbdinteractiveauthentication no`,
   `permitrootlogin no` (or `prohibit-password`), `pubkeyauthentication yes`. If password
   authentication is on, turn it off first (`/etc/ssh/sshd_config.d/`, then
   `sudo systemctl reload ssh`) **from a session whose key login you have just tested**.
3. **Record the address baseline** (from the upgrade plan, section 5.0):

   ```bash
   ip -6 addr show scope global | grep -c 2600:3c01::f03c:93ff:fe24:db1b   # 1
   ip -4 addr show eth0 | grep -c 45.79.106.114                            # 1
   curl -s -o /dev/null -w '%{local_ip}\n' https://en.wikipedia.org/       # the IPv6 above
   ```
4. In Cloud Manager: confirm the account has **two-factor authentication** enabled for
   every user who can log in (the firewall is only as strong as the console that controls
   it), and open a **Weblish** tab to the prod Linode so out-of-band access is proven
   before anything changes.
5. Do not schedule Phase 4 for a Sunday evening (backup cron at 20:00) or during a deploy.

### Phase 1: create the firewall, attached to nothing

Create `dashboard-web` from the JSON or the Cloud Manager steps above. Verify on the
Rules tab: inbound Drop, outbound Accept, three inbound rules with both `0.0.0.0/0` and
`::/0` on each. Nothing is enforced yet.

### Phase 2: rehearse on the `dashboard-rehearsal` clone

The clone is a full copy of prod with the same listeners and its own SLAAC IPv6, so it is
the right place to prove the IPv6 behavior. Attach the firewall on the Linodes tab, then:

1. SSH in (rule 1). From the laptop, with the clone's IP in `/etc/hosts` for
   `dashboard.wikiedu.org`, load the site over HTTPS (rule 2); `curl -I http://...` should
   redirect to HTTPS.
2. On the clone, run the three address-check lines; the IPv6 must still be present and
   the Wikipedia probe must still leave from it.
3. `sudo apt update`, `redis-cli ping`, `dig +short en.wikipedia.org AAAA`, and
   `ntpq -p` (reach column non-zero) prove outbound DNS/HTTP/NTP replies get back in.
4. **Reboot the clone** with the firewall attached. Wait two minutes, then repeat step 2.
   The SLAAC address arrives with the next router advertisement, which on 2026-09-04
   took about a minute; a `0` in the first minute is not a failure. If the address is
   still missing after five minutes, stop: the ICMP rule is not doing its job and Phase 4
   must not proceed until that is understood.
5. Leave it attached for at least a day, then repeat step 2 once more (the address must
   survive router-advertisement refreshes, not just the initial one).

   **Result 2026-09-11:** all of the above passed on `dashboard-rehearsal`
   (IPv6 `2600:3c01::2000:1cff:fe90:bc91`). Two extra checks proved the ICMPv6 path
   directly rather than by waiting: `rdisc6 -1 eth0` (package `ndisc6`) received the
   router advertisement from `fe80::a9fe:a9fe` through the firewall, and the address's
   `valid_lft` reset to ~5400 s afterwards; before that it had only counted down.
   `timedatectl` showed NTP synchronized, `apt update` and `dig` worked. After
   `sudo reboot` the address was back within two minutes and the Wikipedia probe left
   from it. Use `rdisc6` in future instead of step 5's day-long wait.

### Phase 3: staging

Attach to `dashboard-testing`. Same checks as Phase 2 steps 1 to 3 (its IPv6 is not
allowlisted anywhere, so this is mostly a second data point). It stays attached.

### Phase 4: production

1. Weblish tab open; Phase 0 checks done within the last day; Sentry open.
2. Attach the firewall to the prod Linode.
3. Within the first minute, from prod: the three address-check lines. From the laptop:
   `ssh` in a **new** session, `curl -sI https://dashboard.wikiedu.org/ | head -1`,
   `curl -6 -sI https://dashboard.wikiedu.org/ | head -1`, `ping -c 3 dashboard.wikiedu.org`,
   `ping -6 -c 3 dashboard.wikiedu.org`.
4. Over the next 15 minutes: Sentry stays quiet; the Sidekiq Web UI shows jobs completing;
   `sudo journalctl -u sidekiq-default --since -15min` shows no connection errors; a page
   that hits the Wikimedia API (any course's Activity tab) loads.
5. Within the next day: `sudo certbot renew --dry-run` (snap) succeeds, proving HTTP-01
   still reaches Apache; after the next Sunday, confirm the weekly dump landed in
   `/home/dbbackup/dumps`.
6. Fill in the "Applied" section below and make the HECVAT and wiki updates listed there.

   **Result 2026-09-11:** attached at about 15:47 PDT. Probes from outside in the first
   seconds after the attach still saw unlisted ports *refused* (the packets reached the
   host); within a minute they were *dropped* (six-second timeout), which is the sign the
   Cloud Firewall is enforcing. Allow a minute before judging. After that: 22, 80, 443
   open; 3306 and 8080 dropped; HTTPS 200 including a database-backed page; HTTP 301 to
   HTTPS; ping answered. On the server: IPv6 `2600:3c01::f03c:93ff:fe24:db1b` present with
   a normal `valid_lft`, Wikipedia probe left from it, `apt update` succeeded, NTP
   synchronized. Still to do in the following days: `sudo certbot renew --dry-run`, a
   glance at the IPv6 `valid_lft` an hour later (it must have reset upward at least once),
   Sentry quiet, and the Sunday dump landing in `/home/dbbackup/dumps`.

**Rollback at any point**: Cloud Manager → Firewalls → `dashboard-web` → Linodes tab →
**Remove** the Linode (or **Disable** the whole firewall). Effective within seconds; no
reboot. If SSH is what broke, do it from Weblish or from any browser; the console does not
depend on the rules.

## Change procedure

This is the firewall change policy (HECVAT FIDP-02).

- **Who**: the CTO, or another Wiki Education staff member with admin access to the
  Linode account, and no one else. Access to that account is part of the quarterly account
  review.
- **How, for planned changes**: update the rule table and the JSON in this file in a pull
  request that explains the reason; after review, apply the change in Cloud Manager (or via
  the CLI/API) so the file and the live firewall match; then note the date under "Applied".
- **How, for emergencies** (for example an attack that needs a source range dropped):
  apply the change in Cloud Manager first, then bring this file into line within one
  business day.
- **What is never done casually**: removing `allow-icmp` (the Wikimedia-allowlisted IPv6
  depends on it); changing `allow-ssh` without an open Weblish session; setting the
  outbound policy to DROP without first enumerating and testing every outbound dependency
  in the facts table.
- **Record**: the Linode account event history holds every firewall event with user and
  timestamp for 90 days; this file's git history holds the intended state indefinitely.
  When the two disagree, the live firewall is wrong and gets fixed to match the file, or
  the file gets a PR explaining why the change was right.
- **Review**: quarterly, alongside the other server and account checks; and whenever the
  HECVAT is refreshed.

## Later hardening (not part of this rollout)

- **Narrow `allow-ssh`** to the staff addresses that actually deploy, once they are known
  to be stable; Weblish remains the fallback if an address changes. Alternatively keep 22
  open and add `fail2ban` on the host.
- **Host firewall (nftables)** as a second layer, so the rules hold even if the Linode is
  ever moved or the Cloud Firewall detached; also where per-service rate limits would live.
- **Outbound restriction** to the enumerated dependencies. High effort, modest gain for a
  server whose job is to call many third-party APIs.

## After it is live: documentation updates

Once Phase 4 is done and verified, make these edits so the public record matches reality:

1. `docs/hecvat.md`:
   - **FIDP-01** → Yes. Suggested note: "Inbound traffic to the production server is
     filtered by a stateful network firewall (Akamai/Linode Cloud Firewall) applied
     outside the server: the default inbound policy is drop, with only SSH, HTTP/HTTPS, and
     ICMP permitted; outbound traffic is unrestricted. The rule set and change procedure
     are published in the open-source repository (server_config/firewall.md). No separate
     host-based firewall is configured."
   - **FIDP-02** → Yes. Suggested note: "Firewall changes follow the procedure documented
     in server_config/firewall.md: the rule set is maintained in the repository, planned
     changes are reviewed there before being applied through the hosting provider's
     console, and emergency changes are recorded within one business day."
   - **FIDP-05** → Yes. Suggested note: "Every change to the network firewall (creation,
     rule updates, attaching or detaching a server, enabling or disabling) is recorded in
     the hosting account's event history with the acting user and timestamp, retained for
     90 days; the intended rule set and its history are kept in the public repository. No
     IDS or IPS is deployed (see FIDP-03 and FIDP-04)."
   - **DATA-01** note, optionally append: "Inbound traffic is filtered by a network
     firewall that admits only SSH, HTTP/HTTPS, and ICMP."
   - Bump the **Last reviewed** date in the header.
2. The security-status page on the office wiki: move "No firewall" from the gaps list to
   the in-place list.
3. `docs/deploy.md`, recovery procedure: attaching the firewall is part of standing up a
   replacement server.

## Applied

| Date | Linode | Firewall ID | By | Notes |
|---|---|---|---|---|
| 2026-09-11 | `dashboard-rehearsal` | 163657050 | Sage Ross | Phase 2 passed incl. reboot and `rdisc6` RA test. |
| 2026-09-11 | `dashboard-testing` (staging) | 163657050 | Sage Ross | External check: 22/80/443 open, HTTPS 200, HTTP 301 to HTTPS, unlisted port dropped (6 s timeout, not refused). |
| 2026-09-11 | prod (`dashboard.wikiedu.org`) | 163657050 | Sage Ross | Phase 4 passed; see the result note under Phase 4. Enforcement took under a minute to propagate. |

## Sources

- Akamai Cloud Firewall overview (limits, cost, interfaces): https://techdocs.akamai.com/cloud-computing/docs/cloud-firewall
- Cloud Firewall rules (fields, policies, ordering): https://techdocs.akamai.com/cloud-computing/docs/manage-firewall-rules
- Cloud Firewall vs. Linux firewall software ("stateful network-based firewalls"; inbound order of evaluation; recommendation to use both): https://techdocs.akamai.com/cloud-computing/docs/comparing-cloud-firewalls-to-linux-firewall-software
- IPv6 on Linodes (SLAAC requires ICMPv6 and router advertisements): https://techdocs.akamai.com/cloud-computing/docs/an-overview-of-ipv6-on-linode
- API: create a firewall (request schema): https://techdocs.akamai.com/linode-api/reference/post-firewalls
- API: events (firewall event types, 90-day retention): https://techdocs.akamai.com/linode-api/reference/get-events

(Document written by Claude Code.)
