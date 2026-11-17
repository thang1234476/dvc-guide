import json
for p in json.load(open('data/clean.json', encoding='utf-8')):
    if 'kết hôn' in p['ten'].lower(): print(p['ma_thu_tuc'], p['ten'])

