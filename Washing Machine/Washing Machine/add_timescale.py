import glob
import os

path = r'c:\Users\HP\Desktop\Washing Machine\Washing Machine.srcs\sources_1\new\*.v'
for f in glob.glob(path):
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    if '`timescale' not in content:
        with open(f, 'w', encoding='utf-8') as file:
            file.write('`timescale 1ns / 1ps\n' + content)
