[Back to README](../README.md)

## Contributing

Testing is very important to the health of the Wiki Ed Dashboard as a whole. As part of a holistic testing strategy, the project utilizes the following testing stack:

* [RSpec](https://github.com/rspec/rspec) for unit tests (model and controller specs, and specs for plain old Ruby object)
* [Capybara](https://github.com/teamcapybara/capybara) for end-to-end integration testing.
* [Jest](https://facebook.github.io/jest/) for testing front-end utilities and React.js components

The tests are run on Travis for continuous integration purposes. Upon a successful unit test run — excluding feature tests — on the `production` branch, Travis will deploy the `production` branch to the production environment.

Write tests for the applicable parts of your contribution wherever possible.

## Running tests

#### Rspec unit and feature tests
Running `rspec` will run all model, controller, and integration tests (found in `spec/features`), as well as any other specs in the `spec` directory (such as classes in `lib` and `presenters`). Running `rspec spec/features` will run just the integration tests. You can pass any directory to `rspec` to run specs in just that directory, such as `rspec spec/models`.

If there are deprecations warnings in the development build of the javascript assets,
this can cause feature specs to fail. Run `yarn build` to get the production build,
which will not include the deprecation warnings.

#### Javascript tests
Running `yarn test` will run the entire client-side test suite. During development, you can use `jest --watch` to run Jest in watch mode. This works similarly to guard, re-running relevant tests whenever the corresponding files change.

### Server and client tests together
You can run the entire test suite, including a fresh compilation of assets, with `yarn build && rspec && yarn test`.

## Test Coverage
All new code should be covered with appropriate tests. In most cases, new features should be covered by RSpec feature specs.

## RSpec Test Coverage
Istanbul is used to provide JavaScript test coverage for RSpec feature tests, in addition to the Ruby coverage provided by simplecov. When the full test suite is run, the JavaScript report is generated and can be
accessed at `http://localhost:3000/js_coverage/index.html` which means to view the report you have to have the server running
by doing `rails s`

To generate the coverage report, run the following commands

```bash
yarn coverage
COVERAGE=true bundle exec rspec spec/
```
