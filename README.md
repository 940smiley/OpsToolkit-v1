# OpsToolkit v1

OpsToolkit is a modular, audit-ready automation framework for Windows workstation setup, developer onboarding, and contributor empowerment. It provides a clean, menu-driven interface for installing tools, configuring Windows, customizing Windows Terminal, and applying security/privacy baselines.

## At a Glance
- **Predictable module structure** with clear naming and separation of responsibilities
- **Safe, reversible operations** designed to avoid destructive changes
- **Transparent logging** so every action is visible and auditable
- **Contributor-friendly design** with consistent templates and conventions
- **Zero hidden behavior**: no surprises, no side effects

## Quick Start
Run this one-liner in PowerShell:

```powershell
irm https://raw.githubusercontent.com/940smiley/OpsToolkit-v1/main/bootstrap.ps1 | iex
```

This will:
- Download the toolkit
- Extract it to `~/OpsToolkit`
- Register module paths
- Launch the OpsToolkit Launcher

## Features
### Windows Terminal Customization
- Themes, profiles, icons, keybindings, color schemes, defaults
- Backup and restore

### Windows System Configuration
- Privacy hardening and security baseline
- Power settings and Explorer tweaks
- Context menu entries and optional features
- Developer mode, WSL, and WSA setup

### Developer Tools
- Visual Studio Build Tools, .NET SDK, Windows SDK
- Git Extensions and VS Code (plus extensions)
- Docker Desktop and common Python packages

## Architecture Overview
```
OpsToolkit/
├── Install-OpsToolkit.psm1
├── Launcher/
│   └── OpsToolkitLauncher.psm1
├── modules/
│   ├── Utility/
│   │   ├── Prompts.psm1
│   │   ├── FileSystem.psm1
│   │   └── Logging.psm1
│   ├── Install-*.psm1
│   └── Update-OpsToolkit.psm1 (placeholder)
├── scripts/
├── logs/
└── bootstrap.ps1
```

### Dependency & Component Map
| Component | Depends On | Purpose |
| --- | --- | --- |
| `Install-OpsToolkit.psm1` | Utility modules | Master installer orchestration |
| `Launcher/OpsToolkitLauncher.psm1` | Utility modules | Menu-driven launcher UX |
| `modules/Utility/Prompts.psm1` | - | Standardized user prompts |
| `modules/Utility/FileSystem.psm1` | - | File and path helpers |
| `modules/Utility/Logging.psm1` | - | Centralized logging |
| `Install-*` modules | Utility modules | Task-specific installers and configurators |
| `bootstrap.ps1` | PowerShell | Entry point for download/setup |

## Usage
Launch the Toolkit:
```powershell
Start-OpsToolkitLauncher
```

Run the Master Installer:
```powershell
Install-OpsToolkit
```

Run a specific module:
```powershell
Install-WindowsTerminal
Install-WindowsDeveloperTools
Install-WindowsPrivacySettings
```

## Installation & Setup Details
1. Ensure PowerShell 5.1+ is available.
2. Run the quick-start command from an elevated PowerShell session.
3. Verify that `~/OpsToolkit` exists and logs are writing to `~/OpsToolkit/logs`.
4. Use `Start-OpsToolkitLauncher` for guided installs or call specific modules directly.

## Contribution Guidelines
- Review the [CONTRIBUTING](CONTRIBUTING.md) guide for module templates, naming rules, and logging conventions.
- Keep modules single-purpose and export both `*-Core` and interactive wrappers.
- Include testing notes and screenshots (for UI-related changes) in pull requests.

## Auto-Update Placeholder
`Update-OpsToolkit` is planned in `modules/Update-OpsToolkit.psm1` and will manage future upgrades.

## License
MIT License. Feel free to fork, extend, and build on top of OpsToolkit.

---
_Last enhanced by Codex on 2025-12-08 14:30 UTC._
