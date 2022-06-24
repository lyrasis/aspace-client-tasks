ArchivesSpace Client Tasks
==========================

About
-----

This repo contains a collection of Thor tasks used to get data into shape for ArchivesSpace and to interact with the ArchivesSpace API via the ruby [archivesspace-client](https://github.com/lyrasis/archivesspace-client). It is intended to be either a standalone Thor CLI or a companion to a migration project via [kiba-extend-project](https://github.com/lyrasis/kiba-extend-project).

The repo contains generalized, commonly-used tasks in the `common` folder, as well as project-specific example tasks in the `project_name` folder.

Set-up
------------

### Installation

1. If you want to download this as a standalone Thor CLI, create from the template as described at [Creating a repository from a template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)
2. If you want to add this to an existing migration project, the easiest way is to download the .zip and unzip at the top level of your project since the zip does not contain any of the .git files. You can then track it as a subdirectory of your migration project

After you have the repo in place you'll need to `cd` to the directory and run `bundle install` to install the required gems.

### File configuration

In order to work with ERB templates, the archivesspace-client requires the `ARCHIVESSPACE_CLIENT_TEMPLATES_PATH` environment variable to point to the directory where your templates live. I also decided to set the ArchivesSpace login credentials as environment variables so that I could separate them from the code. The variables are set in a .env file. Rename .env.example as such and set these variables. The included [dotenv](https://github.com/bkeepers/dotenv) gem "loads variables from a .env file into ENV when the environment is bootstrapped."

`aspace_client.rb` is the main configuration file. It contains variables such as the default location of your data files, default location to place log files, and base URI for your ArchivesSpace API instance. Follow the comments in the file to set these up.

Design Decisions
----------------

For now, I've decided to keep this as a simple repository with generalized, commonly-used tasks in the `common` folder. I wanted the repository to be fairly customizable without too much overhead. I also wanted this CLI to be easily integrated into a migration project.

The common tasks are written at the point of need. As the need arises I'll add more common tasks. Feel free to send a PR with additions as well.

Contents
--------

The main files at the top are `Thorfile`, `aspace_client.rb`, and `.env`. As mentioned before, `aspace_client.rb` sets most of the configuration for the CLI and `.env` sets the environment variables. `Thorfile` loads all the Thor files.

The rest of the content is organized into subfolders. `common` contains the aforementioned commonly-used tasks. I recommend organizing any local, custom tasks in another folder named whatever makes sense. I added example local/custom tasks from a previous project to the folder `project_name`. You can organize tasks however you want, but if you look at the common tasks, they're organized by high-level ArchivesSpace entities (agents, subjects, classifications, archival objects).

In addition to the tasks, there's also a folder `templates`. This contains example ERB templates to call when sending data to ArchivesSpace. Feel free to put your templates here or wherever makes sense if you intend to use templates. See the [archivesspace-client repository](https://github.com/lyrasis/archivesspace-client#templates) for more info about how it uses templates.

You'll also notice a subfolder of `templates` named `utilities`. These are simple ruby scripts that will take the input from a data file and run it through a template so that you can test the output before sending the data through one of the POST tasks.

How it Works
-------------

At its core, Thor is a "simple and efficient tool for building self-documenting command line utilities." If you're unfamiliar with Thor, I recommend checking out [the repo](https://github.com/rails/thor) which has nice documentation.

All of the files in `common` and `project_name` contain Thor tasks. `Thorfile` calls `chains.thor`, which calls `aspace_client.rb`, which loads all the other ruby files.

You can see a list of available tasks by running `thor list`. You'll notice that tasks are organized into sections - this is because the task classes are organized under modules. If you want to further filter the list, you can navigate the module-class-method path. For example, `thor common` will list all available tasks under the `common` module. `thor common:agents` will list all available tasks in the `common` module, `agents` class. 

In order to run a specific task, use the `thor` command with the full method path. For example, `thor common:agents:get_people`. If the task requires parameter inputs (you'll see expected parameters in all caps), then run the command but add the parameters spaced out in order. For example, `thor common:agents:post_corporate "/folder/path" filename corporate`.

While you can call any task, `chains.thor` can be used to build in-out tasks that chain together different tasks to make it easy to build ETL workflows. `registries.rb` is where you can build in-out registries that point to in and out files that can be called in a chain. It also contains a utility task, `save`, that makes it easy to save the output of a chain. Currently, POST tasks expect a data file, so you'll need to call the `save` task in a chain before calling a POST task.

`chains.thor` utilizes a modified method, `execute`, to invoke (call) another Thor task. This, and the fact that GET and processing tasks output data in a predictable manner (if you're familiar with ArchivesSpace API responses), allows you to chain together tasks. Then, all you have to do is call your chain task and it'll run all the tasks for a given in-out workflow.

I put two examples in `chains.thor` - one save chain and one POST chain.