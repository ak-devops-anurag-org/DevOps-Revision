==================================
Azure ML Studio 
==================================


### AzureML - Dedicated ML Platform on Azure

Creation, deployment and scale of ML model
Versioning,

Features
- open a build it support for open sourec toll and framework for model traning - framework PyTorch, TensorFlow
- Development tools - Jupter notebook, pycharm
- Automated ML - Build the model, Hyberparameter tuning, etc
- Entitiy managment - Versioning, Profiling
- Security - data privacy, etc
- Model serviing - Batch and real time model serving
- Model training - 
- infrastructure - CPUs, GPUs, TPUs, etc



============

### AzureML orverview

- Automated ML
- Designer

- Datasets - data used to train the model - with versioning for Tracibility
- Experiment - run a pipeline to create a new model and name that expirement 
- Pipeline - all matrix are stored
- Model - endpoints and Dataset

Computer - 
- Compute instances for Developments
- Computer Cluster - for Training
- Inference Cluster - for deployments

Data stores - for connection with different Azure services


==================================
Demo - Data Scientist's Experiment
==================================

### AzureML implementation with Azure devOps

Data scientists - Data cleaning and EDA (Exploratory Data Analysis - critical approach in data science where you summarize, visualize, and investigate raw data.)

MLOPs enginner - Automating the build and deploying the model

Azure devops - Code (containing code, ymal files, etc for MLOps)

in Azure DevOps -> 
- Market place -> Machine learning add
- Service connection (to connect a AzureML workspace to Azure DevOps)
- Azure devops -> Library -> env variables 

Experiments -
- Data scientist -> 
- train the model on 70-80% data -> 
- score of the trained model by testing on the 20-30% remaining data 


ML engineers -> Take the refrence from the Experiment code (train and score code) -> robust and scallable code with Automation


==================================
Demo - Orcehstrated ML codes in Azure
==================================

Orchestrated experiment - 
- data prep
- model train
- model evaluation then validation


NOTE : so the ML engineer writes the python scripts (train.py, evaluate.py, register.y and score.py) so that he/she can use and run this scripts withing the pipeline to automate the traning, evaluation and registring the model 


Training .py code 
- train_aml.py (for training code) 
  - we call this from some work flow script
  - dataset version
  - all areguments
  - some parameters
  - bease on the arguments get the data set
  - split the data
  - train the data using a train_model function
  - 

Evaluate .py code 
- if the model generated is the first one?
- if model exists - it should be better then the previous version 

- get the model name to compare it to previous model
- when its a frist model we will have to register it with possible tags

mse? matrix? in MLOps

Registring Model .py code
- get the workspace details 
- parameters
- model tags
- get/load the model file


Scoring model .py code
- test the model from the dummy data or 20% remanining Data, printing the prediction