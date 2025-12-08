Contributing to OpsToolkit
OpsToolkit is designed to be modular, auditable, and contributor‑friendly. This guide explains how to add modules, improve existing ones, and maintain consistency across the toolkit.

✅ Principles
All contributions must follow these principles:
• 	Auditability — every action must be visible and logged
• 	Predictability — no hidden behavior, no side effects
• 	Modularity — one module = one responsibility
• 	Reversibility — avoid destructive changes
• 	Clarity — code should be readable and self‑documenting
• 	Contributor Empowerment — no magic, no black boxes

📁 Folder Structure
OpsToolkit/
├── Install-OpsToolkit.psm1
├── Launcher/
│   └── OpsToolkitLauncher.psm1
├── Modules/
│   ├── Utility/
│   │   ├── Prompts.psm1
│   │   ├── FileSystem.psm1
│   │   └── Logging.psm1
│   ├── Install-*.psm1
│   └── Update-OpsToolkit.psm1 (coming soon)
└── bootstrap.ps1

✅ Module Template
All modules must follow this structure:
Header comment with summary
Import Prompts, FileSystem, Logging
Define ModuleName-Core
Define ModuleName (interactive wrapper)
Export both functions

✅ Logging
All modules must log actions using:
Write-ModuleLog "Message"
Logs are stored in:
~/OpsToolkit/logs/

✅ Naming Conventions
• 	Modules: Install-Thing.psm1
• 	Functions: Install-Thing and Install-Thing-Core
• 	Utility modules live in Modules/Utility/
• 	No global variables except $Script:Root

✅ Pull Requests
All PRs must include:
• 	Summary of changes
• 	Why the change is needed
• 	Testing steps
• 	Screenshots (if UI‑related)

✅ Code Style
• 	Use 4‑space indentation
• 	Avoid aliases (ls, cat, etc.)
• 	Prefer Join-Path over string concatenation
• 	Use Try/Catch for all external calls
• 	Avoid modifying global state

✅ Testing
Before submitting:
1. 	Run the module directly
2. 	Run it through the Launcher
3. 	Run it through the Master Installer
4. 	Verify logs
5. 	Verify no unexpected registry or system changes

✅ Thank You
OpsToolkit grows through community contributions.
Your improvements help everyone build faster, safer, and cleaner Windows environments.