data_dir = "/etc/nomad.d/data"

bind_addr = "0.0.0.0"

log_level = "INFO"
log_file  = "/etc/nomad.d/nomad.log"

server {
  enabled = true
  bootstrap_expect = 1
}

client {
  enabled = true
  servers = ["0.0.0.0:4647"]
}

consul {
  address = "0.0.0.0:8500"
  token = "a14115ca-5fc8-461d-8ad3-f0a1acdacc0d"
}

acl {
  enabled = true
}
