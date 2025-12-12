# Deployment Guide

This guide explains how to deploy OpsToolkit documentation to GitHub Pages.

## Prerequisites

- A GitHub account
- Repository with documentation
- Custom domain (optional)

## Steps

1. Enable GitHub Pages in your repository settings (Settings > Pages).
2. Point DNS to GitHub Pages (`A` records to `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, and `185.199.111.153` and a `CNAME` record to `<user>.github.io`).
3. Configure your custom domain in the repository settings (if applicable).
4. Wait for DNS propagation (can take up to 48 hours).
5. Verify your site is accessible at your custom domain or `<user>.github.io/<repo>`.

## Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Configuring a custom domain for GitHub Pages](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)
- [Managing a custom domain for your GitHub Pages site](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)
