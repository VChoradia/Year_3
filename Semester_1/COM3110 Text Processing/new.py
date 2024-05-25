# -*- coding: utf-8 -*-
"""
Created on Fri Oct  6 10:08:44 2023

@author: vivek
"""

# Docstring usage example
"""
USE: python <PROGNAME> (options)
OPTIONS:
-h : print this help message and exit
-d FILE : use dictionary file FILE
-i FILE : process text from input file FILE
-o FILE : write results to output file FILE
"""

import sys 

def tokenize(doc):
 '''Tokenizes the specified document'''
 return doc.split()
 
print(__doc__)
print(tokenize.__doc__)


# Task 6 code example
def printHelp():
 progname = sys.argv[0]
 progname = progname.split('\\')[-1] # strip out extended path if running the program from Spyder
 help = __doc__.replace('<PROGNAME>', progname, 1) # replace the placeholder <PROGNAME> with the script filen
 print('-' * 60, help, '-' * 60, file=sys.stderr)
 sys.exit()