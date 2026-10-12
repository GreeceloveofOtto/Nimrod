#!/usr/bin/env python3
"""Convert synthesized audio with ffmpeg Vorbis, archive WAV sources, rewrite only successes."""
import argparse,json,shutil,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def convert(path,archive=True):
    output=path.with_suffix('.ogg')
    encoding=['-b:a','48k'] if 'bgm' in path.parts else ['-q:a','3']
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(path),'-ac','1','-ar','44100','-c:a','libvorbis',*encoding,str(output)],check=True)
    check=subprocess.run(['ffprobe','-v','error','-show_entries','stream=sample_rate,channels','-of','json',str(output)],capture_output=True,text=True,check=True)
    s=json.loads(check.stdout)['streams'][0]
    if int(s['sample_rate'])!=44100 or int(s['channels'])!=1:raise ValueError(f'Incorrect audio format: {output}')
    if archive:
        target=ROOT/'archive/audio_wav'/path.relative_to(ROOT/'assets/audio');target.parent.mkdir(parents=True,exist_ok=True);shutil.move(path,target)
    return output

def rewrite(mapping):
    for folder in ['scripts','data','scenes','assets']:
        for p in (ROOT/folder).rglob('*'):
            if p.suffix not in ['.gd','.json','.tscn','.tres']:continue
            text=p.read_text();new=text
            for old,out in mapping.items():new=new.replace(old,out)
            if new!=text:p.write_text(new)

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('files',nargs='*');p.add_argument('--keep-wav',action='store_true');a=p.parse_args();files=[Path(f).resolve() for f in a.files] or sorted((ROOT/'assets/audio').rglob('*.wav'));mapping={}
    for f in files:
        if 'legacy' in f.parts:continue
        out=convert(f,not a.keep_wav);mapping['res://'+str(f.relative_to(ROOT))]='res://'+str(out.relative_to(ROOT))
    rewrite(mapping);print(f'AUDIO_OGG: {len(mapping)} files converted')
    (ROOT/'archive/audio_conversion.json').write_text(json.dumps(mapping,indent=2))
if __name__=='__main__':main()
