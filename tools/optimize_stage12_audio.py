#!/usr/bin/env python3
"""Re-encode immutable synthesized WAV music as mono Vorbis; reject worse loop seams/peaks."""
import json,subprocess,shutil
from pathlib import Path
import numpy as np
R=Path(__file__).resolve().parents[1];A=R/'archive/stage12/audio_before';A.mkdir(parents=True,exist_ok=True)
def decode(path):
 return np.frombuffer(subprocess.run(['ffmpeg','-v','error','-i',str(path),'-ac','1','-ar','44100','-f','f32le','pipe:1'],check=True,capture_output=True).stdout,dtype=np.float32)
def main():
 rows=[]
 for path in sorted((R/'assets/audio/bgm').glob('*.ogg')):
  source=R/'archive/audio_wav/bgm'/(path.stem+'.wav')
  if not source.exists():continue
  out=R/'archive/stage12'/(path.stem+'_36k.ogg')
  subprocess.run(['ffmpeg','-v','error','-y','-i',str(source),'-ac','1','-ar','44100','-c:a','libvorbis','-b:a','36k',str(out)],check=True)
  old=decode(path);new=decode(out);seam0=abs(float(old[-1]-old[0]));seam1=abs(float(new[-1]-new[0]));peak=float(np.abs(new).max());ok=len(old)==len(new) and seam1<=seam0+.01 and peak<.99 and out.stat().st_size<path.stat().st_size
  row={'path':str(path.relative_to(R)),'before':path.stat().st_size,'candidate':out.stat().st_size,'sample_count_unchanged':len(old)==len(new),'old_seam':seam0,'new_seam':seam1,'peak':peak,'accepted':ok}
  if ok:
   shutil.copy2(path,A/path.name);shutil.copy2(out,path)
  rows.append(row)
 (R/'archive/stage12/audio_trials.json').write_text(json.dumps(rows,indent=2))
 print('AUDIO',sum(x['accepted'] for x in rows),'accepted; savings',sum(x['before']-x['candidate'] for x in rows if x['accepted'])/1048576,'MiB')
if __name__=='__main__':main()
