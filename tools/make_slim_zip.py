#!/usr/bin/env python3
"""Build a clean download, including source/tests/tools but excluding archive and caches.
Extract-and-test with --verify to check the package independently of the worktree.
"""
import argparse,hashlib,json,os,re,shutil,subprocess,sys,tempfile,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
IGNORED={'.git','.godot','archive','__pycache__','.codex','.agents','source_art','reference','sprite_qa','motion_review','generated_images','artifacts','pack_source','downloads'}
def files():
 doc_images=[] # All development captures are supplied separately, never in the slim runtime ZIP.
 for folder,dirs,names in os.walk(ROOT):
  dirs[:]=[d for d in dirs if d not in IGNORED and not d.startswith('_legacy') and not (Path(folder)/d/'.gdignore').exists()]
  for name in names:
   p=Path(folder)/name
   if 'docs' in p.relative_to(ROOT).parts and p.suffix.lower() in ['.png','.jpg','.jpeg'] and p not in doc_images:continue
   if p.suffix in ['.import','.uid','.pyc','.zip','.tmp'] or name in ['.DS_Store']:continue
   yield p

def write_archive(out, entries):
 """Godot's project importer only creates directories explicitly listed in ZIPs."""
 written_dirs=set()
 with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
  for f in entries:
   name=Path('Nimrod')/f.relative_to(ROOT)
   for parent in reversed(name.parents):
    if parent==Path('.'):continue
    directory=parent.as_posix()+'/'
    if directory not in written_dirs:
     info=zipfile.ZipInfo(directory);info.create_system=3;info.external_attr=(0o40755<<16)|0x10
     z.writestr(info,b'');written_dirs.add(directory)
   z.write(f,name.as_posix())
 return len(written_dirs)

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',default=str(ROOT/'downloads/Nimrod_stage13_2026-10-13.zip'));p.add_argument('--verify',action='store_true');a=p.parse_args();out=Path(a.output);out.parent.mkdir(parents=True,exist_ok=True);entries=list(files());asset_bytes=sum(f.stat().st_size for f in entries if 'assets' in f.relative_to(ROOT).parts)
 directory_count=write_archive(out,entries)
 from check_zip_import import check_import
 import_check=check_import(out)
 assert import_check['failed_files']==[], 'Godot ZIP import compatibility failed'
 print(f'PACKAGE: {len(entries)} files, runtime assets {asset_bytes/1048576:.2f} MiB, ZIP {out.stat().st_size/1048576:.2f} MiB -> {out}',flush=True)
 budget=json.loads((ROOT/'data/stage13_budget.json').read_text())
 new_bytes=sum((ROOT/name).stat().st_size for name in budget['new_assets'])
 size_ok=asset_bytes<=budget['baseline_assets_bytes']+budget['new_assets_limit_bytes'] and out.stat().st_size<=budget['zip_target_mib']*1048576 and new_bytes<=budget['new_assets_limit_bytes']
 ok=size_ok;checks=[];target=None
 if a.verify:
  target=Path(tempfile.mkdtemp(prefix='nimrod-stage13-',dir='/tmp'))
  with zipfile.ZipFile(out) as z:z.extractall(target)
  project=target/'Nimrod'
  for command in [['python','tools/run_headless_checks.py','--jobs','4','--output','archive/package_verification'],['python','tools/validate_assets.py'],['python','tools/check_alpha_cleanliness.py'],['python','tools/check_level_reachability.py'],['python','tools/check_sprite_frames.py'],['python','tools/check_all_sprite_frames.py'],['python','tools/check_enemy_grounding.py'],['python','tools/check_enemy_visual_bounds.py'],['python','tools/check_prop_contact.py'],['python','tools/check_head_ghost.py']]:
   result=subprocess.run(command,cwd=project);checks.append({'command':command,'returncode':result.returncode});ok=ok and result.returncode==0
  print('EXTRACTED:',project)
 report={'zip':str(out),'asset_bytes':asset_bytes,'zip_bytes':out.stat().st_size,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'directory_entries':directory_count,'godot_zip_import':import_check,'size_goals_passed':size_ok,'extracted_project':str(target/'Nimrod') if target else None,'checks':checks,'functional_verification_passed':bool(checks) and all(c['returncode']==0 for c in checks)}
 (ROOT/'archive').mkdir(exist_ok=True);(ROOT/'archive/package_report.json').write_text(json.dumps(report,indent=2)+'\n')
 if not size_ok:
  largest=sorted((f for f in entries if 'assets' in f.relative_to(ROOT).parts and f.suffix.lower() in ['.png','.webp']),key=lambda f:f.stat().st_size,reverse=True)[:20]
  candidates=[{'path':str(f.relative_to(ROOT)),'bytes':f.stat().st_size,'candidate':'Recheck runtime references; if required, try lower density only when SSIM >=.93 and game bounds are preserved','estimated_savings_bytes':int(f.stat().st_size*.1)} for f in largest]
  report['budget_candidates']=candidates;(ROOT/'archive/package_report.json').write_text(json.dumps(report,indent=2)+'\n')
  text='\n## 패키지 용량 목표 미달 후보\n\n'+''.join(f"- {r['path']}: {r['bytes']/1048576:.2f}MiB, 참조/SSIM 재검토 후 예상 {r['estimated_savings_bytes']/1048576:.2f}MiB 절감.\n" for r in candidates)
  document=ROOT/'docs/SIZE_REPORT_KO.md'
  previous=re.sub(r'\n## 패키지 용량 목표 미달 후보\n\n(?:- assets/[^\n]+\n)+','',document.read_text())
  document.write_text(previous+text)
 print('SIZE GOALS:', 'PASS' if size_ok else 'NOT MET',flush=True)
 if checks:print('EXTRACTED FUNCTIONAL CHECKS:', 'PASS' if report['functional_verification_passed'] else 'FAIL',flush=True)
 return 0 if ok else 1
if __name__=='__main__':sys.exit(main())
