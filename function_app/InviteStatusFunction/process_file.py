import logging
import requests
import csv
import io
from msal import ConfidentialClientApplication
from .utils import save_blob_to_container

import os

tenant_id = os.getenv("TENANT_ID")  
client_id = os.getenv("CLIENT_ID")
client_secret = os.getenv("CLIENT_SECRET")

# MSAL client setup
authority = f"https://login.microsoftonline.com/{tenant_id}"
scopes = ["https://graph.microsoft.com/.default"]

def get_auth_token():
    """
    Authenticate with Azure AD and acquire an access token.
    """
    try:
        app = ConfidentialClientApplication(
            client_id,
            authority=authority,
            client_credential=client_secret,  # Replace with certificate?
        )

        token_response = app.acquire_token_for_client(scopes=scopes)
        if "access_token" in token_response:
            logging.info("Token acquired successfully.")
            return token_response["access_token"]
        else:
            logging.error(f"Failed to acquire token: {token_response.get('error_description')}")
            raise Exception("Token acquisition failed.")
    except Exception as e:
        logging.error(f"Authentication error: {e}")
        raise

def process_blob(myblob: str):
    """
    Process the uploaded blob, query Microsoft Graph, and save results to storage.
    """
    try:
        # Fetch MS Graph token
        token = get_auth_token()

        # Read input CSV file
        input_data = io.StringIO(myblob)
        csv_reader = csv.DictReader(input_data)

        # Prepare output data
        output_csv = io.StringIO()
        output_log = io.StringIO()
        csv_writer = csv.writer(output_csv)
        csv_writer.writerow(["Mail", "State", "UPN"])  # CSV headers

        for row in csv_reader:
            user_email = row.get("mail")
            if not user_email:
                logging.warning("Row without 'mail' field encountered, skipping.")
                continue

            # Query Microsoft Graph API for the user
            response = requests.get(
                f"https://graph.microsoft.com/v1.0/users?$filter=mail eq '{user_email}'&$select=userPrincipalName,externalUserState,mail",
                headers={"Authorization": f"Bearer {token}"},
            )

            if response.status_code == 200:
                data = response.json()
                if data.get("value"):
                    user = data["value"][0]
                    csv_writer.writerow(
                        [user.get("mail"), user.get("externalUserState"), user.get("userPrincipalName")]
                    )
                else:
                    output_log.write(f"{user_email} not found\n")
            else:
                logging.error(f"Error querying {user_email}: {response.text}")
                output_log.write(f"Error querying {user_email}: {response.text}\n")

        # Save outputs to Azure Blob Storage
        save_blob_to_container(output_csv.getvalue(), "output-container", "output.csv")
        save_blob_to_container(output_log.getvalue(), "log-container", "output_log.txt")
        logging.info("Processing completed successfully.")
    except Exception as e:
        logging.error(f"Error processing blob: {e}")
        raise
