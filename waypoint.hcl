project = "wikiedu"

app "wikiedu-web" {
  runner {
    enabled = true

    data_source "git" {
      url  = "https://github.com/speedshop/WikiEduDashboard.git"
      ref  = "hashistack"
    }
  }

  build {
    use "pack" {
      builder = "heroku/buildpacks:20"
      static_environment = {
        "CURL_CONNECT_TIMEOUT" = "30"
        "CURL_TIMEOUT" = "120"
      }
    }
    registry {
      use "docker" {
        image = "978bcc.wikiedu.org/wikiedu-web"
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