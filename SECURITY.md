# Security Policy

## Supported Versions

Security fixes are provided for the latest release and the current default branch.

| Version | Supported |
| --- | --- |
| Latest release | Yes |
| Default branch | Yes |
| Older releases | No |

## Reporting A Vulnerability

Please use GitHub's private vulnerability reporting feature from the repository's Security tab. Do not open a public issue for a vulnerability that could expose users or provide a practical exploitation path.

Include the affected version, macOS version, reproduction steps, impact, and any suggested mitigation. Remove serial numbers, account names, full system profiles, and other personal data before attaching diagnostics.

You should receive an initial response within seven days. A confirmed issue will be tracked privately until a fix or mitigation is available.

## Scope

Security reports include, but are not limited to:

- unintended privilege or permission use
- persistence or system configuration changes not disclosed in the documentation
- execution of untrusted input
- collection or transmission of user or display data
- release artifact or update-chain integrity problems

A display mode that is unavailable, a brief black screen during switching, or a compatibility regression caused by private macOS APIs is normally a bug rather than a security vulnerability. Report those through the bug template unless they create a separate security impact.

## Release Integrity

Release archives include a SHA-256 checksum. Current public builds are ad-hoc signed and not notarized; verify the checksum and download only from this repository's GitHub Releases page.
