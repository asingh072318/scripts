#!/usr/bin/python3
import PyPDF2
import sys
import os
pdf_in = open(os.getcwd()+'/'+sys.argv[1], 'rb')
pdf_reader = PyPDF2.PdfFileReader(pdf_in)
pdf_writer = PyPDF2.PdfFileWriter()

for pagenum in range(pdf_reader.numPages):
  page = pdf_reader.getPage(pagenum)
  page.rotateClockwise(90)
  pdf_writer.addPage(page)

pdf_out = open('rotated_'+sys.argv[1], 'bw+')
pdf_writer.write(pdf_out)
pdf_out.close()
pdf_in.close()
