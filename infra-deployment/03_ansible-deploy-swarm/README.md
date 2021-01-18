# ITID202

Setup Docker Swarm with Ansible.

In this setup we have a node manager, on which we will use Ansible to configure/manage a swarm cluster, hosting a MongoDB replica set.

---

## Pre-Check

Hosts file: 

```
10.211.0.11 deb-docker1
10.211.0.12 deb-docker1
10.211.0.13 deb-docker3
```

---

Prepare your system for Ansible, with a user named devops (the only script that requires root):

```
$ chmod 700 00_prepare_sys_for_ansible.sh
$ sudo ./00_prepare_sys_for_ansible.sh
```

---

Switch to your devops user, install Ansible in a venv, and create a ssh key to manage your nodes.

You can easily change the installation (venv) directory by modifying the script. Example for version 2.9:

```
chmod 750 install_ansible.sh
$ ./install_ansible.sh 2.9
```

---

## Prepare your managed nodes for Ansible

Prepare all nodes to be managed with Ansible with the playbook `setup-ansible-nodes.yml`.

This playbook will, on all nodes:

- set the machine hostname according to our inventory file
- create a user "devops"
- make this user passwordless sudoers
- add our ssh key (~/.ssh/id_rsa) to its authorized_keys
- do a full upgrade (dist-upgrade)
- reboot

The user will not have a password set. The only way to connect as him is to ssh in with our ssh key.

The name of the created user is in groups_vars/all

We execute this with the user "sysadmin" as it is a sudoer provided by default on our nodes.

```
$ ansible-playbook -i inventory.yml -u sysadmin --ask-pass --become --ask-become-pass setup-ansible-nodes.yml
```

---

Ensure passwordless ssh is working:

```
$ ansible -i inventory.yml -u devops --become -m ping all
deb-docker1 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
deb-docker2 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
deb-docker3 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
```

---

## Deploy Docker Swarm

```
$ ansible-playbook -i inventory.ini -u devops deploy-swarm.yml 
PLAY RECAP

client                 : ok=11   changed=3    unreachable=0    failed=0   
deb-docker1            : ok=18   changed=4    unreachable=0    failed=0   
deb-docker2            : ok=15   changed=1    unreachable=0    failed=0   
deb-docker3            : ok=15   changed=1    unreachable=0    failed=0   
```

SSH to the Swarm Manager and List the Nodes:

```
$ sudo docker node ls
ID                            HOSTNAME         STATUS         AVAILABILITY        MANAGER STATUS      ENGINE VERSION
0ead0jshzkpyrw7livudrzq9o *   deb-docker1      Ready          Active              Leader              18.03.1-ce
iwyp6t3wcjdww0r797kwwkvvy     deb-docker2      Ready          Active                                  18.03.1-ce
ytcc86ixi0kuuw5mq5xxqamt1     deb-docker3      Ready          Active                                  18.03.1-ce
```

Create a Nginx Demo Service:

```
$ docker network create --driver overlay appnet
$ docker service create --name nginx --publish 80:80 --network appnet --replicas 6 nginx
$ docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
k3vwvhmiqbfk        nginx               replicated          6/6                 nginx:latest        *:80->80/tcp

$ docker service ps nginx
ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE            ERROR               PORTS
tspsypgis3qe        nginx.1             nginx:latest        deb-docker1         Running             Running 34 seconds ago                       
g2f0ytwb2jjg        nginx.2             nginx:latest        deb-docker2         Running             Running 34 seconds ago                       
clcmew8bcvom        nginx.3             nginx:latest        deb-docker1         Running             Running 34 seconds ago                       
q293r8zwu692        nginx.4             nginx:latest        deb-docker3         Running             Running 34 seconds ago                       
sv7bqa5e08zw        nginx.5             nginx:latest        deb-docker2         Running             Running 34 seconds ago                       
r7qg9nk0a9o2        nginx.6             nginx:latest        deb-docker3         Running             Running 34 seconds ago   
```

Test the Application:

```
$ curl -i http://10.211.0.11
HTTP/1.1 200 OK
Server: nginx/1.15.0
Date: Thu, 14 Jun 2018 10:01:34 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 05 Jun 2018 12:00:18 GMT
Connection: keep-alive
ETag: "5b167b52-264"
Accept-Ranges: bytes
```

## Delete the Swarm:

```
$ ansible-playbook -i inventory.ini -u devops delete-swarm.yml 

PLAY RECAP 
deb-docker1             : ok=2    changed=1    unreachable=0    failed=0   
deb-docker2             : ok=2    changed=1    unreachable=0    failed=0   
deb-docker3             : ok=2    changed=1    unreachable=0    failed=0   
```

Ensure the Nodes is removed from the Swarm, SSH to your Swarm Manager:

```
$ docker node ls
Error response from daemon: This node is not a swarm manager. Use "docker swarm init" or "docker swarm join" to connect this node to swarm and try again.
```
