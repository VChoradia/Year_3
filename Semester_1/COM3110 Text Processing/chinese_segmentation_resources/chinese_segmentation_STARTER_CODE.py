"""
USE: python <PROGNAME> (options)
OPTIONS:
    -h : print this help message and exit
    -d FILE : use dictionary file FILE
    -i FILE : process text from input file FILE
    -o FILE : write results to output file FILE
"""
################################################################

import sys, re, getopt

################################################################

MAXWORDLEN = 5

################################################################
# Command line options handling, and help

opts, args = getopt.getopt(sys.argv[1:], 'hd:i:o:')
opts = dict(opts)

def printHelp():
    progname = sys.argv[0]
    progname = progname.split('/')[-1] # strip out extended path
    help = __doc__.replace('<PROGNAME>', progname, 1)
    print('-' * 60, help, '-' * 60, file=sys.stderr)
    sys.exit()
    
if '-h' in opts:
    printHelp()

if len(args) > 0:
    print("\n** ERROR: no arg files - only options! **", file=sys.stderr)
    printHelp()

if '-d' not in opts:
    print("\n** ERROR: must specify dictionary (opt: -d)! **", file=sys.stderr)
    printHelp()

if '-i' not in opts:
    print("\n** ERROR: must specify input text file (opt: -i)! **", file=sys.stderr)
    printHelp()

if '-o' not in opts:
    print("\n** ERROR: must specify output text file (opt: -o)! **", file=sys.stderr)
    printHelp()

################################################################
with open(args[0], encoding="utf8") as gold_in:
    gold_lines = gold_in.readlines()

with open(args[1], encoding="utf8") as result_in:
    result_lines = result_in.readlines()

if len(result_lines) != len(gold_lines):
    print("\n ** ERROR gold-std and results fines differ in num of lines **",
          file=sys.stderr)
    printHelp()

def get_words_sequenced(line):
    words = set()
    posn = 0
    for word in line.split():
        words.add((posn, word))
        posn += len(word)
    return words

################################################################
# Score all lines

gold_word_count = 0
correct_words = 0
correct_sentences = 0

for i in range(len(gold_lines)):
    gold_words = get_words_sequenced(gold_lines[i])
    result_words = get_words_sequenced(result_lines[i])
    gold_word_count += len(gold_words)
    


