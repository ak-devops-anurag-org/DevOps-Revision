# === Ansible ===

Ansible is an agentless automation/configuration-management tool used to configure servers, deploy applications, install packages, manage users, and perform operational tasks.

ansible-project/
│
├── ansible.cfg
├── inventory
├── playbook.yml
└── roles/

ansible-project/
│
├── ansible.cfg
├── inventories/
│   ├── dev/
│   │   └── hosts.yml
│   ├── staging/
│   │   └── hosts.yml
│   └── prod/
│       └── hosts.yml
│
├── playbooks/
│   ├── site.yml
│   └── deploy.yml
│
├── roles/
│   ├── nginx/
│   ├── docker/
│   └── application/
│
└── group_vars/
    ├── all.yml
    └── prod.yml

ansible-playbook \
  -i inventories/prod/hosts.yml \
  playbooks/deploy.yml



ansible.cfg
     ↓
How Ansible behaves

inventory
     ↓
Which servers Ansible manages

playbook
     ↓
What Ansible should do

role
     ↓
Reusable production automation

variables
     ↓
Environment-specific values


- works on push based approch
- One control node/server - and we do not need to set up ansible agent on worker nodes 
- But, ansible to work from control node it required - python to be installed on each and every control and worker node
- angentless (prons)

- instead of writing scripts we write the ansible playbook

# === exmple use case ===
- stoping the DB servers first then stoping the app servers
- power up the App server then the DB servers

- we can use ansible to provison VM (on public - awas and private cloud - VMware) and configure app on those and setting the comm b/n them, configure firewall, etc
- 

### === Need? ===
• Reduce the Time to Market by faster configurations
• We need to have a scalable approach to manage multiple servers

# === Alternative of Ansible ===
- Chef and puppet 

But - 
- follows - pull and push approvch - first checks if docker is installed, if not the push - install it
- need to set up agent on the servers/EC2 instance where we need to configure the dependencies



setting up a control plane and 2 worker node

- sudo apt-get update
- sudo apt-get install ansible

- ssh-key gen
- add the public key of the control node in the worker nodes - path - .ssh/authorized_keys

- hosts.ini (inventory file -> contains all the servers details)

[servers]
worker-node-1 ansible_host=<ip-address on werker>
worker-node-2 ansible_host=<ip-address on werker>

[all:vars]            // common variables for all the above worker nodes
ansible_ssh_private_key_file=/home/ubuntu/ansible-master-key
ansible_python_interpreter=/user/bin/ptyhong3

## === Ansible config file - section 2 ===

### === config ===
path - /etc/ansible/ansible.cfg
[defaults]
[inventory]
[privilege_escalation]
[paramiko_connection]
[ssh_connection]
[persistent_connection]
[colors]

$ANSIBLE_CONFIG=/opt/ansib1e-web.cfg ansible-playbook playbook.yml
$ANSIBLE_GATHERING=EXPLICIT ansible-playbook playbook.yml

cmd >> ansible-config list   # list all config files
cmd >> ansible-config view   # shows the current config file
cmd >> ansible-config dump   # Shows the current setting ansible has picked up & from where did it picked  

EG - 
$ export ANSIBLE GATHERING=exp1icit
$ ansible-config dump I grep GATHERING
DEFAULT_GATHERING (ENV:ANSIBLE_GATHERING) = explicit

### === priority of the config - files ===
1. ANSIBLE_CONFIG environment variable
             ↓
2. ./ansible.cfg
   (current directory)
             ↓
3. ~/.ansible.cfg
   (user home)
             ↓
4. /etc/ansible/ansible.cfg
   (system-wide)



### === yaml ===
=== Key Value Pair ===
Fruit: Apple
Vegetable: Carrot
Liquid: Water
Meat: Chicken

==== Array/ Lists ===
Fruits :
-   Orange
-   Apple
-   Banana
Vegetables :
-   Carrot
-   Cauliflower
-   Tomato

=== Dictionary/Map ===
Banana :
    calories: 105
    Fat: 0.4 g
    Carbs: 27 g
Grapes:
    Calories: 62
    Fat: 0.3 g
    Carbs: 16 g

==== Key Value/Dictionary/Lists ===
Fruits:
- Banana:
    calories: 105
    Fat: 0.4 g
    carbs: 27 g
- Grape:
    Calories: 62
    Fat: 0.3 g
    Carbs: 16 g


## === inventory - Section - 3 ===
- ansible is agent less
- info abou the target servers/system are stored in inventory file
- /etc/ansible/hosts

- sample inventory files

server1.company.com
server2.company.com

[mail]  // group
server3.company.com
server4.company.com

[db]  // other group
server3.company.com
server4.company.com


- setting alias
web ansible_host=server1.company.com ansible_connection=ssh (ssh)
web ansible_host=server1.company.com ansible_connection=winrm (windoes host)

localhost ansible_connection=localhost


### === Inventory Parameters: ===
• ansibl_connection — ssh/winrm/localhost
• ansible_port — 22/5986
• ansible_user — root/administrator (user used to make remote connection)
• ansible_host — 198.x.x.10
• ansible_ssh_pass — pass

best practice - go with ssh key based 


### === inventory format ===
- INI
- Yaml


### === Grouping and Parent-chile Relationship ===
- why we need grouping
- eg - we need to update multiple web servers (we gorup them using a lable - so update happens across all of them at once)

- what if the servers are located across locations
- web servers - parent 
- web_server_US - child 



## === Variables - Section - 4 ===

- eg - var in ineventory
- ansible_host, ansible_connection

- in playboook - `{{ http_host}}`    // jinja2 template
- vars : 
    dns_server: 10.3.3.43

- sample var file - web.yml

http_host : 442
inter_ip_range : 192.3.2.4


### === var types ===
- string
- no (float or int)
- boolean
- list (ordered collection - values can be of any types)   packages[0], "{{packages}}"
- dictionary vars (contains key value pair)

### === Registering var and var percedence ===

app_port: 8080
port: "{{ app_port }}"

Playbook
---
- name: Deploy application
  hosts: app_servers

  vars:
    app_name: myapp
    app_port: 8080

  tasks: 
    - name: Show application details
      ansible.builtin.debug:
        msg: "Deploying {{ app_name }} on port {{ app_port }}"


### === Registering Variables 
- register stores the result of a task into a variable.

- name: Check disk usage
  ansible.builtin.shell: df -h /
  register: disk_output

- name: Check all the dir and files in current path
  ansible.builtin.shell: ls -l /
  register: dir_files

inspect values
- name: Display disk information
  ansible.builtin.debug:
    var: disk_output


### === Precedence ===
LOW precedence
      ↓
Role defaults
      ↓
Inventory variables
      ↓
group_vars 
      ↓
host_vars
      ↓
Play vars
      ↓
Task vars
      ↓
Extra vars (-e)
      ↓
HIGH precedence

### === Variable Scoping ===
Where is this variable available?

- hosts: web
  vars:                          // play
    app_name: myapp
  tasks:                         // task

    - name: Task 1
      debug:
        var: app_name

    - name: Task 2
      debug:
        var: app_name

app_name is available to both tasks because it is defined at play scope.

### === Magic Variables -> predefined variables === 
- predefined variables, hostvats, groups, inventory_hostname, etc 
- eg- ansible_host, ansible_connection, etc....
- important Ansible concept.
- Magic variables are variables automatically created by Ansible.


hostvars ->
This is extremely useful.
It lets you access variables of another host.

For example:
{{ hostvars['db01']['ansible_host'] }}

Meaning:
Give me the ansible_host variable of db01.

Production use case:

Application server
       |
       | needs DB IP
       ↓
Database server

You can reference the DB host's information without hardcoding its IP.






## === Doubts ===
- Private cloud and VM ware ?? 
- 

