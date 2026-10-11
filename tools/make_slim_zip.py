#!/usr/bin/env python3
"""Build a clean download, including source/tests/tools but excluding archive and caches.
Extract-and-test with --verify to check the package independently of the worktree.
"""
import argparse,hashlib,json,os,shutil,subprocess,sys,tempfile,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
IGNORED={'.git','.godot','archive','__pycache__','.codex','.agents','source_art','reference','sprite_qa','motion_review','generated_images'}
def files():
 screenshots=sorted((ROOT/'docs/screenshots').glob('*.jpg'),key=lambda p:p.stat().st_mtime,reverse=True)[:20]
 for folder,dirs,names in os.walk(ROOT):
  dirs[:]=[d for d in dirs if d not in IGNORED and not d.startswith('_legacy') and not (Path(folder)/d/'.gdignore').exists()]
  for name in names:
   p=Path(folder)/name
   if 'docs/screenshots' in p.as_posix() and p not in screenshots:continue
   if p.suffix in ['.import','.uid','.pyc','.zip','.tmp'] or name in ['.DS_Store']:continue
   yield p

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',default='/workspace/downloads/Nimrod_slim_2026-10-11.zip');p.add_argument('--verify',action='store_true');a=p.parse_args();out=Path(a.output);out.parent.mkdir(parents=True,exist_ok=True);entries=list(files());asset_bytes=sum(f.stat().st_size for f in entries if 'assets' in f.relative_to(ROOT).parts)
 with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for f in entries:z.write(f,'Nimrod/'+str(f.relative_to(ROOT)))
 print(f'PACKAGE: {len(entries)} files, runtime assets {asset_bytes/1048576:.2f} MiB, ZIP {out.stat().st_size/1048576:.2f} MiB -> {out}',flush=True)
 size_ok=asset_bytes<=100*1048576 and out.stat().st_size<=120*1048576
 ok=size_ok;checks=[];target=None
 if a.verify:
  target=Path(tempfile.mkdtemp(prefix='nimrod-stage7-',dir='/tmp'))
  with zipfile.ZipFile(out) as z:z.extractall(target)
  project=target/'Nimrod'
  for command in [['python','tools/run_headless_checks.py','--output','archive/package_verification'],['python','tools/validate_assets.py'],['python','tools/check_alpha_cleanliness.py'],['python','tools/check_level_reachability.py']]:
   result=subprocess.run(command,cwd=project);checks.append({'command':command,'returncode':result.returncode});ok=ok and result.returncode==0
  print('EXTRACTED:',project)
 report={'zip':str(out),'asset_bytes':asset_bytes,'zip_bytes':out.stat().st_size,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'size_goals_passed':size_ok,'extracted_project':str(target/'Nimrod') if target else None,'checks':checks,'functional_verification_passed':bool(checks) and all(c['returncode']==0 for c in checks)}
 (ROOT/'archive').mkdir(exist_ok=True);(ROOT/'archive/package_report.json').write_text(json.dumps(report,indent=2)+'\n')
 print('SIZE GOALS:', 'PASS' if size_ok else 'NOT MET',flush=True)
 if checks:print('EXTRACTED FUNCTIONAL CHECKS:', 'PASS' if report['functional_verification_passed'] else 'FAIL',flush=True)
 return 0 if ok else 1
if __name__=='__main__':sys.exit(main())
