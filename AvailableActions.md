# Available GitHub Actions

## CI/CD Starters
- **PowerShell Module Lint/Test**
  - Trigger: `push`, `pull_request`
  - Steps: `actions/checkout`, `actions/setup-powershell`, run Pester or script validation.
- **Windows Build/Install Smoke Test**
  - Trigger: nightly schedule
  - Steps: provision Windows runner, execute key modules with `-WhatIf` where possible.

## Linting & Formatting
- **Markdown Lint** using `markdownlint-cli2`.
- **YAML Lint** using `ibiqlik/action-yamllint`.

## Security & Dependency Scans
- **CodeQL** for PowerShell and shell scripts.
- **Secret Scanning** with `trufflesecurity/trufflehog` or GitHub Advanced Security (if available).

## Release & Packaging
- **Semantic Release** to tag versions and generate notes.
- **Artifact Upload** to publish packaged scripts or logs from CI runs.

## Example Workflow Snippet
```yaml
name: PowerShell Validation
on: [push, pull_request]
jobs:
  lint:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-powershell@v1
      - name: Run PSScriptAnalyzer
        shell: pwsh
        run: |
          Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
          Invoke-ScriptAnalyzer -Path modules -Recurse -Severity Error
```
