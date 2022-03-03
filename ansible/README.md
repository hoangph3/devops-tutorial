## demo app - developing with ansible

### To start VMs

Step 1: Create hosts server

    vagrant up

Step 2: Checking connection

    sshpass -p vagrant ssh vagrant@192.168.56.10
    sshpass -p vagrant ssh vagrant@192.168.56.11

### With ansible-playbook

Use `tasks` to play in 
[`playbook-01.yml`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/playbook-01.yml).

```yaml
---
- hosts: all
  tasks:
    - name: Print message
      debug:
        msg: Hello Ansible
```

```shell
ansible-playbook -i inventory playbook-01.yml
```

Use `vars` to defines a list of variables in 
[`playbook-02.yml`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/playbook-02.yml).

```yaml
---
- hosts: all
  vars:
    - username: hoang
    - dir: /home/hoang
  tasks:
    - name: Print variables
      debug:
        msg: "Username: {{ username }},
              Home dir: {{ dir }} "
```

```shell
ansible-playbook -i inventory playbook-02.yml
```

To access system information, use `filter` parameter to provide a pattern,
you can get any variable in JSON output and show off on `msg` of `debug` in 
[`playbook-03.yml`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/playbook-03.yml).

```yaml
---
- hosts: all
  tasks:
    - name: print facts
      debug:
        msg: "IPv4 address: {{ ansible_default_ipv4.address }}"

```

```shell
ansible all -i inventory -m setup
ansible all -i inventory -m setup -a "filter=*ipv4*"
ansible-playbook -i inventory playbook-03.yml
```

Use `when` in playbook to run tasks with condition, the variable in the condition was predefined in `vars` in
[`playbook-04.yml`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/playbook-04.yml).

```yaml
---
- hosts: all
  vars:
    - create_user_file: yes
    - user: vagrant  
  tasks:
    - name: create file for user
      file:
        path: /home/{{ user }}/tmp.txt
        state: touch
      when: create_user_file
```

```shell
ansible-playbook -i inventory playbook-04.yml
```

Use `register` in playbook to create a new variable and assigns it with the output obtained from a command.

Because Ansible will interrupt a play if the command you're using to evaluate a condition fails. 
For that reason, you'll need to include an `ignore_errors` directive set to `yes` in said task, and this will make Ansible move on to the next task and continue the play.
We can see clearly with [`playbook-05.yml`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/playbook-05.yml).

```yaml
---
- hosts: all
  vars:
    - user: vagrant
    - filename: tmp
  tasks:
    - name: Check if file already exists
      command: ls /home/{{ user }}/{{ filename }}
      register: file_exists
      ignore_errors: yes

    - name: create file for user
      file:
        path: /home/{{ user }}/{{ filename }}
        state: touch
      when: file_exists is failed

    - name: show message if file exists
      debug:
        msg: The user file already exists.
      when: file_exists is succeeded
```

```shell
ansible-playbook -i inventory playbook-05.yml
```

Then, re-run playbook, you'll get a different result because the file is already exists.

```shell
ansible-playbook -i inventory playbook-05.yml
```

Use `loop` in playbook to avoid repeating the task several times. By default Ansible sets the loop variable `item` for each loop.
Let see in [`playbook-06.yml`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/playbook-06.yml).

```yaml
---
- hosts: all
  tasks:
    - name: creates users files
      file:
        path: /tmp/ansible-{{ item }}
        state: touch
      loop:
        - root
        - hoang
        - hanh
```

```shell
ansible-playbook -i inventory playbook-06.yml
```

With privilege escalation, such as to run a command with extended permissions (ex: `sudo`), you'll need to include a `become` directive set to `yes` in
[`playbook-07.yml`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/playbook-07.yml).

```yaml
---
- hosts: all
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
```

```shell
ansible-playbook -i inventory playbook-07.yml
```

To provide privilege escalation password, you can use the following command with flag `-K` (--ask-become-pass).

```shell
ansible-playbook -i inventory playbook-07.yml -K
```

You can also change which user you want to switch to while executing a task or play. To do that, set the `become_user` directive to the name of the remote user you want to switch to in
[`playbook-08.yml`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/playbook-08.yml).

```yaml
---
- hosts: all
  become: yes
  vars:
    user: "{{ ansible_env.SUDO_USER }}"
  tasks:
    - name: Create root file
      file:
        path: /tmp/my_file_root
        state: touch

    - name: Create {{ user }} file
      become_user: "{{ user }}"
      file:
        path: /tmp/my_file_{{ user }}
        state: touch
```

```shell
ansible-playbook -i inventory playbook-08.yml
```

Now we can verify file ownership information.

```shell
sshpass -p vagrant ssh vagrant@192.168.56.10
ls -la /tmp/my_file*
```

Use `apt` in playbook to install and manage system packages. To install a package, you can set package `state` to `present` or `latest` (default is `present`). When you want to remove a package, you must set the package `state` to `absent`.
Let see in [`playbook-09.yml`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/playbook-09.yml).

```yaml
---
- hosts: all
  become: yes
  tasks:
    - name: Update apt cache and make sure Vim is installed
      apt:
        name: vim
        state: latest
        update_cache: yes
```

```shell
ansible-playbook -i inventory playbook-09.yml
```

When installing multiple packages, you can use a `loop` and provide an array containing the names of the packages you want to install in
[`playbook-10.yml`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/playbook-10.yml).

```yaml
---
- hosts: all
  become: yes
  tasks:
    - name: Update apt cache and make sure Vim, Curl and Unzip are installed
      apt:
        name: "{{ item }}"
        update_cache: yes
      loop:
        - vim
        - curl
        - unzip
```

```shell
ansible-playbook -i inventory playbook-10.yml
```

