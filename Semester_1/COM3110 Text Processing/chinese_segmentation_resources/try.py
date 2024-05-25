# -*- coding: utf-8 -*-
"""
Created on Fri Oct 13 10:40:46 2023

@author: vivek
"""

import binascii
with open("chinesetext.utf8", 'rb') as f:
    filecontent = f.read()
chunk1 = filecontent[:11]
print(chunk1.decode('utf8'))

