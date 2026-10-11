#!/usr/bin/env python3
"""Audit static clip requests, aliases and actual PNGs for every EnemyBase type."""
import json,re
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def check():
 lines=[];errors=[]
 standard={'idle','walk','windup','attack','recovery','turn','hurt','death'}
 codefiles=['enemy_base.gd','enemy_stage5.gd','enemy_cedar.gd','enemy_kala_ushumgal.gd','enemy_melee_beast.gd','enemy_ranged_beast.gd','enemy_sky_beast.gd']
 static={name:sorted(set(re.findall(r'_show_clip\("([^"\n]+)"', (R/'scripts'/name).read_text()))) for name in codefiles}
 lines.append('Static literal _show_clip calls: '+json.dumps(static,ensure_ascii=False))
 for e in json.loads((R/'data/enemies.json').read_text())['enemies']:
  m=json.loads((R/'assets/sprites/enemies'/e['id']/'manifest.json').read_text());clips={c['name']:c for c in m['clips']};aliases=m.get('aliases',{});requests=standard|{c['name'] for c in e.get('clips',[])}
  if e['id']=='kala_ushumgal':requests.update(static['enemy_kala_ushumgal.gd'])
  missing=[]
  for name in sorted(requests):
   resolved=name if name in clips else aliases.get(name,'')
   if resolved not in clips:missing.append(name)
   elif not (R/'assets'/clips[resolved]['sheet']).is_file():errors.append(e['id']+'/'+resolved+' PNG missing')
  if missing:errors.append(e['id']+': unmapped '+','.join(missing))
  lines.append(e['id']+': '+str(len(clips))+' clips; aliases='+json.dumps(aliases,ensure_ascii=False)+'; missing='+str(missing))
 lines.append(f'Clip audit: {len(errors)} failures');lines.extend('FAIL '+e for e in errors);text='\n'.join(lines)+'\n';(R/'docs/STAGE6_CLIP_AUDIT.txt').write_text(text);print(text,end='');return not errors
if __name__=='__main__':raise SystemExit(not check())
