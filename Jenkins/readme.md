What is Jenkins
requiremnet of it (JDK)
Where all we can set it up (linux/windows VM, docker, k8s, etc)
In prod we set it up on linux Vm. and why?

path to get the default pass for jenkins
while setting up the jenkins on 
<linux-vm-ip>:8080 we get option to install recommeded plugins
what are plugins?


pipeline?? explain and define (in general)

in Jnekins - 
  - freestyle project?
  - pipeline?

path of the freestyle project o/p (build)?
/var/lib/jenkins/workspace/

Jenkins works on master slave?
what is master slave architecture?

agents?
and how we can set it up in brief
requirements on agenet - no need of jenkins on agent but will need JDK








pipeline view - jenkin plugin

<!-- ------------------------------ -->
credentials binding - in Jenkins Pipeline
gitHub webhooks - 
GitHub repo setting - enable webHooks 
Jenkine libraries (reusable code)






<!-- questions -->
why deploy a VM to deploy the Jenkins server, as this will increase the cost
For running the CICD pipelines we do have free alternatives, such as GitHub actions, Azure DevOps, etc?



<!-- declerative pipeline -->
createing a declerative pipeline to clone the repo, create the image out of it push it on docker hub and deploy it using docker compose(prefered)

deploy using docker run command is not recommeded
