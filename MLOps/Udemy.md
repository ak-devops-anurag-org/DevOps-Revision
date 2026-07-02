### MLOps?
### Traditional ML Lifecycle / Flow (This can be itrative)

1. Business understanding / Requirement gathering [Role - Subject matter experts]

2. Data acquisition (Data collection) - identify data sources, format, data lake - more the data more accurate the result/prediction possible [Role - Data engineer]

3. Clear the data (Data wrangling, Exploratory Data Analysis, Data transformations, Data pre-processing, Data visulization) [Role - Data engineer/Scientists]

4. Modelling (Model selection / Algo, Model building, Model validation/testing - testing only on the 70% data we collected, Model Trainining) Retrain [Data scientists]

FYI - There are tolls  that Engineer can use to get the best model by changing the model Alogo used, parameters to speed up the process and reducing the manual itrations to get the best model possible

5. Model Deployment - Web services / API so end users can use it (Model as a service - REST API endpoint and Embedded deployment - model is packed into a app/software) [Role ML engineers]

6. Monitoring - what and why?
- Model Retraining - 
- NOTE : the data pattern changed and the prediction are not acurate (Model shift) with Exmaple 


### Roles and Responsibilities
- Subject matter experts
- Data scientists - algo selectinm model building and train
- Data engineers - Data acquisition, data lake, data wrangling, clening and transformation, ETL pipelines
- ML engineers - Deployment, Opertionalize the model, Integrating the model to the app/software 


### ML project is of two phase - 
- Data scientists - Data acquisition -> Data processing -> Model building -> Model training -> Model validation
- Operational team - Package -> Complie -> Deploy -> Release -> Monitoring 