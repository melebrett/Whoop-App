# MSDS-434-Final

to create docker images and store in the GCP registry run the following command in google cli:

`gcloud builds submit --config=cloudbuild.yaml .`

then set up the container on cloud run