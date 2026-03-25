# Security Policy

## Supported Versions

The latest commit on `main` is the supported version.

## Reporting a Vulnerability

Please do not open public issues for sensitive vulnerabilities.

Use GitHub private vulnerability reporting for this repository whenever possible.

Include:

- Affected component/file
- Reproduction steps
- Impact assessment
- Suggested remediation (if available)

You should receive an acknowledgement within a few business days.

## Repository Security Controls

- Branch protection is enabled on `main` and requires pull requests.
- Dependabot security updates are enabled.
- Automated security fixes are enabled.
- Secret scanning and push protection are enabled.
- CodeQL default setup is enabled in repository security settings.

## Security Notes

- This app is local-first and stores data in IndexedDB.
- Exported files may contain sensitive inventory information.
- Desktop builds should be code-signed before broad distribution.
