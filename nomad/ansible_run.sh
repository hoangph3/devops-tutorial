docker run --rm --net=host \
-v $(pwd)/ansible:/ansible \
willhallonline/ansible:alpine ansible-playbook $1
