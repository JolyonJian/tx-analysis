import json
import os
import re


def parser(sources):
    res = ''
    for key in sources:
        pattern = re.compile('.*[sol]$')
        if re.search(pattern, key) is not None:
            for item in sources[key]:
                res += '// ' + key + '\n\n'
                res += sources[key][item] + '\n\n'
            return res


path = "..\\..\\contracts\\"
files = os.listdir(path)
for file in files:
    res = ''
    fr = open(path + file, 'r', encoding='utf8')
    str = fr.read()
    try:
        content = json.loads(str)
        print('%s is json format!' % file)
        res = parser(content)
    except ValueError:
        try:
            content = json.loads(str[1:-1])
            res = parser(content['sources'])
        except ValueError:
            print('%s is not json format.' % file)
    fr.close()
    if res is not '':
        fw = open("..\\..\\recontracts\\" + file, 'w', encoding='utf-8')
        fw.write(res)
        print('%s has been rewritten!' % file)
        fw.close()
