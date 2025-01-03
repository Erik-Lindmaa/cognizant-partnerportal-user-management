import {
    BlobServiceClient,
  } from '@azure/storage-blob';
  
  const containersToBeCreated = [
    "input-container",
    "azure-webjobs-blobtrigger-94qrrl3-44341269",
    "azure-webjobs-hosts"
  ];
  const connectionString = 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;';
  
  // Function to create containers if they do not exist
  async function createContainers() {
    try {
      const client = BlobServiceClient.fromConnectionString(connectionString);
  
      console.log("Listing existing containers:");
      let existingContainers = [];
      
      for await (const container of client.listContainers()) {
        existingContainers.push(container.name);
        console.log(`* ${container.name}`);
      }
  
      for (const containerToBeCreated of containersToBeCreated) {
        if (!existingContainers.includes(containerToBeCreated)) {
          try {
            console.log(`Container '${containerToBeCreated}' does not exist, creating...`);
            const containerClient = client.getContainerClient(containerToBeCreated);
            await containerClient.create();
            console.log("Success!");
          } catch (e) {
            console.log("Container creation failed!");
            console.log(e.message);
          }
        } else {
          console.log(`Container '${containerToBeCreated}' already exists.`);
        }
      }
    } catch (err) {
      console.error("Error listing or creating containers:", err.message);
    }
  }
  
  // Run the function
  createContainers();