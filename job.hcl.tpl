job "rails" {
  datacenters = ["dc1"]

  group "web" {
    count = 2

    network {
      mode = "bridge"
    }

    volume "rails" {
      type      = "host"
      read_only = false
      source    = "rails"
    }

    service {
      name = "puma"
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

      volume_mount {
        volume      = "rails"
        destination = "/workspace/public/system"
        read_only   = false
      }

      config {
        image = "docker.wikiedu.org/wikiedu-web:latest"
        ports = ["http"]
        command = "puma"
        args = ["-b", "tcp://0.0.0.0", "-p", "5000", "--preload", "-w", "2", "-t", "1:1"]
        auth = jsondecode(file("./dockerAuth.json"))
      }

      resources {
        # Dependent on the worker count (4)
        cpu    = 3000 # 2000 * 4, -500 for the envoy proxy
        memory = 2048 # 1024 * 4
      }

      env {
        {{range $key, $value := .Env}}
        {{$key}} = "{{$value}}"
        {{end}}
      }
    }
  }

  group "sidekiq-constant" {
    network {
      mode = "bridge"
    }

    constraint {
      attribute = "${node.unique.name}"
      operator  = "!="
      value     = "node-railsweb"
    }

    service {
      name = "sidekiq-constant"
      tags = ["app", "sidekiq"]

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
        image = "docker.wikiedu.org/wikiedu-web:latest"
        command = "sidekiq"
        args = ["-q", "constant_update", "-c", "1"]
        auth = jsondecode(file("./dockerAuth.json"))
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

  group "sidekiq-daily" {
    network {
      mode = "bridge"
    }

    constraint {
      attribute = "${node.unique.name}"
      operator  = "!="
      value     = "node-railsweb"
    }

    service {
      name = "sidekiq-daily"
      tags = ["app", "sidekiq"]

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
        image = "docker.wikiedu.org/wikiedu-web:latest"
        command = "sidekiq"
        args = ["-q", "daily_update", "-c", "1"]
        auth = jsondecode(file("./dockerAuth.json"))
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

  group "sidekiq-default" {
    network {
      mode = "bridge"
    }

    constraint {
      attribute = "${node.unique.name}"
      operator  = "!="
      value     = "node-railsweb"
    }

    service {
      name = "sidekiq-default"
      tags = ["app", "sidekiq"]

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
        image = "docker.wikiedu.org/wikiedu-web:latest"
        command = "sidekiq"
        args = ["-q", "default", "-c", "1"]
        auth = jsondecode(file("./dockerAuth.json"))
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

  group "sidekiq-long" {
    network {
      mode = "bridge"
    }

    constraint {
      attribute = "${node.unique.name}"
      operator  = "!="
      value     = "node-railsweb"
    }

    service {
      name = "sidekiq-long"
      tags = ["app", "sidekiq"]

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
        image = "docker.wikiedu.org/wikiedu-web:latest"
        command = "sidekiq"
        args = ["-q", "long_update", "-c", "1"]
        auth = jsondecode(file("./dockerAuth.json"))
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

  group "sidekiq-medium" {
    network {
      mode = "bridge"
    }

    constraint {
      attribute = "${node.unique.name}"
      operator  = "!="
      value     = "node-railsweb"
    }

    service {
      name = "sidekiq-medium"
      tags = ["app", "sidekiq"]

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
        image = "docker.wikiedu.org/wikiedu-web:latest"
        command = "sidekiq"
        args = ["-q", "medium_update", "-c", "1"]
        auth = jsondecode(file("./dockerAuth.json"))
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

  group "sidekiq-short" {
    network {
      mode = "bridge"
    }

    constraint {
      attribute = "${node.unique.name}"
      operator  = "!="
      value     = "node-railsweb"
    }

    service {
      name = "sidekiq-short"
      tags = ["app", "sidekiq"]

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
        image = "docker.wikiedu.org/wikiedu-web:latest"
        command = "sidekiq"
        args = ["-q", "short_update", "-c", "1"]
        auth = jsondecode(file("./dockerAuth.json"))
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

