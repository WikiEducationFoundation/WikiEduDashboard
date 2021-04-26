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
        "./apt-buildpack-0.1.0",
        "urn:cnb:registry:heroku/ruby"
      ]
      static_environment = {
        "CURL_CONNECT_TIMEOUT" = "30"
        "CURL_TIMEOUT" = "120"
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
