# Blueprint: endpoint

The employee device: laptops and desktops that people work on. This blueprint fixes which resident agents run on a device, which applications are standard, how devices are named and labelled, and why.

**Status:** draft, evolving. Created 2026-10-15.

**Capability code.** The naming standard has no capability code for devices yet, because devices are not services and get no service DNS name. The folder is called `endpoint`, the same word the standard uses for the device object family and its label keys (`endpoint-profile`). The [tech radar](https://github.com/mess-systems/tech-radar) category `device` is a catalog code for the same area; it is not a name token.

## 1. Scope

| In scope | Out of scope |
|---|---|
| Company laptops and desktops | Phones and tablets (separate blueprint later) |
| Resident agents and standard applications | Server-side components (Fleet server, Wazuh manager, NetBird management): they belong to their own capabilities |
| Device naming and labels | Personal devices beyond the BYOD alias rule |

## 2. Profiles, forms and platforms

| Profile | Who | Baseline |
|---|---|---|
| `std` | Every employee | Default baseline |
| `eng` | Engineers | Build tools, AI coding agents, sandboxing, containers |
| `paw` | Administrators, admin work only | Dedicated, hardened privileged-access workstation. No mail, chat or AI clients |

| Form | Meaning |
|---|---|
| `lt` | Laptop |
| `dt` | Desktop or fixed workstation |

| Platform | Profiles |
|---|---|
| Windows 11 Pro | `std`, `eng`, `paw` |
| macOS (current or previous release) | `std`, `eng`, `paw` |
| Ubuntu 26.04 LTS | `std`, `eng`, `paw` |
| CachyOS | `eng` only |

## 3. Naming and labels

Device name: `<profile>-<form>-<asset-id>`, for example `eng-lt-k7m2qa`.

- `asset-id` is 6 characters from the alphabet `a-z 2-9` without `o`, `l`, `i`, starting with a letter. It is allocated by the asset system and never changes. Serial numbers are not used.
- The name fits the 15-character limit of Windows computer names.
- Regex: `^(std|eng|paw)-(lt|dt)-[a-hjkmnp-z][a-hjkmnp-z2-9]{5}$`.
- A personal device keeps its own hostname; the management tool may give it the alias `byod-<form>-<asset-id>` for inventory only.
- The name grants nothing. Access comes from groups and device posture, never from the name.
- Endpoints have no records in the service DNS zone.

Labels in Fleet and Wazuh follow [labels and tags](https://github.com/mess-systems/naming-standard/blob/main/05-labels-and-tags.md): `plane`, `owner` (a group), `endpoint-profile`, `device-form`, `data-class`. User name, serial number and hostname never go into labels.

The device naming rule is a proposal for naming-standard v2.2; until it is merged there, this blueprint is the public description.

## 4. Resident agents

A resident agent is a background service that runs whenever the device is on. Built-in OS features (disk encryption, firewall, updates) are settings, not agents. Ansible is not an agent: it runs over SSH or as a scheduled `ansible-pull`.

| Agent | Purpose | Radar | `std` | `eng` | `paw` |
|---|---|---|---|---|---|
| Fleet (fleetd with osquery) | Inventory, policies, device queries | [Trial](https://github.com/mess-systems/tech-radar/blob/main/technologies/fleet.md) | yes | yes | yes |
| Wazuh agent | Security logs and detection | [Adopt](https://github.com/mess-systems/tech-radar/blob/main/technologies/wazuh.md) | yes | yes | yes |
| NetBird client | Mesh access to internal services with SSO | [Adopt](https://github.com/mess-systems/tech-radar/blob/main/technologies/netbird.md) | yes | yes | yes |
| RustDesk service | Remote support | [Adopt](https://github.com/mess-systems/tech-radar/blob/main/technologies/rustdesk.md) | yes | yes | no: no inbound remote control on a privileged workstation |
| agentdesktop | Inventory and managed settings of AI clients, sandbox policy, routes model traffic to the AI gateway | [Trial](https://github.com/mess-systems/tech-radar/blob/main/technologies/agentdesktop.md) | yes | yes | no: no AI clients on `paw` |
| Container runtime (Podman) | Dev containers and sandboxes for CLI agents | [Trial](https://github.com/mess-systems/tech-radar/blob/main/technologies/podman.md) | no | yes | no |
| SPIRE agent | SPIFFE device identity for fully managed, attested devices | [Trial](https://github.com/mess-systems/tech-radar/blob/main/technologies/spire.md) | no | no | yes (proposed) |

AI is used by everyone, so control of AI clients is needed on every profile that has them. `paw` has none by design.

### 4.1 Agents per device

| Profile | Agents | Count | With reductions |
|---|---|---|---|
| `std` | Fleet, Wazuh, NetBird, RustDesk, agentdesktop | 5 | 4 |
| `eng` | the `std` five plus the container runtime | 6 | 4 |
| `paw` | Fleet, Wazuh, NetBird, SPIRE | 4 | 4 |

The count is the same on every platform of a profile. If the SPIRE agent is also enabled on `std` or `eng`, the count grows by 1.

### 4.2 Reductions

| Overlap | Reduction | Effect |
|---|---|---|
| Fleet and Wazuh both collect inventory and check settings | Wazuh reads osquery results through its osquery module; its own inventory collection and configuration assessment are switched off. Fleet owns inventory and policies, Wazuh owns logs and detection | Less duplicated data; agent count unchanged |
| RustDesk and NetBird both reach the device | The support client starts on request of the user instead of running as a service | Minus 1 on `std` and `eng` |
| Container runtime as a permanent daemon | Podman is daemonless: rootless and started on demand, so it is not a resident agent | Minus 1 on `eng` |
| agentdesktop and Fleet both inventory software | AI client inventory comes from Fleet; agentdesktop keeps managed settings and sandbox policy | Less duplicated data; agent stays |

### 4.3 Platform notes

| Platform | Notes |
|---|---|
| Windows 11 Pro | All agents have official builds. BitLocker, Defender and firewall are built in. |
| macOS | Apple MDM profiles come from the Fleet server; no agent besides fleetd is needed for them. FileVault is built in. |
| Ubuntu 26.04 LTS | All agents have Debian or Ubuntu packages. LUKS2 with TPM2. |
| CachyOS | Fleet, Wazuh and NetBird are available for the platform. |

## 5. Standard applications

Started by the user; they do not run in the background. The radar covers products named by the standards, so most user applications are outside it by design.

| Category | Product | Profiles | Radar |
|---|---|---|---|
| Browser | Firefox with policies | all | outside the radar |
| Office | LibreOffice | `std`, `eng` | outside the radar |
| Mail | Thunderbird | `std`, `eng` | outside the radar |
| Passwords | Bitwarden client; KeePassXC offline | all | server [Vaultwarden](https://github.com/mess-systems/tech-radar/blob/main/technologies/vaultwarden.md) in Assess |
| Chat | Element | `std`, `eng` | [Matrix](https://github.com/mess-systems/tech-radar/blob/main/technologies/matrix.md) (Adopt) as the protocol |
| Archiver | 7-Zip | `std`, `eng` | outside the radar |
| Media | VLC | `std`, `eng` | outside the radar |
| PDF | PDF Arranger, Okular, Xournal++, OCRmyPDF (Linux) | `std`, `eng` | outside the radar |
| User configuration | chezmoi | `eng` | outside the radar |
| AI CLI agents | OpenCode by default; goose, Codex CLI, Gemini CLI | `eng` | no cards yet |
| AI chat for everyone | LibreChat web client through the AI gateway | `std`, `eng` | [LibreChat](https://github.com/mess-systems/tech-radar/blob/main/technologies/librechat.md) (Trial), [agentgateway](https://github.com/mess-systems/tech-radar/blob/main/technologies/agentgateway.md) (Adopt) |
| Remote desktops for risky work | Kasm Workspaces in the browser | `std`, `eng` | [Kasm Workspaces](https://github.com/mess-systems/tech-radar/blob/main/technologies/kasm-workspaces.md) (Adopt) |
| Windows applications on Linux | WinBoat | `eng` on Linux | [WinBoat](https://github.com/mess-systems/tech-radar/blob/main/technologies/winboat.md) (Adopt) |

On `paw`: browser, password manager and admin tools only. No mail, chat or AI clients.

Configuration is applied with [Ansible](https://github.com/mess-systems/tech-radar/blob/main/technologies/ansible.md) (Adopt) and Fleet policies.

## 6. Rationale

- **Few agents.** Every resident agent costs battery, attack surface and support. The baseline keeps one agent per job and removes overlaps (section 4.2).
- **Open source and self-hosted.** All agents report to servers the company runs; no vendor relay in the path.
- **Access by posture, not by network.** NetBird gives mesh access after SSO; the device name grants nothing.
- **AI through one gateway.** agentdesktop points AI clients at the company AI gateway with short-lived credentials; provider keys stay at the gateway, never on the device.
- **`paw` is minimal.** No inbound remote control, no mail, chat or AI: a privileged workstation does only admin work.

## 7. Configuration examples

The files in [examples/](examples/) are **examples only**: skeletons with placeholder values that show the shape of a setting. They are not the configuration of any running system.

| File | Shows |
|---|---|
| [fleet-labels.example.yml](examples/fleet-labels.example.yml) | Fleet labels that group devices by profile from the device name |
| [wazuh-agent-osquery.example.xml](examples/wazuh-agent-osquery.example.xml) | Wazuh agent reading osquery results instead of running its own inventory |
| [agentdesktop.example.yaml](examples/agentdesktop.example.yaml) | AI clients routed to an AI gateway |
| [podman-containers.example.conf](examples/podman-containers.example.conf) | Rootless Podman defaults for `eng` |

## 8. Open questions

1. AI CLI agents (OpenCode and others) have no radar cards. One group card or one card each.
2. Password manager: Bitwarden client with Vaultwarden (Assess) or another choice.
3. Fleet free edition: remote lock and wipe, label-based profile assignment and enforced encryption are paid features; the free edition needs scripts instead.
4. SPIRE agent on devices: SPIRE is in Trial for workloads; device use is not decided.
