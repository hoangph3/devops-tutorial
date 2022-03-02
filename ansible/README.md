## demo app - developing with ansible

### To start VMs

Step 1: Create hosts server

    vagrant up

Step 2: Checking connection

    sshpass -p vagrant ssh vagrant@192.168.56.10
    sshpass -p vagrant ssh vagrant@192.168.56.11

### With ansible-playbook

Use `tasks` in playbook to run task by task.

    ansible-playbook -i inventory playbook-01.yml

Use `vars` in playbook to defines a list of variables.

    ansible-playbook -i inventory playbook-02.yml

Access system information in playbook, use `filter` parameter to provide a pattern, you can get any variable in JSON output and show off on `msg` of `debug`.

    ansible all -i inventory -m setup
    ansible all -i inventory -m setup -a "filter=*ipv4*"
    ansible-playbook -i inventory playbook-03.yml

Use `when` in playbook to run tasks with condition, the variable in the condition was predefined in `vars`.

    ansible-playbook -i inventory playbook-04.yml

Use `register` in playbook to create a new variable and assigns it with the output obtained from a command.

Because Ansible will interrupt a play if the command you're using to evaluate a condition fails. For that reason, you'll need to include an `ignore_errors` directive set to `yes` in said task, and this will make Ansible move on to the next task and continue the play.

    ansible-playbook -i inventory playbook-05.yml

Then, re-run playbook, you'll get a different result because the file is already exists.

    ansible-playbook -i inventory playbook-05.yml

Use `loop` in playbook to avoid repeating the task several times. By default Ansible sets the loop variable `item` for each loop.

    ansible-playbook -i inventory playbook-06.yml

With privilege escalation, such as to run a command with extended permissions (ex: `sudo`), you'll need to include a `become` directive set to `yes` in your play.

    ansible-playbook -i inventory playbook-07.yml

To provide privilege escalation password, you can use the following command with flag `-K` (--ask-become-pass).

    ansible-playbook -i inventory playbook-07.yml -K

You can also change which user you want to switch to while executing a task or play. To do that, set the `become_user` directive to the name of the remote user you want to switch to.

    ansible-playbook -i inventory playbook-08.yml

Now we can verify file ownership information.

    sshpass -p vagrant ssh vagrant@192.168.56.10
    ls -la /tmp/my_file*

Use `apt` in playbook to install and manage system packages. To install a package, you can set package `state` to `present` or `latest` (default is `present`). When you want to remove a package, you must set the package `state` to `absent`.

    ansible-playbook -i inventory playbook-09.yml

When installing multiple packages, you can use a `loop` and provide an array containing the names of the packages you want to install.

    ansible-playbook -i inventory playbook-10.yml

