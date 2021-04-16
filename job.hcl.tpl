job "rails" {
  datacenters = ["dc1"]

  group "web" {
    network {
      mode = "bridge"
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

      config {
        image = "a5641d.wikiedu.org/wikiedu-web:latest"
        ports = ["http"]
        command = "bundle"
        args = ["exec", "puma", "-b", "0.0.0.0", "-p", "5000", "--preload", "-w", "4", "-t", "1:1"]
        auth {
          username = "docker"
          password = "testpass"
        }
      }

      resources {
        # Dependent on the worker count (4)
        cpu    = 7500 # 2000 * 4, -500 for the envoy proxy
        memory = 4096 # 1024 * 4
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
        image = "a5641d.wikiedu.org/wikiedu-web:latest"
        command = "bundle"
        args = ["exec", "sidekiq", "-q", "constant_update", "-c", "1"]
        auth {
          username = "docker"
          password = "testpass"
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

  group "sidekiq-daily" {
    network {
      mode = "bridge"
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
        image = "a5641d.wikiedu.org/wikiedu-web:latest"
        command = "bundle"
        args = ["exec", "sidekiq", "-q", "daily_update", "-c", "1"]
        auth {
          username = "docker"
          password = "testpass"
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

  group "sidekiq-default" {
    network {
      mode = "bridge"
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
        image = "a5641d.wikiedu.org/wikiedu-web:latest"
        command = "bundle"
        args = ["exec", "sidekiq", "-q", "default", "-c", "1"]
        auth {
          username = "docker"
          password = "testpass"
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

  group "sidekiq-long" {
    network {
      mode = "bridge"
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
        image = "a5641d.wikiedu.org/wikiedu-web:latest"
        command = "bundle"
        args = ["exec", "sidekiq", "-q", "long_update", "-c", "1"]
        auth {
          username = "docker"
          password = "testpass"
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

  group "sidekiq-medium" {
    network {
      mode = "bridge"
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
        image = "a5641d.wikiedu.org/wikiedu-web:latest"
        command = "bundle"
        args = ["exec", "sidekiq", "-q", "medium_update", "-c", "1"]
        auth {
          username = "docker"
          password = "testpass"
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

  group "sidekiq-short" {
    network {
      mode = "bridge"
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
        image = "a5641d.wikiedu.org/wikiedu-web:latest"
        command = "bundle"
        args = ["exec", "sidekiq", "-q", "short_update", "-c", "1"]
        auth {
          username = "docker"
          password = "testpass"
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

