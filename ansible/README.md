## demo app - developing with ansible

### To start VMs

Step 1: Create hosts server

```shell
vagrant up
```

Step 2: Checking connection

```shell
sshpass -p vagrant ssh vagrant@192.168.56.10
sshpass -p vagrant ssh vagrant@192.168.56.11
```

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

```shell
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [Print message] ***********************************************************
ok: [192.168.56.10] => {
    "msg": "Hello Ansible"
}
ok: [192.168.56.11] => {
    "msg": "Hello Ansible"
}

PLAY RECAP *********************************************************************
192.168.56.10              : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
192.168.56.11              : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
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
        msg: " Username: {{ username }},
               Home dir: {{ dir }} "
```

```shell
ansible-playbook -i inventory playbook-02.yml
```

```shell
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [Print variables] *********************************************************
ok: [192.168.56.10] => {
    "msg": "Username: hoang, Home dir: /home/hoang "
}
ok: [192.168.56.11] => {
    "msg": "Username: hoang, Home dir: /home/hoang "
}

PLAY RECAP *********************************************************************
192.168.56.10              : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
192.168.56.11              : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
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

```shell
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [print facts] *************************************************************
ok: [192.168.56.10] => {
    "msg": "IPv4 address: 10.0.2.15"
}
ok: [192.168.56.11] => {
    "msg": "IPv4 address: 10.0.2.15"
}

PLAY RECAP *********************************************************************
192.168.56.10              : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
192.168.56.11              : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
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

```shell
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [create file for user] ****************************************************
changed: [192.168.56.11]
changed: [192.168.56.10]

PLAY RECAP *********************************************************************
192.168.56.10              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
192.168.56.11              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Now we can verify the file was created.

```shell
sshpass -p vagrant ssh vagrant@192.168.56.10
cd /home/vagrant/
ls -l
```

```shell
total 0
-rw-rw-r-- 1 vagrant vagrant 0 Mar  3 16:26 tmp.txt
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

```shell
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [Check if file already exists] ********************************************
fatal: [192.168.56.11]: FAILED! => {"changed": true, "cmd": ["ls", "/home/vagrant/tmp"], "delta": "0:00:00.004377", "end": "2022-03-03 15:42:05.367117", "msg": "non-zero return code", "rc": 2, "start": "2022-03-03 15:42:05.362740", "stderr": "ls: cannot access '/home/vagrant/tmp': No such file or directory", "stderr_lines": ["ls: cannot access '/home/vagrant/tmp': No such file or directory"], "stdout": "", "stdout_lines": []}
...ignoring
fatal: [192.168.56.10]: FAILED! => {"changed": true, "cmd": ["ls", "/home/vagrant/tmp"], "delta": "0:00:00.005670", "end": "2022-03-03 15:42:05.495959", "msg": "non-zero return code", "rc": 2, "start": "2022-03-03 15:42:05.490289", "stderr": "ls: cannot access '/home/vagrant/tmp': No such file or directory", "stderr_lines": ["ls: cannot access '/home/vagrant/tmp': No such file or directory"], "stdout": "", "stdout_lines": []}
...ignoring

TASK [create file for user] ****************************************************
changed: [192.168.56.10]
changed: [192.168.56.11]

TASK [show message if file exists] *********************************************
skipping: [192.168.56.11]
skipping: [192.168.56.10]

PLAY RECAP *********************************************************************
192.168.56.10              : ok=3    changed=2    unreachable=0    failed=0    skipped=1    rescued=0    ignored=1   
192.168.56.11              : ok=3    changed=2    unreachable=0    failed=0    skipped=1    rescued=0    ignored=1   
```

Then, re-run playbook, you'll get a different result because the file is already exists.

```shell
ansible-playbook -i inventory playbook-05.yml
```

```shell
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [Check if file already exists] ********************************************
changed: [192.168.56.11]
changed: [192.168.56.10]

TASK [create file for user] ****************************************************
skipping: [192.168.56.10]
skipping: [192.168.56.11]

TASK [show message if file exists] *********************************************
ok: [192.168.56.10] => {
    "msg": "The user file already exists."
}
ok: [192.168.56.11] => {
    "msg": "The user file already exists."
}

PLAY RECAP *********************************************************************
192.168.56.10              : ok=3    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
192.168.56.11              : ok=3    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
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

```shell
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [creates users files] *****************************************************
changed: [192.168.56.11] => (item=root)
changed: [192.168.56.10] => (item=root)
changed: [192.168.56.10] => (item=hoang)
changed: [192.168.56.11] => (item=hoang)
changed: [192.168.56.10] => (item=hanh)
changed: [192.168.56.11] => (item=hanh)

PLAY RECAP *********************************************************************
192.168.56.10              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
192.168.56.11              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
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

```shell
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [Update apt cache] ********************************************************
changed: [192.168.56.10]
changed: [192.168.56.11]

PLAY RECAP *********************************************************************
192.168.56.10              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
192.168.56.11              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

To provide privilege escalation password, you can use the following command with flag `-K` (--ask-become-pass).

```shell
ansible-playbook -i inventory playbook-07.yml -K
```

```shell
BECOME password: 

PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [Update apt cache] ********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

PLAY RECAP *********************************************************************
192.168.56.10              : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
192.168.56.11              : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
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
        path: /tmp/file_of_root
        state: touch

    - name: Create {{ user }} file
      become_user: "{{ user }}"
      file:
        path: /tmp/file_of_{{ user }}
        state: touch
```

```shell
ansible-playbook -i inventory playbook-08.yml
```

```shell
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [Create root file] ********************************************************
changed: [192.168.56.11]
changed: [192.168.56.10]

TASK [Create vagrant file] *****************************************************
changed: [192.168.56.10]
changed: [192.168.56.11]

PLAY RECAP *********************************************************************
192.168.56.10              : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
192.168.56.11              : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Now we can verify file ownership information.

```shell
sshpass -p vagrant ssh vagrant@192.168.56.10
ls -la /tmp/file_of_*
```

```shell
-rw-r--r-- 1 root    root    0 Mar  3 16:03 /tmp/file_of_root
-rw-rw-r-- 1 vagrant vagrant 0 Mar  3 16:03 /tmp/file_of_vagrant
```

Use `apt` in playbook to install and manage system packages. To install a package, you can set package `state` to `present` or `latest` (default is `present`).
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

```shell
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [Update apt cache and make sure Vim is installed] *************************
ok: [192.168.56.11]
ok: [192.168.56.10]

PLAY RECAP *********************************************************************
192.168.56.10              : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
192.168.56.11              : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Now we can verify Vim package have installed.

```shell
sshpass -p vagrant ssh vagrant@192.168.56.11
vim --version | head -n1
```

```shell
VIM - Vi IMproved 8.0 (2016 Sep 12, compiled Jan 20 2022 02:47:53)
```

When you want to remove a package, you must set the package `state` to `absent`.

```yaml
---
- hosts: all
  become: yes
  tasks:
    - name: Removing Vim package
      apt:
        name: vim
        state: absent
```

Now we can verify Vim package have removed.

```shell
sshpass -p vagrant ssh vagrant@192.168.56.11
vim --version
```

```shell
-bash: vim: command not found
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

```shell
PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.56.11]
ok: [192.168.56.10]

TASK [Update apt cache and make sure Vim, Curl and Unzip are installed] ********
changed: [192.168.56.10] => (item=vim)
ok: [192.168.56.10] => (item=curl)
ok: [192.168.56.10] => (item=unzip)
changed: [192.168.56.11] => (item=vim)
ok: [192.168.56.11] => (item=curl)
ok: [192.168.56.11] => (item=unzip)

PLAY RECAP *********************************************************************
192.168.56.10              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
192.168.56.11              : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Templates allow you to create new files on the nodes using predefined models based on the [Jinja2 templating](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html) system. Ansible templates are typically saved as `.tpl` files and support the use of variables, loops, and conditional expressions.

Now we will create new template file called [`landing-page.html.j2`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/files/landing-page.html.j2)

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title> {{ page_title }} </title>
  <meta name="description" content="Created with Ansible">
</head>
<body>
    <h1> {{ page_title }} </h1>
    <p> {{ page_description }} </p>
</body>
</html>
```

This template uses two variables that must be provided whenever the template is applied in a playbook: `page_title` and `page_description`. We can see in [`playbook-11.yml`](https://github.com/hoangph3/devops-tutorial/blob/main/ansible/playbook-11.yml)

```yaml
---
- hosts: all
  become: yes
  vars:
    page_title: Meme Wibu
    page_description: Wibu is the best.
  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: latest

    - name: Apply Page Template
      template:
        src: files/landing-page.html.j2
        dest: /var/www/html/index.nginx-debian.html

    - name: Allow all access to tcp port 80
      ufw:
        rule: allow
        port: '80'
        proto: tcp
```

```shell
ansible-playbook -i inventory playbook-11.yml
```

On localhost, you can access landing page with server public ip (`192.168.56.10` or `192.168.56.11`)

```shell
curl 192.168.56.11
```

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Meme Wibu</title>
  <meta name="description" content="Created with Ansible">
</head>
<body>
    <h1>Meme Wibu</h1>
    <p>Wibu is the best.</p>
</body>
</html>
```