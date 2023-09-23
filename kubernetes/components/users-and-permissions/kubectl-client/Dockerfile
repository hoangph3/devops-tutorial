FROM python:3.8-slim-buster
RUN apt -y update && apt -y install curl telnet nano && curl -L -O https://dl.k8s.io/v1.23.5/kubernetes-client-linux-amd64.tar.gz && tar zvxf kubernetes-client-linux-amd64.tar.gz kubernetes/client/bin/kubectl && mv kubernetes/client/bin/kubectl / && rm -rf kubernetes && rm -f kubernetes-client-linux-amd64.tar.gz
CMD ["sleep", "9999999"]
# ADD kubectl-proxy.sh /kubectl-proxy.sh
# RUN chmod +x kubectl-proxy.sh
# ENTRYPOINT /kubectl-proxy.sh