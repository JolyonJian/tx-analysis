import os
from etherscan.contracts import Contract
import json
import sys

TOKEN = '9FGJN1C5FKQSZRX3RWSZNZUSCVS7TZZF58'

not_valid = []
if os.path.exists('not_valid.json'):
    with open('not_valid.json') as fd:
        not_valid = json.load(fd)
count = 0
count_effective = 0

empty = 0

start = 0
if len(sys.argv) > 2:
    start = int(sys.argv[2])

nb_contracts = 10000
with open('..\\gt8000-all.csv') as fp:
    line = fp.readline()
    while line:
        address = line.split(',')[0]
        if address == 'address':
            line = fp.readline()
            continue
        count += 1
        if start > count:
            line = fp.readline()
            continue
        if address in not_valid:
            line = fp.readline()
            continue
        contract_path = '..\\jsons/%s.json' % (address)
        if os.path.exists(contract_path):
            line = fp.readline()
            continue
        count_effective += 1
        print(count, '/', nb_contracts, round(count_effective * 100 / nb_contracts,
              2), '%', 'empty', empty, round(empty*100/count_effective, 2), '%')
        try:
            api = Contract(address=address, api_key=TOKEN)
            sourcecode = api.get_sourcecode()
            if len(sourcecode[0]['SourceCode']) == 0:
                empty += 1
            with open(contract_path, 'w') as fd:
                json.dump(sourcecode[0], fd)

        except Exception as identifier:
            not_valid.append(address)
            with open('not_valid.json', 'w') as fd:
                json.dump(not_valid, fd)
            print(identifier)
        line = fp.readline()
