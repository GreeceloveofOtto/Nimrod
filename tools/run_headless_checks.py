#!/usr/bin/env python3
"""Import/check every script, run every executable regression test and the smoke test.
Verbose native cleanup diagnostics are retained. Any ERROR, SCRIPT ERROR or WARNING makes the run fail. Never swallow child status.
"""
import argparse,json,os,re,shutil,subprocess,sys,time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BAD=re.compile(r'\b(?:SCRIPT ERROR|ERROR|WARNING)\b')

def find_godot():
 candidates=[os.getenv('GODOT_BIN'),'/workspace/tools/godot43',shutil.which('godot'),shutil.which('godot4')]
 for p in candidates:
  if p and Path(p).is_file():return p
 finder=ROOT/'tools/find_godot.bat'
 if os.name=='nt' and finder.exists():
  p=subprocess.run(['cmd','/c',str(finder)],capture_output=True,text=True,check=True).stdout.strip().splitlines()[-1]
  if Path(p).is_file():return p
 raise RuntimeError('Set GODOT_BIN to the Godot 4.3 executable')

def run(godot,args,label,out,timeout):
 env=os.environ.copy()
 if Path('/workspace/cache').exists():
  for key,part in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:env.setdefault(key,'/workspace/cache/'+part)
 start=time.monotonic()
 try:
  result=subprocess.run([godot,'--headless','--verbose','--path',str(ROOT)]+args,capture_output=True,text=True,timeout=timeout,env=env);log=result.stdout+result.stderr
 except subprocess.TimeoutExpired as error:
  def decode(v):return v.decode(errors='replace') if isinstance(v,bytes) else (v or '')
  log=decode(error.stdout)+decode(error.stderr)+'\nERROR: test exceeded timeout '+str(timeout)+' seconds\n';result=subprocess.CompletedProcess(args,124)
 out.mkdir(parents=True,exist_ok=True);(out/(label+'.log')).write_text(log)
 issues=BAD.findall(log);ok=result.returncode==0 and not issues
 print(f'{"PASS" if ok else "FAIL"} {label} ({time.monotonic()-start:.1f}s)',flush=True)
 if not ok:print(log[-6000:],flush=True)
 return {'label':label,'returncode':result.returncode,'issues':issues,'seconds':round(time.monotonic()-start,2),'passed':ok}

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--test',action='append',default=[]);p.add_argument('--timeout',type=int,default=300);p.add_argument('--skip-import',action='store_true');p.add_argument('--output',default='archive/headless_checks');p.add_argument('--jobs',type=int,default=1,help='Independent Godot processes after the serial import; default 1');a=p.parse_args();godot=find_godot();out=ROOT/a.output;results=[]
 if a.jobs<1:p.error('--jobs must be positive')
 if not a.skip_import:
  results.append(run(godot,['--editor','--quit'],'import',out,a.timeout))
  if not results[-1]['passed']:return 1
 # Check-only must receive a script; a bare --check-only never checks this project.
 scripts=sorted((ROOT/'scripts').glob('*.gd'))
 with ThreadPoolExecutor(max_workers=a.jobs) as pool:
  results.extend(pool.map(lambda script:run(godot,['--check-only','--script','res://'+str(script.relative_to(ROOT))],'parse_'+script.stem,out,a.timeout),scripts))
 tests=[ROOT/'tests'/t for t in a.test] if a.test else sorted((ROOT/'tests').glob('*.gd'))
 # Test trees and run flags live in separate engine processes. The two disk
 # reports (grounding and stuck fuzz) have distinct paths; imports stay serial.
 with ThreadPoolExecutor(max_workers=a.jobs) as pool:
  results.extend(pool.map(lambda test:run(godot,['--script','res://'+str(test.relative_to(ROOT))],test.stem,out,a.timeout),tests))
 (out/'results.json').write_text(json.dumps(results,indent=2));ok=all(r['passed'] for r in results);print(f'HEADLESS: {sum(r["passed"] for r in results)}/{len(results)} passed');return 0 if ok else 1
if __name__=='__main__':sys.exit(main())
