#!/usr/bin/env python3
"""Build and independently verify the Stage15 landing approval checkpoint."""
from pathlib import Path
import argparse,hashlib,json,subprocess,sys,tempfile,time,zipfile
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from make_slim_zip import files,write_archive
from check_zip_import import check_import
A=ROOT/'archive/stage15_map'
EXCLUDED={'data/world/zabulistan/art_quality.json','docs/stage14_rework_placements.json'}
def main():
 p=argparse.ArgumentParser();p.add_argument('--verify',action='store_true');args=p.parse_args()
 out=ROOT/'downloads/Nimrod_stage15_landing_review_2026-10-16.zip';out.parent.mkdir(exist_ok=True)
 entries=[f for f in files() if f.relative_to(ROOT).as_posix() not in EXCLUDED]
 dirs=write_archive(out,entries);compat=check_import(out)
 report={'scope':'landing_approval_checkpoint','zip_bytes':out.stat().st_size,'asset_bytes':sum(f.stat().st_size for f in entries if f.relative_to(ROOT).parts[0]=='assets'),'world_art_bytes':sum(f.stat().st_size for f in entries if f.relative_to(ROOT).parts[:3]==('assets','world','zabulistan_v2')),'world_data_bytes':sum(f.stat().st_size for f in entries if f.relative_to(ROOT).parts[:2]==('data','world')),'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'directory_entries':dirs,'import_compatibility':compat,'full_map_goals_pending':True,'checks':[]}
 A.mkdir(parents=True,exist_ok=True)
 # Freeze the exact candidate bytes for comparison with the documentation-only repack.
 report['candidate_files']={str(f.relative_to(ROOT)):hashlib.sha256(f.read_bytes()).hexdigest() for f in entries}
 (A/'package_report.json').write_text(json.dumps(report,indent=2)+'\n')
 print('PACKAGE',out,report['zip_bytes']/1048576,'MiB',flush=True)
 if args.verify:
  temp=Path(tempfile.mkdtemp(prefix='nimrod-stage15-',dir='/tmp'))
  with zipfile.ZipFile(out) as z:z.extractall(temp)
  project=temp/'Nimrod';quality=temp/'expected_art_quality.json';quality.write_bytes((ROOT/'data/world/zabulistan/art_quality.json').read_bytes())
  commands=[['tools/run_headless_checks.py','--jobs','4','--output','archive/package_verification']]
  commands += [[f'tools/{name}.py'] for name in ['validate_assets','check_alpha_cleanliness','check_level_reachability','check_sprite_frames','check_all_sprite_frames','check_enemy_grounding','check_enemy_visual_bounds','check_prop_contact','check_head_ghost','check_siyavash_face']]
  commands += [['tools/measure_assets.py','--plaza-budget','--output','archive/plaza_budget.json'],['tools/world/validate_world.py'],['tools/check_tileset_seams.py'],['tools/qa/check_tileset_seams.py'],['tools/qa/check_world_art.py','--quality-file',str(quality)],['tools/qa/check_carved_art.py','--quality-file',str(quality)]]
  report['extracted_project']=str(project)
  for i,command in enumerate(commands):
   start=time.monotonic();log=A/f'package_{i:02}_{Path(command[0]).stem}.log'
   print('VERIFY',i,command,flush=True)
   with log.open('w') as output:result=subprocess.run([sys.executable]+command,cwd=project,stdout=output,stderr=subprocess.STDOUT)
   report['checks'].append({'command':command,'returncode':result.returncode,'seconds':round(time.monotonic()-start,2),'log':str(log.relative_to(ROOT))})
   print('RESULT',result.returncode,log,flush=True)
   (A/'package_report.json').write_text(json.dumps(report,indent=2)+'\n')
  report['functional_verification_passed']=all(c['returncode']==0 for c in report['checks']) and not compat['failed_files']
  (A/'package_report.json').write_text(json.dumps(report,indent=2)+'\n')
  return int(not report['functional_verification_passed'])
 return int(bool(compat['failed_files']))
if __name__=='__main__':raise SystemExit(main())
