# Changelog

All notable changes to this project will be documented in this file.

The following list of major changes can also be found under designated git tags.

>The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
<!--
## [version number] - YEAR-MONTH-DAY

### Sections
'Added' for new features.
'Changed' for changes in existing functionality.
'Deprecated' for soon-to-be removed features.
'Removed' for now removed features.
'Fixed' for any bug fixes.
'Security' in case of vulnerabilities.

[version number]: Link
-->

[comment]: <> (## [Unreleased])

## [v1.0.2] - 2023-06-03

### Added

- New list view static icon for Playdate OS 2.0

## [v1.0.1] - 2023-03-09

### Changed

- A couple of variables from global to local.
- Updated all files to latest year, due to new version.

### Fixed

- Changes made to related code where `sprite:copy()` is used, as it was not working correctly in SDK 1.13.2:
    - Using `sprite.className` instead of `sprite:isa()` to detect sprite type. 
    - Using custom snapshot functions to properly copy necessary sprite attributes.
- Fixed typo for a global variable `Input`.

## [v1.0] - 2022-12-08

### Added

- Version v1.0 of the game.
- `CHANGELOG.md` file, a log of changes between current and future releases.
- `CODE_OF_CONDUCT.md` file, containing GitHub's community conduct rules.
- `CONTRIBUTING.md` file, list or rules and notes on contributing to the project.
- `LICENSE` file, containing GNU v3 licence text and updates to all files with license references.
- `DEV_NOTES.md` file, containing an extension to the documentation present in lua files.
