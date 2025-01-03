import os
import logging
from azure.storage.blob import BlobServiceClient

# Insert your function.process_blob here.
def process_blob(myblob):
    logging.info(f"Processing blob: {myblob}")

    # Use connection string for local development with Azurite
    connection_string = os.getenv('AZURE_STORAGE_CONNECTION_STRING', 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;')

    try:
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        container_name = 'input-container'
        blob_name = 'sample-blob.txt'
        
        # Get a client to operate with the specified blob and container
        container_client = blob_service_client.get_container_client(container_name)
        blob_client = container_client.get_blob_client(blob_name)

        # Upload some text to the blob
        blob_client.upload_blob("This is a sample text.", overwrite=True)
        logging.info(f"Uploaded to blob: {blob_name}")
        
    except Exception as ex:
        logging.error(f"Encountered an error during blob operations: {ex}")

# Mock invocation data for local testing
class MockBlob:
    def __init__(self, data):
        self.data = data
    
    def __str__(self):
        return self.data.decode('utf-8') if isinstance(self.data, bytes) else str(self.data)

mock_blob = MockBlob(b"Hello, Azure Functions!")
process_blob(mock_blob)