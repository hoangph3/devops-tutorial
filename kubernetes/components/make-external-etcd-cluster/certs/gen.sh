cfssl gencert \
    -initca config/ca-csr.json | cfssljson -bare ca

cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    --config=config/ca-config.json \
    -profile=kubernetes config/server-csr.json | cfssljson -bare server

