# OSINT Tools Suite

All tools cloned and dependencies installed under `/home/user/Murad/tools/`.

| Tool | Type | Purpose |
|------|------|---------|
| sherlock | Python | Username hunt across 400+ sites |
| maigret | Python | Username OSINT aggregator |
| theHarvester | Python | Email/domain/IP recon |
| helix | Python | OSINT automation |
| osint-recon-suite | Python | Multi-source recon |
| WhatsMyName | Python | Username enumeration |
| social-analyzer | Python | Social media profile finder |
| osmedeus | Go | Automated recon framework |
| OneListForAll | Wordlists | Fuzzing wordlists |
| sn0int | Rust | Semi-automatic OSINT framework |
| enumerepo | Go | GitHub repo enumeration |
| python-for-OSINT-21-days | Python | OSINT scripting course |
| cheatsheets | Reference | OSINT cheatsheets |
| Python-osint-automation-examples | Python | Automation examples |
| awesome-grep | Reference | Grep patterns for OSINT |
| Awesome-OSINT-Lists | Reference | Curated OSINT list |
| OSINT-corsec00 | Reference | OSINT resources |
| OSINT-BIBLE | Reference | OSINT methodology bible |
| holehe | Python | Email account checker |
| blackbird | Python | Email/username OSINT |
| GHunt | Python | Google account OSINT |

## Quick Start

```bash
# Username across all platforms
cd sherlock && python3 sherlock/sherlock.py <username>

# Email account checker
cd holehe && holehe <email>

# Google account OSINT
cd GHunt && python3 ghunt.py <email>

# Email/domain harvesting
cd theHarvester && python3 theHarvester.py -d <domain> -b all

# Username OSINT
cd maigret && python3 -m maigret <username>

# Blackbird email/username
cd blackbird && python3 blackbird.py -u <username>
```
