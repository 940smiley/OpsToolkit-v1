# Deployment Guide

This guide explains how to deploy OpsToolkit documentation to GitHub Pages.

## GitHub Pages Setup

To host your OpsToolkit documentation on GitHub Pages:

1. Enable GitHub Pages in your repository settings (Settings → Pages).
2. Point DNS to GitHub Pages (`A` records to `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, and `185.199.111.153` and a `CNAME` record to `<user>.github.io`).
3. Configure your custom domain in the repository settings (if applicable).
4. Wait for DNS propagation (can take up to 48 hours).
5. Verify your site is accessible at `https://<user>.github.io/<repository>` or your custom domain.

## Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
