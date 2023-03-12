# MSDS-434-Final

Web app to display recent Whoop data along with ML model predictions to use for inference about the impact of behaviors on sleep, recovery, strain.



to create docker images and store in the GCP registry run the following command in google cli:

`gcloud builds submit --config=cloudbuild.yaml .`

then set up the container on cloud run (alterneratively can have one main yaml file and use cloudbuild for continuous integration)
