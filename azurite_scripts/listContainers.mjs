import {
  BlobServiceClient,
} from '@azure/storage-blob';

const connectionString = 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;';

// Function to list containers
async function listContainers() {
  try {
    const client = BlobServiceClient.fromConnectionString(connectionString);

    console.log("Existing containers:");
    for await (const container of client.listContainers()) {
      console.log(`* ${container.name}`);
    }
  } catch (err) {
    console.error("Error listing containers:", err.message);
  }
}

// Run the function
listContainers();