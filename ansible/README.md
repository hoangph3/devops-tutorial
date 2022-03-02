## demo app - developing with ansible

#### To start VMs

Step 1: Create hosts server

    vagrant up

Step 2: Checking connection

    sshpass -p vagrant ssh vagrant@192.168.56.10
    sshpass -p vagrant ssh vagrant@192.168.56.11

#### With ansible-playbook

Use `tasks` in playbook:

    ansible-playbook -i inventory playbook-01.yml

Use `vars` in playbook:

    ansible-playbook -i inventory playbook-02.yml

Access system information in playbook:

    ansible all -i inventory -m setup
    ansible all -i inventory -m setup -a "filter=*ipv4*"
    ansible-playbook -i inventory playbook-03.yml