#!/usr/bin/env python3
"""Run every executable headless test on Godot 4.3; retain counts and exit status."""
import argparse, json, os, re, subprocess, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'));parser.add_argument('--report',default=str(ROOT/'docs/STAGE4_TEST_RESULTS.json'));args=parser.parse_args()
    version=subprocess.check_output([args.godot,'--version'],text=True).strip()
    if not version.startswith('4.3.'):raise SystemExit('Godot 4.3 required, got '+version)
    logs=Path(os.environ.get('NIMROD_TEST_LOG_DIR','/tmp/nimrod-stage4-tests'));logs.mkdir(parents=True,exist_ok=True)
    results=[]
    for path in sorted((ROOT/'tests').glob('*.gd')):
        if path.name.startswith('render'):continue # A real renderer is checked separately.
        start=time.monotonic()
        try:
            run=subprocess.run([args.godot,'--headless','--path',str(ROOT),'--script',str(path)],cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=240)
            output=run.stdout;code=run.returncode
        except subprocess.TimeoutExpired as error:
            output=(error.stdout or b'').decode() if isinstance(error.stdout,bytes) else error.stdout or '';code=124
        (logs/(path.stem+'.log')).write_text(output)
        found=re.search(r'(\d+) checks, (\d+) failures',output)
        if not found:
            alternate=re.search(r'checks: (\d+); failures: (\d+)',output)
            found=alternate
        checks,failures=(int(found[1]),int(found[2])) if found else (0,1)
        passed=code==0 and checks>0 and failures==0 and 'SCRIPT ERROR' not in output and '\nERROR:' not in output
        result=dict(test=path.name,checks=checks,failures=failures,exit_code=code,passed=passed,seconds=round(time.monotonic()-start,2));results.append(result)
        print(('PASS' if passed else 'FAIL'),result,flush=True)
        if not passed:print(output[-3000:],flush=True)
    report=dict(godot_version=version,tests=results,total_checks=sum(r['checks'] for r in results),all_passed=all(r['passed'] for r in results))
    Path(args.report).write_text(json.dumps(report,indent=2)+'\n')
    return 0 if report['all_passed'] else 1

if __name__=='__main__':raise SystemExit(main())
