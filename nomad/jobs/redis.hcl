job "db" {
  datacenters = ["dc1"]

  group "redis" {
    count = 1

    scaling {
      enabled = true
      min = 0
      max = 1
    }

    task "redis" {
      driver = "docker"
      config {
        image = "redis:7.0.7-alpine"
        ports = ["db"]
      }

      logs {
        max_files     = 10
        max_file_size = 15
      }

      resources {
        cpu    = 100
        memory = 200
      }
    }

    network {
      port "db" {
        static = 6380
        to = 6379
      }
    }

    service {
      name = "db-redis"
      port = "db"
    }
  }
}