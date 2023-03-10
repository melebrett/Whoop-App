from google.cloud import storage
from google.cloud import bigquery
# credentials = service_account.Credentials.from_service_account_file("../../msds434-whoop-app-44384939c1f4.json")

def main():

    project_id = 'msds434-whoop-app'
    bq = bigquery.Client(project=project_id)

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        autodetect=True
    )

    files = ['cycles.csv','recovery.csv','workouts.csv','sleep.csv']
    for i in files:
        try:
            file = i
            uri = f"gs://whoopdata/{file}"
            table = file.split(".")[0]
            tableid = f"msds434-whoop-app.whoopdataset.{table}"
            load_job = bq.load_table_from_uri(uri, tableid, job_config=job_config)
            load_job.result()
            print(f"successfully loaded {file}")
        except Exception as e:
            print(f"error writing file {file}: {e}")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"job failed with error: {e}")