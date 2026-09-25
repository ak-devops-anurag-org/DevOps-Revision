- production folder structure of terrafrom ? 
modules, env (dev, uat, prod - tfwars, tfstate, main, out)

- what happen when we do terraform init ? 
preparing your local working dir so it can execute our code, backend init, mudule and plugin installation, lock file generation 

- .tfstate file ? stores the current state 
- when does .tfstate file comes into picture and what does it stores?  

- you provisioned aks cluster via terrafrom and then added a vm manually - what happens?

- why tf backend and why to use it?
one is tfstate file may store sensitive details

- terrafrom drift ??

- terraform.tfstate.backup - is an automatic copy of your prior state file created by Terraform before it applies changes

- what happen when we run terraform plan for the first time
- how terraform compares the current and desired state as initialy there will not be any tfstate file?
- the Comparison Process
- The Result of the Plan
- What Happens if the Resources Already Exist?
- When is the State File Actually Created?


- what if I only wants to delete some of the resources 
- Method 1: Use Targeted Destroy (Recommended) tf destroy -target=resource_type.resource_name
- Method 2: Delete the Code (Standard GitOps Practice)