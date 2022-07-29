import json
import os
path = "..\\jsons\\"
files= os.listdir(path)
for file in files:
    fr = open(path + file, 'r')
    content = json.loads(fr.read())
    code = content['SourceCode']
    fr.close()
    fw = open('..\\codes\\%s.sol' % (file[:-5]), 'w', encoding='utf-8')
    fw.write(code)
    fw.close()
    
        