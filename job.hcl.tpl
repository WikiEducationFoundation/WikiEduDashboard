job "rails" {
  datacenters = ["dc1"]

  group "web" {
    network {
      mode = "bridge"
    }

    service {
      name = "rails"
      tags = ["app"]
      port = "5000"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "redis-sidekiq"
              local_bind_port  = 6379
            }
            upstreams {
              destination_name = "memcache"
              local_bind_port  = 11211
            }
            upstreams {
              destination_name = "mariadb"
              local_bind_port  = 3306
            }
          }
        }
      }
    }

    task "rails_server" {
      driver = "docker"

      config {
        image = "978bcc.wikiedu.org/wikiedu-web:latest"
        ports = ["http"]
        command = "rails"
        args = ["server", "-b", "0.0.0.0", "-p", "5000"]
        auth {
          username = "{{ env "WIKIED_DOCKER_USER" }}"
          password = "{{ env "WIKIED_DOCKER_PW" }}"
        }
      }

      resources {
        cpu    = 1500
        memory = 1024
      }

      env {
        {{range $key, $value := .Env}}
        {{$key}} = "{{$value}}"
        {{end}}
      }
    }
  }

  group "background_job" {
    network {
      mode = "bridge"
    }

    service {
      name = "sidekiq"
      tags = ["app"]

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "redis-sidekiq"
              local_bind_port  = 6379
            }
            upstreams {
              destination_name = "memcache"
              local_bind_port  = 11211
            }
            upstreams {
              destination_name = "mariadb"
              local_bind_port  = 3306
            }
          }
        }
      }
    }

    task "sidekiq" {
      driver = "docker"

      config {
        image = "978bcc.wikiedu.org/wikiedu-web:latest"
        command = "bundle"
        args = ["exec", "sidekiq"]
        auth {
          username = "{{ env "WIKIED_DOCKER_USER" }}"
          password = "{{ env "WIKIED_DOCKER_PW" }}"
        }
      }

      resources {
        cpu    = 1500
        memory = 1024
      }

      env {
        {{range $key, $value := .Env}}
        {{$key}} = "{{$value}}"
        {{end}}
      }
    }
  }
}

