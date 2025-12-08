# GitHub Pages Setup

## Activation
1. Open **Settings > Pages** in your repository.
2. Choose **Deploy from a branch**.
3. Select `main` (or `docs` if created) and the `/` root folder.
4. Save to publish. First publish may take a minute.

## Optional /docs Structure
```
/docs
├── index.md
├── getting-started.md
└── changelog.md
```
Use a landing page that links to installer steps and module docs.

## Theme Configuration
- Enable the **minimal** or **cayman** theme for quick readability.
- Add a `_config.yml` in `/docs` to set title, description, and theme.

## Custom Domain
1. Add a `CNAME` file in `/docs` with your domain.
2. Point DNS to GitHub Pages (A records to `185.199.108-111.153` and `CNAME` to `<user>.github.io`).
3. Enable **Enforce HTTPS** once DNS resolves.

## CI/CD Deployment Suggestion
- Use GitHub Actions to build docs and publish to `gh-pages` on push to `main`.
- Include a job step to `actions/upload-pages-artifact` and `actions/deploy-pages`.

## Quick Checks
- Verify links with a link checker before deployment.
- Confirm images load correctly in the published site.
