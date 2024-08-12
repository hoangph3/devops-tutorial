data_dir = "/etc/consul.d/data"

bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
advertise_addr = "127.0.0.1"

server = true
bootstrap_expect = 1

ui = true

acl {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
}
