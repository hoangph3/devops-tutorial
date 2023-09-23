#! /bin/bash

mkcert -install

mkcert -cert-file $1.crt \
  -key-file $1.key \
  localhost 127.0.0.1 \
  site1.example.com \
  site2.example.com
