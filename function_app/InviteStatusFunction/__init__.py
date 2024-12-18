import logging
from .process_file import process_blob

def main(myblob: str) -> None:
    logging.info(f"Processing blob: {myblob}")
    process_blob(myblob)
