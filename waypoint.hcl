project = "wikiedu"

runner {
  enabled = true

  data_source "git" {
    url  = "https://github.com/speedshop/WikiEduDashboard.git"
    ref  = "hashistack"
  }
}

app "wikiedu-web" {
  build {
    use "pack" {
      builder = "heroku/buildpacks:20"
      buildpacks = [
        "urn:cnb:registry:heroku/ruby",
        "./apt-buildpack-0.1.0"
      ]
      static_environment = {
        "CURL_CONNECT_TIMEOUT" = "30"
        "CURL_TIMEOUT" = "120"
        # Rails prioritizes a SECRET_KEY_BASE from the ENV over one in secrets.yml
        # The heroku ruby buildpack will generate a SECRET_KEY_BASE if one is not already present.
        # So, we must provide the production SECRET_KEY_BASE to the build environment to make sure it doesn't
        # get overwritten by a random one, and thereby invalidate sessions upon deployment.
        "SECRET_KEY_BASE" = yamldecode(file(abspath("./config/application.yml"))).secret_key_base
      }
    }
    registry {
      use "docker" {
        image = "docker.wikiedu.org/wikiedu-web"
        tag = "latest"
      }
    }
  }

  deploy {
    use "exec" {
      command = ["nomad","run","<TPL>"]

      template {
        path = "${path.app}/job.hcl.tpl"
      }
    }
  }
}
