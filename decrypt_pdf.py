#!/usr/bin/python3
from PyPDF2 import PdfFileWriter, PdfFileReader
import sys
import os
  
# Create a PdfFileWriter object
out = PdfFileWriter()
  
# Open encrypted PDF file with the PdfFileReader
file = PdfFileReader(sys.argv[1])
  
# Store correct password in a variable password.
password = sys.argv[2]
  
# Check if the opened file is actually Encrypted
if file.isEncrypted:
  try:
    # If encrypted, decrypt it with the password
    file.decrypt(password)
  
    # Now, the file has been unlocked.
    # Iterate through every page of the file
    # and add it to our new file.
    for idx in range(file.numPages):
        
        # Get the page at index idx
        page = file.getPage(idx)
          
        # Add it to the output file
        out.addPage(page)
      
    # Open a new file
    with open("decrypted_"+sys.argv[0], "wb") as f:
        
        # Write our decrypted PDF to this file
        out.write(f)
  
    # Print success message when Done
    print("File decrypted Successfully.")
  except NotImplementedError:
    command=f"qpdf --password='{sys.argv[2]}' --decrypt {os.getcwd()+'/'+sys.argv[1]} {os.getcwd()+'/'+'decrypt_'+sys.argv[1]};"
    os.system(command)
else:
    
    # If file is not encrypted, print the 
    # message
    print("File already decrypted.")
