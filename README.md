# MSDS-434-Final

Web app to display recent Whoop data along with ML model predictions to use for inference about the impact of behaviors on sleep, recovery, strain.

More info on whoop: https://www.whoop.com/

App: https://whoop-app-oc5t7fetca-uc.a.run.app/

## 1. Ingest

Retrieve data from [Whoop API](https://developer.whoop.com/api/) and store in blob storage.

## 2. Upload

Move blobs in cloud storage to BigQuery tables

## 3. Process

Transform and merge raw data, write to new BQ table.

## 4. Models

Build models to predict recovery, workout strain, hrv etc. Upload models to cloud storage buckets, register to vertexAI and set up model API endpoints.

## 5. App

R shiny front end dashboard to display recovery and workout history, along with model predictions. 


Each step is a containerized service, with docker images pushed to Google artifact registry and containers built/run via cloud build/run. 

> to create docker images and store in the GCP registry run the following command in google cli:
> `gcloud builds submit --config=cloudbuild.yaml .`
> then set up the container on cloud run (alterneratively can have one main yaml file and use cloudbuild for continuous integration)

Continuous integration is not a part of this project, but could be set up via cloud build with a dockercompose or yaml file that builds all the necessary images at once.
