"""This script will take arguments in the form of colon seperated
tuples.  The first part of a tuple will be the address that the
code segment will start at.  The second part will be the filename"""

import sys

file_info = []
sys.argv.pop(0)

#parse your arguments into tuples
for elem in sys.argv:
    address, filename = tuple(elem.split(':'))
    file_info.append((int(address),filename))

#it is assumed that you passed in your arguments in order
#please make sure you do that, otherwise bad things might happen
#yes this is terrible code...but time is of the essence

with open('code.hex', 'w') as handle:
    current_address = 0
    for address, filename in file_info:
        #you need to write zeroes until reaching the current address
        while(current_address<address) :
            handle.write('00000000')
            handle.write('\n')
            current_address +=4

        #now that it has been taken care of read in your file
        with open(filename) as in_handle:
            for data_line in in_handle.readlines():
                handle.write(data_line)
                current_address+=4

