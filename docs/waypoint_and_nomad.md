In conjunction with a server cluster managed with the [wikieduinfra repo](https://github.com/WikiEducationFoundation/wikieduinfra), the Dashboard uses Waypoint and Nomad to build and deploy to production.

Use `waypoint up` to (attempt to) both build and deploy the app. (This is equivalent to `waypoint up` followed by `waypoint build`.) This packages the local project directory — including the generated assets and the .gitignored files like `application.yml` and `database.yml` — into a Docker image, pushes it to docker.wikiedu.org, then deploys it as a set of puma and sidekiq jobs to replace to replace the running jobs from the previous deployment.

## Build

Use `waypoint build` to build an image and push it to the docker.wikiedu.org registry without deploying it.

Waypoint uses (and includes a specific version of) `pack`, the command-line tool of `buildpacks.io` (Cloud Native Buildpacks), to turn the Rails project into an executable Docker image.

The behavior of `pack` may vary based on version, and includes a number of relevant dependencies that can affect the Docker image. The most important factor is the buildpack API version(s) it supports, and how it interacts with the builder and buildpack versions via the `lifecycle` dependency.

`pack` takes a configuration from `waypoint.hcl` to determine which builder and which buildpacks to use, along with any necessary environment variables for the build (eg, SECRET_KEY_BASE). When `pack` executes the build, it uses builder along with the ordered set of buildpacks to generate a build image. Each buildpack specifies the `buildpack` API it is written for. We rely mainly on the heroku builder and [Ruby cloud native buildpack](https://github.com/heroku/buildpacks-ruby) to turn our more-or-less-standard Rails app into a runnable Docker image. The builder/buildpacks detect that it's a Rails app, add most of the dependencies, and insert a set of typical entrypoints, including the default `web` entrypoint. `pack` also provides `launcher`, which can be used as a basic entrypoint.

After a successful build, `waypoint` automatically tries to upload the image to our private docker registry, tagging it as `latest`.

## Deploy

Use `waypoint deploy` to deploy the latest uploaded image to our Nomad cluster, using the configuration from the "deploy" stanza of `waypoint.hcl`. This in turn uses `nomad` and a jobspec generated from the `job.hcl.tpl` template to run a connected set of tasks — `puma` and `sidekiq` using the image. The behavior of each task depends on:
 * the image itself
 * the entrypoint, command, and arguments specified in the task's `config` stanza
 * the persistent volume (if any) that the task mounts
 * the Nomad cluster environment, including the distribution of available CPU/memory across servers the "constraint" stanzas of `job.hcl.tpl` that limit/determine where a given task can be allocated
 * the amount of CPU and memory allocated, based on the "resources" stanza for the task

### Migrations

To run a migration:
1. Build and deploy an image that includes the migration.
2. `exec` into an instance (eg, by finding a job in the Nomad UI and clicking 'Exec').
3. `/cnb/lifecycle/launcher rails db:migrate`
