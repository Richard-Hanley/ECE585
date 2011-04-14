#!/bin/bash

#First assemble each bouncer page
./assembler page0.asm > page0_code.hex
./assembler page1.asm > page1_code.hex
./assembler page2.asm > page2_code.hex
./assembler page3.asm > page3_code.hex

#Now assemble the random data to be worked with
python create_data.py 5 page0_data.hex test_page0.hex
python create_data.py 5 page1_data.hex test_page1.hex
python create_data.py 5 page2_data.hex test_page2.hex
python create_data.py 5 page3_data.hex test_page3.hex

#Now concatenate each page
python build_code.py 0:page0_code.hex 200:test_page0.hex
mv code.hex code0.hex
python build_code.py 0:page1_code.hex 200:test_page1.hex
mv code.hex code1.hex
python build_code.py 0:page2_code.hex 200:test_page2.hex
mv code.hex code2.hex
python build_code.py 0:page3_code.hex 200:test_page3.hex
mv code.hex code3.hex

#put it all together now
python build_code.py 0:code0.hex 512:code1.hex 1024:code2.hex 1536:code3.hex
