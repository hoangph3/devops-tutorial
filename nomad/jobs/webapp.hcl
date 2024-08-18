job "app" {
  datacenters = ["dc1"]

  group "flask" {
    count = 1

    scaling {
      enabled = true
      min = 0
      max = 1
    }

    task "flask" {
      driver = "docker"
      config {
        image = "flask-app:0.0.1"
        ports = ["http"]
      }

      template {
        data = <<EOF
        REDIS_URL = {{ key "REDIS_URL" }}
        EOF
        destination = "local/.env"
        env = true
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
      port "http" {
        static = 8000
        to = 8000
      }
    }

    service {
      name = "app-flask"
      port = "http"
    }
  }

  group "nginx" {
    count = 1

    scaling {
      enabled = true
      min = 0
      max = 1
    }

    task "nginx" {
      driver = "docker"
      config {
        image = "nginx:alpine"
        ports = ["http"]
        volumes = [
          "local/nginx.conf:/etc/nginx/nginx.conf",
        ]
      }

      template {
        data = <<EOF
        {{ key "NGINX_CONFIG" }}
        EOF
        destination = "local/nginx.conf"
        change_mode = "restart"
      }

      logs {
        max_files     = 10
        max_file_size = 15
      }

      resources {
        cpu    = 200
        memory = 300
      }
    }

    network {
      port "http" {
        static = 80
        to = 80
      }
    }

    service {
      name = "app-nginx"
      port = "http"
    }
  }
}