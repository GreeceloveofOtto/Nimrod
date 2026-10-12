#!/usr/bin/env python3
"""Change only standalone subject 너가; leave 너는/너에게/너의 and compounds alone."""
from pathlib import Path
import re,argparse,json
R=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser();p.add_argument('--apply',action='store_true');a=p.parse_args();rows=[]
 for folder,ext in [('data','.json'),('scripts','.gd')]:
  for path in (R/folder).glob('*'+ext):
   text=path.read_text();new=re.sub(r'(?<![가-힣A-Za-z0-9_])너가(?![가-힣A-Za-z0-9_])','네가',text)
   for i,(old,current) in enumerate(zip(text.splitlines(),new.splitlines()),1):
    if old!=current:rows.append({'file':str(path.relative_to(R)),'line':i,'before':old,'after':current})
   if a.apply and text!=new:path.write_text(new)
 print(json.dumps(rows,ensure_ascii=False,indent=2))
if __name__=='__main__':main()
