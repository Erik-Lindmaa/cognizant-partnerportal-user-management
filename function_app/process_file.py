import logging
import requests
import csv
import io
from .utils import save_blob_to_container

def process_blob(myblob: str):
    # Fetch credentials and set up MS Graph client
    token = get_auth_token()

    # Read input file
    input_data = io.StringIO(myblob)
    csv_reader = csv.DictReader(input_data)

    # Prepare output data
    output_csv = io.StringIO()
    output_log = io.StringIO()
    csv_writer = csv.writer(output_csv)
    csv_writer.writerow(["Mail", "State", "UPN"])

    for row in csv_reader:
        user_email = row["mail"]
        response = requests.get(
            f"https://graph.microsoft.com/v1.0/users?$filter=mail eq '{user_email}'&$select=userPrincipalName,externalUserState,mail",
            headers={"Authorization": f"Bearer {token}"},
        )

        if response.status_code == 200:
            data = response.json()
            if data["value"]:
                user = data["value"][0]
                csv_writer.writerow(
                    [user["mail"], user["externalUserState"], user["userPrincipalName"]]
                )
            else:
                output_log.write(f"{user_email} not found\n")
        else:
            logging.error(f"Error processing {user_email}: {response.text}")

    # Save output
    save_blob_to_container(output_csv.getvalue(), "output-container", "output.csv")
    save_blob_to_container(output_log.getvalue(), "log-container", "output_log.txt")

def get_auth_token():
    # Your logic for fetching an auth token
    return "<access_token>"
