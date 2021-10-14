# adf-integration-samples

This document covers ADF samples to create a pipeline to copy data from Anthology Student database to Any database on customer domain.

## Pre-requisite
- Contact Anthology Cloud team to create Self hosted integration runtime.
- Please get the Anthology student database details and credentials.


## Step 1
- Create Azure SQL database on your subscription
- Open src>>database folder from github
- Open "Datawarehouse_Script.sql" on SSMS 
- Connect to the newly created database
- Execute the script

## Step 2
- Identify the tables, Columns and datatypes from Anthology Student database which needs to be copied using the ADF pipeline
- update the details of the tables in "Populate_SisDictionary.sql" and "Create_Tables_On_Datawarehouse.sql"
- The script has example of table how it needs to created. Please update them as per your requirement.
- After necessary changes, please execute the scripts "Populate_SisDictionary.sql" and "Create_Tables_On_Datawarehouse.sql" against the database created on step 1

## Step 3
- After completing the step 2, open script "Generate_Views_ForAnthologyStudent.sql"
- Execute the Script
- Please save the output into a file.
- Send the file to Anthology cloud team to create the views in Anthology student database. 

## Step 4
- Create Azure Data Factory in your subscription if it doesn't exist
- download the file "arm_template.zip" from src folder.
- Extract "arm_template.zip" into "arm_template" folder
- Open Azure Data Factory Studio from Azure portal.
- Navigate to "Manage" >> "Arm Template"
- click "Import ARM Template" which will open "custom deployment" in a new tab.
- click "Build your own template in the editor"
- click "Load File" button and select the folder "arm_template" created above
- select "armtemplate.json" and click open button.
- click save
- Populate subscription, resource group, region and Factory name with the details of the Azure data factory created.
- Update "Anthology Student_Connection string" and "Datawarehouse Db_connection String" with the details in below format  "integrated security=False;encrypt=True;connection timeout=30;data source=<database server name>;initial catalog=<database name>;user id=<user name>". Please update the database server name, database name and user name before updating.
- click "Review + Create" and then "Create" button.
- This will install pipeline "AnthologyStudent_Datawarehouse_Initial", datasets "AnthologyStudent" and "DataWarehouseDb" and linked servers "AnthologyStudent" and "DatawarehouseDb"
- Navigate to manage >> linked servers and validate "AnthologyStudent" connection and update the "connect via integration runtime" with the self hosted integration runtime details and update the password or azure key valult details for the credentials and confirm the connectivity using the "test connection" button.
- Validate "DatawarehouseDb" connection details and confirm the connectivity using the "test connection" button.
 
## Step 5
- Navigate to "Author" section and open "AnthologyStudent_Datawarehouse_Initial" pipeline and click "Add Trigger" button to trigger now or create a trigger for the future.
