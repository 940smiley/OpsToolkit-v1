# Contributing to OpsToolkit

OpsToolkit is designed to be modular, auditable, and contributor-friendly. This guide explains how to add modules, improve existing ones, and maintain consistency across the toolkit.

## Principles
- **Auditability:** every action must be visible and logged.
- **Predictability:** no hidden behavior, no side effects.
- **Modularity:** one module = one responsibility.
- **Reversibility:** avoid destructive changes.
- **Clarity:** code should be readable and self-documenting.
- **Contributor empowerment:** no magic, no black boxes.

## Folder Structure
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
│   └── Update-OpsToolkit.psm1 (coming soon)
├── scripts/
└── bootstrap.ps1
```

## Module Template
All modules should include:
1. Header comment with summary.
2. Imports for `Prompts`, `FileSystem`, and `Logging` as needed.
3. A `*-Core` function for non-interactive execution.
4. A wrapper function that calls `*-Core` with user prompts.
5. `Export-ModuleMember` for both functions.

### Logging
- Use `Write-ModuleLog "Message"` for auditable actions.
- Logs are stored in `~/OpsToolkit/logs/`.

### Naming Conventions
- Modules: `Install-Thing.psm1`
- Functions: `Install-Thing` and `Install-Thing-Core`
- Utility modules live in `modules/Utility/`
- Avoid global variables except `$Script:Root`

### Pull Requests
Please include:
- Summary of changes and why they are needed.
- Testing steps with expected outcomes.
- Screenshots for UI-related updates.

### Code Style
- Use 4-space indentation.
- Avoid aliases (e.g., `ls`, `cat`).
- Prefer `Join-Path` over string concatenation.
- Use `Try/Catch` for all external calls.
- Avoid modifying global state.

### Testing Checklist
1. Run the module directly.
2. Run it through the Launcher.
3. Run it through the Master Installer.
4. Verify logs are written.
5. Confirm no unexpected registry or system changes.

## Thank You
OpsToolkit grows through community contributions. Your improvements help everyone build faster, safer, and cleaner Windows environments.
