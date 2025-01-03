import {
    BlobServiceClient,
  } from '@azure/storage-blob';
  
  const connectionString = 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;';
  const containerName = 'input-container';
  const blobName = 'sample-blob.txt';
  const content = 'Hello, Azure Functions!';
  
  async function uploadBlob() {
    const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
    const containerClient = blobServiceClient.getContainerClient(containerName);
    const blockBlobClient = containerClient.getBlockBlobClient(blobName);
  
    try {
      console.log(`Uploading to Azure storage as blob:\n\tname: ${blobName}\n\tcontainer name: ${containerName}`);
      const uploadBlobResponse = await blockBlobClient.upload(content, content.length);
      console.log(`Upload block blob ${blobName} successfully`, uploadBlobResponse.requestId);
    } catch (err) {
      console.error('Error uploading blob:', err.message);
    }
  }
  
  uploadBlob();