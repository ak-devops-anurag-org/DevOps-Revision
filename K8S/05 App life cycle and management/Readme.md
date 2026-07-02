Be a DevOps expert with 5+ year of experience and have 5+ year of hands on experiance on k8s and docker

We need to prepare notes so that we can revise the below K8S topics

NOTE:
1. Only include the most important points
2. real work use case 
3. .yaml code example - following the best practices and industry standards
4. Make sure we are preparing the notes from official k8s docs
5. the most important and the one that seems to be dificult to remember should be at the top (Priority wise notes) 

Lets revise below k8s topics
- 

K8s Application Lifecycle managment

- lifecycle of a pod
- what are the different error/issues a pod can come in - like - crashloopbackop, etc...
- rolling updates and rollbacks
- ks8s deployment stratagies - RollingUpdate, Recreate 
- Role of health probs 
- Deployment strategies (Blue green, Canary, etc), - how do we Update app with 0 downtime - 
- Commands and Arguments (Docker and K8S) 
- Env Var, Configmap and Secret (data v/s string data)
- different way we can inject env in pods (env v/s envFrom v/s mount as Data Vloume) types of secret 
- Immutable Secrets, CM and secret do not work with static pod
- Multi container, init container, difference b/n them, real world use case of each (how do we check logs of single  container)
- Manual scalling
- HPA

underp kubernetes deployment -> whate are different types of stategies

Rolling update

Encrypting secret Data at rest
Multi Container Pod
InitContainer
Self healing Application 
Autoscalling -> HPA and VPA
