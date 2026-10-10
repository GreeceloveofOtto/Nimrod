#!/usr/bin/env python3
"""Verify generated stage5 PCM format, lengths, peaks and loop seam samples."""
import json,wave
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
def main():
    specs=json.loads((ROOT/'data/audio_stage5.json').read_text());checks=0;errors=[]
    def expect(ok,label):
        nonlocal checks
        checks+=1
        if not ok:errors.append(label)
    for kind in ['sfx','bgm']:
        for spec in specs[kind]:
            name=spec['name'];p=ROOT/'assets/audio'/kind/(name+'.wav')
            with wave.open(str(p)) as w:
                expect(w.getnchannels()==1 and w.getsampwidth()==2 and w.getframerate()==44100,name+' mono16/44100')
                expect(abs(w.getnframes()/44100-spec['duration'])<1/44100,name+' duration')
                a=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(float)
                expect(np.max(np.abs(a))<=32767*10**(-3/20)+1,name+' peak <=-3dBFS')
                if kind=='bgm' or spec.get('loop',False):
                    seam=abs(a[0]-a[-1]);normal=np.quantile(np.abs(np.diff(a)),.999)
                    expect(seam<=max(3,normal*2),name+' periodic seam')
                    print('LOOP',name,'seam',seam,'normal99.9%',round(normal,1))
    print(f'STAGE5_AUDIO: {checks} checks, {len(errors)} failures')
    for e in errors:print('FAIL:',e)
    return not errors
if __name__=='__main__':raise SystemExit(0 if main() else 1)
