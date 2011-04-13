from random import getrandbits
import sys

def to_string(num) :
    ret = "%08x" % num
    return ret[-8:]

def asm_iter(data):
    R5, R6 = data
    res = []
    if(R5 < R6):
        res.append(to_string(R5+R6))
    else :
        res.append(to_string(R5 & R6))
    res.append(to_string((R5 | R6) ^ 0xFFFFFFFF))
    res.append(to_string(R5 << 2))
    res.append(to_string(R6 << 4))
    return res

if __name__ == "__main__":
    runs, data_file, test_file = int(sys.argv[1]), sys.argv[2], sys.argv[3]
    data = []
    test = []
    for i in range(runs):
        iter_data = getrandbits(32), getrandbits(32)
        data.append(map(to_string, iter_data))
        [test.append(elem) for elem in map(asm_iter, iter_data)]

    with open(data_file, 'w') as handle:
        for R5,R6 in data:
            handle.write(R5)
            handle.write('\n')
            handle.write(R6)
            handle.write('\n')

    with open(test_file, 'w') as handle:
        for R5,R6 in data:
            handle.write(R5)
            handle.write('\n')
            handle.write(R6)
            handle.write('\n')
        for elem in test:
            handle.write(elem)
            handle.write('\n')



    
