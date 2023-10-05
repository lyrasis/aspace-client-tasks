# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

*NOTE:* Version 1.0.0 was release before this changelog was implemented, so those changes are not documented.

## [Unreleased]

### Added

- documentation to methods where documentation was lacking
- `get_[module_type]_all_ids` for classifications, subjects, and resources
- `delete_[module_type]` for classifications, subjects, and resources
- `resources.json.jbuilder` jbuilder template

### Changed

- all methods that had a `field` parameter now have a `fields` parameter that accepts
  a string or array, except `common:container_profiles:attach_container_profiles` and
  `common:top_containers:attach_top_containers`. This is because ASpace expects a single
  ref for these two entities
- removed hard-coded `page_size` query parameter since `Archivesspace::Configuration.page_size`
  is already set as a default. `page_size` can be added to individual queries to override the default
- removed `.to_sym` for POST methods because of the change in template functionality in archivesspace-client
- updated template reference in `chains.thor` based on change in template functionality in archivesspace-client

<!-- ### Deprecated -->

### Fixed

- fixed bug in `common:objects:make_index_aos_dynamic` where the index return was in the wrong location
- fixed typos in `common:objects:move_aos_children_to_parents`
- fixed bug in `common:subjects:attach_subjects`. needed to flatten multi-level array
- updated `Gemfile` to point to master branch of archivesspace-client

<!-- ### Removed

### Security -->

## [2.2.0] - 2023-03-24

### Added

- `templater.rb` set of tools for creating ERB templates
- `utils:templatize` method/task to create ERB templates from the command line
- `common:objects:attach_resources` method
- `common:locations:attach_locations` method
- `common:locations:get_locations` method
- `common:locations:get_locations_all_ids` method
- `common:locations:make_index` method
- `common:locations:post_locations` method
- `common:locations:delete_locations` method
- `common:container_profiles:attach_container_profiles` method
- `common:container_profiles:delete_container_profiles` method
- `common:container_profiles:get_container_profiles` method
- `common:container_profiles:get_container_profiles_all_ids` method
- `common:container_profiles:make_index` method
- `common:container_profiles:post_container_profiles` method
- `common:top_containers:attach_top_containers` method
- `common:top_containers:delete_top_containers` method
- `common:top_containers:get_top_containers` method
- `common:top_containers:get_top_containers_all_ids` method
- `common:top_containers:make_index` method
- `common:top_containers:post_top_containers` method
- `registries:get_csv` method
- `registries:json_to_csv` method

<!-- ### Changed -->

<!-- ### Deprecated -->

<!-- ### Fixed -->
- fixed typo in `common:objects:move_aos_children_to_parents`

<!-- ### Removed -->

<!-- ### Security -->

## [2.1.0] - 2023-02-08

### Added

- `common:objects:make_index_aos_dynamic` method
- `common:objects:move_aos_children_to_parents` method
- `common:objects:post_aos_children` method
- `common:objects:post_aos_children_intermediary_grouping` method
- `get_children_of_ao` method
- aos_tester_iterate.rb example template script for catching breaking template issues

### Changed

- Changed all remaining `invoke` method calls to `execute` method calls
- Generalized all of the directory references in the template utility scripts

<!-- ### Deprecated -->

<!-- ### Fixed -->

### Removed

- Removed all `*args` method parameters. This was a janky bandaid for calling `invoke` method calls multiple times within a given context

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

[unreleased]: https://github.com/lyrasis/aspace-client-tasks/compare/v2.2.0..HEAD
[2.2.0]: https://github.com/lyrasis/aspace-client-tasks/compare/v2.1.0..v2.2.0
[2.1.0]: https://github.com/lyrasis/aspace-client-tasks/compare/v2.0.0..v2.1.0
[2.0.0]: https://github.com/lyrasis/aspace-client-tasks/compare/v1.1.0..v2.0.0
[1.1.0]: https://github.com/lyrasis/aspace-client-tasks/compare/v1.0.0..v1.1.0
