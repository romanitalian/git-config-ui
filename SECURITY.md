# Security

## Reporting a vulnerability

Please **do not** open a public issue for security-sensitive reports.

Use one of the following:

1. **GitHub**: open a **private security advisory** from the repository’s **Security** tab (if enabled for the repo).
2. **Maintainers**: contact the repository owners via GitHub (e.g. direct message if available) with enough detail to reproduce or assess the issue.

Include: affected version or commit, steps to reproduce, and impact if known.

We will aim to acknowledge receipt and coordinate a fix and disclosure timeline when possible.

## Scope

This project is a local macOS utility that reads and writes your user Git configuration via `/usr/bin/git`. It does not intentionally collect or transmit data over the network. Reports about dependency vulnerabilities in development-only test libraries are still welcome if they affect maintainer or CI workflows.
