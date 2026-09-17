# ⚡ AutoHeal Flight Deck for Omarchy

## Marketplace installation and review notes

This section describes the current implementation and takes precedence over broader feature claims below.

### Requirements and dependencies

Requires Omarchy Quattro's plugin-capable shell, Qt 6 / QtQuick / QtQuick.Controls / QtQuick.Layouts, Quickshell and Omarchy qs.Commons / qs.Ui modules. This is not a standalone QML application.

Bash, jq, awk and GNU coreutils. Python, uv, Node.js, Docker and Git are inspected for versions. The separate AutoHeal executable is resolved from PATH, ~/.local/bin/autoheal, or ~/Work/autoheal/autoheal, with memory at ~/.local/share/autoheal/memory.json. Uses the Omarchy notification helper.

### Install

Review the unsandboxed plugin source, then run in an Omarchy Quattro session:

    omarchy plugin add https://github.com/harshithnadig/omarchy-autoheal.git --enable

Use the Omarchy bar editor to place the widget if necessary. Installation fetches upstream HEAD, not a pinned marketplace-reviewed snapshot.

### Remove

    omarchy plugin remove harshith.autoheal

### Permissions and persistent state

Reads the AutoHeal memory file. The self-test button invokes the separately installed AutoHeal executable if present. Removal leaves AutoHeal and its memory intact.

### Current limitations

Prototype: ARMED status, reflex latency and recent-heal entries are hard-coded examples. The self-test notification claims success regardless of the external result. Tool versions and memory-rule count are read locally.

Repository structure and documentation were reviewed for resubmission. This is not a fresh end-to-end runtime test or security audit.

### License

MIT; see LICENSE. External applications, models and dependencies retain their own licenses.

---

**AutoHeal Flight Deck** is the official Omarchy topbar status and diagnostics plugin for **AutoHeal**.

---

## ✨ Features

- 󱐌 **Reflex Status Indicator:** Live lightning glyph reporting sub-millisecond reflex engine readiness.
- 🧰 **Toolchain Doctor Matrix:** Instant health check for Python, UV, Node.js, Docker, and Git.
- 📜 **Recent Heals Log:** Visual timeline of automatically recovered commands and port collisions.
- 🧪 **1-Click Reflex Self-Test:** Triggers internal validation across all 6 reflex engines.

---

## 🚀 Installation

Enable via Omarchy Plugin Manager:
```bash
omarchy plugin enable harshith.autoheal
```
