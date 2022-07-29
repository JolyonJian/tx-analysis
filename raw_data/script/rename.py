# -*- coding:utf-8 -*-

import os
import xlrd

wb = xlrd.open_workbook('..\\marked.xlsx')
sh = wb.sheet_by_name('Sheet1')
for i in range(sh.nrows):
    if i == 0:
        continue
    entry = dict(zip(sh.row_values(0),sh.row_values(i)))
    old_name = '..\\codes\\%s.sol' % (entry['address'])
    new_name = '..\\codes\\%s_%s_%s.sol' % (i, int(entry['tx_count']), entry['address'])
    os.rename(old_name, new_name)
