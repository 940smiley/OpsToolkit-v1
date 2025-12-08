OpsToolkit v1
OpsToolkit is a modular, audit‑ready automation framework for Windows workstation setup, developer onboarding, and contributor empowerment. It provides a clean, menu‑driven interface for installing tools, configuring Windows, customizing Windows Terminal, and applying security/privacy baselines.
Everything is built with:
• 	Predictable module structure
• 	Safe, reversible operations
• 	Clear logging
• 	Contributor‑friendly design
• 	Zero hidden behavior

🚀 Quick Start
Run this one‑liner in PowerShell:
irm https://raw.githubusercontent.com/940smiley/OpsToolkit-v1/main/bootstrap.ps1  iex
This will:
• 	Download the toolkit
• 	Extract it to ~/OpsToolkit
• 	Register module paths
• 	Launch the OpsToolkit Launcher

📦 Features
Windows Terminal Customization
• 	Themes
• 	Profiles
• 	Icons
• 	Keybindings
• 	Color schemes
• 	Defaults
• 	Backup/restore
Windows System Configuration
• 	Privacy hardening
• 	Security baseline
• 	Power settings
• 	Explorer tweaks
• 	Context menu entries
• 	Optional features
• 	Developer mode
• 	WSL + WSA
Developer Tools
• 	Visual Studio Build Tools
• 	.NET SDK
• 	Windows SDK
• 	Git Extensions
• 	VS Code + Extensions
• 	Docker Desktop
• 	Python packages

🧩 Architecture
OpsToolkit/
├── Install-OpsToolkit.psm1
├── Launcher/
│   └── OpsToolkitLauncher.psm1
├── Modules/
│   ├── Utility/
│   │   ├── Prompts.psm1
│   │   ├── FileSystem.psm1
│   │   └── Logging.psm1
│   ├── Install-WindowsTerminal.psm1
│   ├── Install-WindowsSubsystemLinux.psm1
│   ├── Install-WindowsPackageManager.psm1
│   ├── Install-WindowsDeveloperMode.psm1
│   ├── Install-WindowsFeatures.psm1
│   ├── Install-WindowsSubsystemAndroid.psm1
│   ├── Install-WindowsDeveloperTools.psm1
│   ├── Install-WindowsFonts.psm1
│   ├── Install-WindowsTerminalThemes.psm1
│   ├── Install-WindowsTerminalProfiles.psm1
│   ├── Install-WindowsTerminalIcons.psm1
│   ├── Install-WindowsTerminalExtensions.psm1
│   ├── Install-WindowsTerminalKeybindings.psm1
│   ├── Install-WindowsTerminalColorSchemes.psm1
│   ├── Install-WindowsTerminalDefaults.psm1
│   ├── Install-WindowsTerminalBackup.psm1
│   ├── Install-WindowsPrivacySettings.psm1
│   ├── Install-WindowsSecurityBaseline.psm1
│   ├── Install-WindowsPowerSettings.psm1
│   ├── Install-WindowsExplorerTweaks.psm1
│   ├── Install-WindowsContextMenu.psm1
│   ├── Install-GitExtensions.psm1
│   ├── Install-VSCode.psm1
│   ├── Install-VSCodeExtensions.psm1
│   ├── Install-DockerDesktop.psm1
│   └── Install-PythonPackages.psm1
└── bootstrap.ps1

🛠 Usage
Launch the Toolkit:
Start-OpsToolkitLauncher
Run the Master Installer:
Install-OpsToolkit
Run a specific module:
Install-WindowsTerminal
Install-WindowsDeveloperTools
Install-WindowsPrivacySettings

🔄 Auto‑Update (Coming Soon)
OpsToolkit includes a placeholder for an update engine:
Update-OpsToolkit
This will be implemented in Modules/Update-OpsToolkit.psm1.

🤝 Contributing
See CONTRIBUTING.md for full guidelines.

📝 License
MIT License.
Feel free to fork, extend, and build on top of OpsToolkit.