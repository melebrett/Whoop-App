from google.cloud import storage
from google.oauth2.service_account import Credentials

class upload:

    def __init__(self):

        self.key_path = "../../msds434-whoop-app-44384939c1f4.json"
        self.creds = Credentials.from_service_account_file(self.key_path)
        self.gcloudClient = storage.Client(credentials=self.creds)
        self.bucket = self.gcloudClient.get_bucket('whoopdata')

    def uploadBlobCSV(self,blobfilepath,filepath):
        
        blob = self.bucket.blob(blobfilepath)
        blob.upload_from_filename(filepath)