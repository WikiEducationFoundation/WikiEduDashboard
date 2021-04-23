# apt Buildpack

[![Version](https://img.shields.io/badge/dynamic/json?url=https://cnb-registry-api.herokuapp.com/api/v1/buildpacks/fagiani/apt&label=Version&query=$.latest.version)](https://github.com/fagiani/apt-buildpack)

This is a [Cloud Native Buildpack](https://buildpacks.io/) that adds support for `apt`-based dependencies during both build and runtime.

This buildpack is based on the [heroku-buildpack-apt](https://github.com/heroku/heroku-buildpack-apt)


## Usage

This buildpack is not meant to be used on its own, and instead should be in used in combination with other buildpacks.

Include a list of `apt` package names to be installed in a file named `Aptfile`

The buildpack automatically downloads and installs the packages when you run a build:

```
$ pack build --buildpack fagiani/apt myapp
```

#### Aptfile

    # you can list packages
    libexample-dev

    # or include links to specific .deb files
    http://downloads.sourceforge.net/project/wkhtmltopdf/0.12.1/wkhtmltox-0.12.1_linux-precise-amd64.deb

    # or add custom apt repos (only required if using packages outside of the standard Ubuntu APT repositories)
    :repo:deb http://cz.archive.ubuntu.com/ubuntu artful main universe

## License

MIT

## Disclaimer

This buildpack is experimental and not yet intended for production use.
