import pandas as pd
import datetime
import google
import os
from google.cloud import storage
from pyWhoop import whoop
# from ingest import ingest
from dotenv import load_dotenv

def retrieve():

    load_dotenv()

    username = os.getenv("USERNAME") or ""
    pw = os.getenv("PASSWORD") or ""
    client = whoop.WhoopClient(username=username, password=pw, authenticate=False)
    client.authenticate()

    today = datetime.date.today()

    sleep = client.get_sleep_collection("2019-01-01",str(today))
    df_sleep = pd.json_normalize(sleep)
    recovery = client.get_recovery_collection("2019-01-01",str(today))
    df_recovery = pd.json_normalize(recovery)
    workouts = client.get_workout_collection("2019-01-01",str(today))
    df_workouts = pd.json_normalize(workouts)
    cycles = client.get_cycle_collection("2019-01-01",str(today))
    df_cycles = pd.json_normalize(cycles)

    df_sleep.to_csv("data/sleep.csv", index=False)
    df_recovery.to_csv("data/recovery.csv", index=False)
    df_cycles.to_csv("data/cycles.csv", index=False)
    df_workouts.to_csv("data/workouts.csv", index=False)

def upload(bucketname, filename, blobname):

    client = storage.Client()
    bucket = client.get_bucket(bucketname)
    blob = storage.Blob(blobname, bucket)
    blob.upload_from_filename(filename)
    gcslocation = 'gs://{}/{}'.format(bucketname, blobname)
    print ('Uploaded {} ...'.format(gcslocation))

    return gcslocation


def ingest(bucketname):
    
    retrieve()
    cycles = upload(bucketname, "data/cycles.csv", "cycles.csv")
    recovery = upload(bucketname, "data/recovery.csv", "recovery.csv")
    sleep = upload(bucketname, "data/sleep.csv", "sleep.csv")
    workouts = upload(bucketname, "data/wourkouts.csv", "workouts.csv")

    return [cycles, recovery, sleep, workouts]

def main():
    try:
        # bucket = os.getenv("WHOOPDATABUCKET")
        bucket = "whoopdata"
        locations = ingest(bucket)
        print("Success!")
    except:
        print("Failed!")


if __name__ == '__main__':
    main()
