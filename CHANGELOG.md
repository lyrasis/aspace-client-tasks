# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

*NOTE:* Version 1.0.0 was release before this changelog was implemented, so those changes are not documented.

## [Unreleased]

<!-- ### Added  -->


### Changed

- Refactored `get`, `get_all_ids`, `post`, and `delete` methods for agents
  - Instead of having static methods for each agent type, these methods are now dynamically defined using `define_method`


<!-- ### Deprecated -->


<!-- ### Fixed -->

<!-- ### Removed -->

<!-- ### Security -->

## [1.1.0] - 2022-06-24

### Added 

- Changelog
- Logging to all POST methods

### Changed

- Refactored `execute` method with optional arguments

### Deprecated

- Removing `post_all_agents` method in the next major release. See issue #17

### Fixed

- Fixed bug in `post_subjects` method

[unreleased]: https://github.com/lyrasis/aspace-client-tasks/compare/v1.1.0..HEAD
[1.1.0]: https://github.com/lyrasis/aspace-client-tasks/compare/v1.0.0..v1.1.0
