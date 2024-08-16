job "nginx" {
  datacenters = ["dc1"]

  group "nginx-group" {
    count = 1

    network {
      port "http" {
        static = 8082
        to = 8081
      }
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
        {{ key "local/nginx/nginx.conf" }}
        EOF
        destination = "local/nginx.conf"
        change_mode = "restart"
      }
    }
  }
}
