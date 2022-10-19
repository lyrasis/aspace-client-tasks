# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

*NOTE:* Version 1.0.0 was release before this changelog was implemented, so those changes are not documented.

## [Unreleased]

<!-- ### Added -->

<!-- ### Changed -->

<!-- ### Deprecated -->

<!-- ### Fixed -->

<!-- ### Removed

<!-- ### Security -->

## [2.0.0] - 2022-10-19

### Added

- `get_json` method to read JSON data from file
  - needed since methods now accept data instead of files
- `get_accessions` method
- `get_accessions_all_ids` method
- `delete_accessions` method
- `make_index_accessions` method
- `post_accessions` method
- `turn_on_access_restrictions` method
- `update_accessions` method example
- Mixin module that contains the `execute` method

### Changed

- Refactored `get`, `get_all_ids`, `post`, and `delete` methods for agents
  - Instead of having static methods for each agent type, these methods are now dynamically defined using `define_method`
- Refactored all `post` methods to accept data rather than reading in a file
  - This makes the `post` methods more flexible when chaining methods together
- Added a countdown message for each `delete` and `post` method
- Moved `attach_x` (agents, subjects, classifications) to their respective classes
  - Makes more sense than having these methods in the Objects class since one can attach any of those entities to accessions as well
- Refactored the `chains.thor` examples to use `get_json`
- Changed `aspace_client.rb` log paths to be more reusable in conjuction with kiba-extend projects
- Monkey-patched Thor class to include `mixin` module
  - This replaces all of the `no_commands` blocks previously required in each file

<!-- ### Deprecated -->


### Fixed

- `common:subjects:make_index` now removes the spacing around dashes that ArchivesSpace inserts
  - conforms to common practice for how complex headings are formed
- added condition to `attach_x` methods to ensure the process doesn't override an array if it already exists, adding to it instead

### Removed

- Removed `post_all_agents` method in favor of the chaining capabilities of this app

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

[unreleased]: https://github.com/lyrasis/aspace-client-tasks/compare/v2.0.0..HEAD
[2.0.0]: https://github.com/lyrasis/aspace-client-tasks/compare/v1.1.0..v2.0.0
[1.1.0]: https://github.com/lyrasis/aspace-client-tasks/compare/v1.0.0..v1.1.0
