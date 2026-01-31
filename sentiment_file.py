import zipfile, xml.etree.ElementTree as ET
from collections import Counter

path = "data/dats_youscan2.xlsx"
NS = {'s': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}

def load_shared(z):
    shared = []
    try:
        with z.open('xl/sharedStrings.xml') as f:
            root = ET.parse(f).getroot()
            for si in root.findall('s:si', NS):
                texts = [t.text or '' for t in si.findall('.//s:t', NS)]
                shared.append(''.join(texts))
    except KeyError:
        pass
    return shared

def cell_value(c, shared):
    t = c.attrib.get('t')
    if t == 's':
        v = c.find('s:v', NS)
        if v is None: return ''
        try: return shared[int(v.text)]
        except Exception: return v.text or ''
    if t == 'inlineStr':
        is_node = c.find('s:is', NS)
        if is_node is None: return ''
        texts = [t.text or '' for t in is_node.findall('.//s:t', NS)]
        return ''.join(texts)
    v = c.find('s:v', NS)
    return '' if v is None else (v.text or '')

with zipfile.ZipFile(path) as z:
    shared = load_shared(z)
    with z.open('xl/worksheets/sheet1.xml') as f:
        root = ET.parse(f).getroot()
        rows = []
        for row in root.findall('s:sheetData/s:row', NS):
            cells = {}
            for c in row.findall('s:c', NS):
                r = c.attrib.get('r')
                col = ''.join(ch for ch in r if ch.isalpha()) if r else ''
                cells[col] = cell_value(c, shared)
            rows.append(cells)

headers = {col: (rows[0].get(col, '') if rows else '').strip()
           for col in (rows[0] if rows else {})}
# localizar columnas de Sentimiento y Marco Bonilla
col_sent = next((c for c,h in headers.items() if h == 'Sentimiento'), None)
col_mb = next((c for c,h in headers.items() if h == 'Marco Bonilla'), None)

cnt = Counter()
for row in rows[1:]:
    if col_mb and (row.get(col_mb, '').strip().lower() == 'marco bonilla'):
        sent = row.get(col_sent, '').strip() if col_sent else ''
        cnt[sent or 'SIN_SENTIMIENTO'] += 1

print(cnt)
print("total", sum(cnt.values()))
