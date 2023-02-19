import pandas as pd
import datetime
import os
from pyWhoop import whoop
from ingest import ingest
from dotenv import load_dotenv

def main():

    load_dotenv()

    username = os.getenv("USERNAME") or ""
    pw = os.getenv("PASSWORD") or ""
    client = whoop.WhoopClient(username=username, password=pw, authenticate=False)
    client.authenticate()
    # client.is_authenticated()
    # client.get_profile()

    today = datetime.date.today()


    try:
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
    except:
        print('failed to retrieve data')

    ing = ingest()
    ing.uploadBlobCSV("cycles.csv","data/cycles.csv")
    ing.uploadBlobCSV("recovery.csv","data/recovery.csv")
    ing.uploadBlobCSV("sleep.csv","data/sleep.csv")
    ing.uploadBlobCSV("workouts.csv","data/workouts.csv")

if __name__ == '__main__':
    main()