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
        image = "nginx:latest"
        ports = ["http"]
        mount {
          type   = "bind"
          source = "local"
          target = "/etc/nginx"
        }
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
