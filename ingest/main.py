import pandas as pd
import datetime
import google
import os
import tempfile
from google.cloud import storage
from pyWhoop import whoop
from dotenv import load_dotenv

def retrieve(sleepfile, recoveryfile, cyclesfile, workoutsfile):

    # username = os.getenv("EMAIL")
    # pw = os.getenv("PASSWORD")
    user = "brettmmele@gmail.com"
    pwd = "uX8ZARtpyVe6wZX"
    client = whoop.WhoopClient(username=user, password=pwd, authenticate=False)
    client.authenticate()

    today = datetime.date.today()

    print('retrieving data')
    sleep = client.get_sleep_collection("2019-01-01",str(today))
    df_sleep = pd.json_normalize(sleep)
    recovery = client.get_recovery_collection("2019-01-01",str(today))
    df_recovery = pd.json_normalize(recovery)
    workouts = client.get_workout_collection("2019-01-01",str(today))
    df_workouts = pd.json_normalize(workouts)
    cycles = client.get_cycle_collection("2019-01-01",str(today))
    df_cycles = pd.json_normalize(cycles)

    print('data retrieved, writing to temp files')
    df_sleep.to_csv(sleepfile, index=False)
    df_recovery.to_csv(recoveryfile, index=False)
    df_cycles.to_csv(cyclesfile, index=False)
    df_workouts.to_csv(workoutsfile, index=False)

def upload(bucketname, filename, blobname):

    print('uploading files to blob')
    client = storage.Client(project='msds434-whoop-app')
    bucket = client.get_bucket(bucketname)
    blob = storage.Blob(blobname, bucket)
    blob.upload_from_filename(filename)
    gcslocation = 'gs://{}/{}'.format(bucketname, blobname)
    print ('Uploaded')

    return gcslocation


def ingest(bucketname):

    print('begin ingest')
    sf = tempfile.NamedTemporaryFile(suffix='.csv')
    rf = tempfile.NamedTemporaryFile(suffix='.csv')
    cf = tempfile.NamedTemporaryFile(suffix='.csv')
    wf = tempfile.NamedTemporaryFile(suffix='.csv')
    
    retrieve(sf.name,rf.name,cf.name,wf.name)
    cycles = upload(bucketname, cf.name, "cycles.csv")
    recovery = upload(bucketname, rf.name, "recovery.csv")
    sleep = upload(bucketname, sf.name, "sleep.csv")
    workouts = upload(bucketname, wf.name, "workouts.csv")

    sf.close()
    rf.close()
    cf.close()
    wf.close()

    return [cycles, recovery, sleep, workouts]

def main():
    load_dotenv()
    # bucket = os.getenv("WHOOPDATABUCKET")
    bucket = "whoopdata"
    locations = ingest(bucket)
    print("Success!")
    # print(os.getenv('EMAIL'))
    # print(os.getenv('PASSWORD'))

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"failed: {e}")
