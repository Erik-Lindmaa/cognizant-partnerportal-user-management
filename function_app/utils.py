from azure.storage.blob import BlobServiceClient

def save_blob_to_container(data: str, container_name: str, blob_name: str):
    """
    Saves a string as a blob to the specified Azure Storage container.

    Args:
        data (str): The content to save to the blob.
        container_name (str): The name of the Azure Blob Storage container.
        blob_name (str): The name of the blob file to create.
    """
    import os
    import logging

    try:
        # Get the connection string for Azure Blob Storage
        storage_connection_string = os.getenv("AzureWebJobsStorage")
        if not storage_connection_string:
            raise ValueError("AzureWebJobsStorage environment variable is not set.")

        # Initialize the BlobServiceClient
        blob_service_client = BlobServiceClient.from_connection_string(storage_connection_string)

        # Get a BlobClient
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)

        # Upload the data
        blob_client.upload_blob(data, overwrite=True)
        logging.info(f"Blob '{blob_name}' successfully saved to container '{container_name}'.")
    except Exception as e:
        logging.error(f"Error saving blob '{blob_name}' to container '{container_name}': {e}")
        raise
