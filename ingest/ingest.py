from google.cloud import storage
from google.oauth2.service_account import Credentials

key_path = "../msds434-final-376804-99e68a7a0e6a.json"
creds = Credentials.from_service_account_file(key_path)
gcloudClient = storage.Client(credentials=creds)

class ingest:

    def __init__(self):
        self.bucket = gcloudClient.get_bucket('bretts434final')

    def uploadBlobCSV(self,blobfilepath,filepath):
        
        blob = self.bucket.blob(blobfilepath)
        blob.upload_from_filename(filepath)