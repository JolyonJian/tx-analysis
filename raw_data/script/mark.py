# -*- coding:utf-8 -*-

import pandas as pd
import csv
import xlrd

erc20 = set()
erc721 = set()
data = []

with open('..\\gt8000-erc20.csv') as csv_file:
    row = csv.reader(csv_file)
    next(row)
    for r in row:
        erc20.add(r[0])
        
with open('..\\gt8000-erc721.csv') as csv_file:
    row = csv.reader(csv_file)
    next(row)
    for r in row:
        erc721.add(r[0])

wb = xlrd.open_workbook('..\\gt8000-all.xlsx')
#按工作簿定位工作表
sh = wb.sheet_by_name('gt8000-all')
for i in range(sh.nrows):
    if i == 0:
        continue
    entry = dict(zip(sh.row_values(0),sh.row_values(i)))
    if entry['address'] in erc20:
        entry['is_erc20'] = 1
    else:
        entry['is_erc20'] = 0
    if entry['address'] in erc721:
        entry['is_erc721'] = 1
    else:
        entry['is_erc721'] = 0
    data.append(entry)

pd.DataFrame(data).to_excel('..\\marked.xlsx')
