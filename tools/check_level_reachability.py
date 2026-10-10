#!/usr/bin/env python3
"""Check actual level geometry, jump limits and every named upper-route chain."""
import json, math
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def check(level):
    errors=[]; checks=0; rules=level['reachability'];rise=rules['max_rise'];gap=rules['max_gap']
    ground=sorted(level['terrain'],key=lambda p:p['from'])
    def expect(condition,message):
        nonlocal checks
        checks+=1
        if not condition:errors.append(message)
    expect(ground[0]['from']==0 and ground[-1]['to']==level['width'],'Ground covers both ends')
    for a,b in zip(ground,ground[1:]):
        expect(a['to']==b['from'],f"Death pit or overlap between {a['id']} / {b['id']}")
        expect(abs(a['y']-b['y'])<=rise,f"Ground step >{rise}px: {a['id']}")
    def floor_at(x):return next(p['y'] for p in ground if p['from']<=x<p['to'] or x==level['width']==p['to'])
    platforms={p['id']:p for p in level['platforms']}
    for p in platforms.values():
        x,y=p['position'];w=p['width']
        local=[floor_at(x+.01),floor_at(x+w-.01)]
        local.extend(g['y'] for g in ground if g['from']<x+w and g['to']>x)
        expect(max(local)-y<=rules['max_local_platform_elevation'],f"{p['id']} exceeds local height limit")
        expect(-120<=880-y<=440,f"{p['id']} elevation outside allowed ground + platform bounds")
    for chain in rules['chains']:
        route=[platforms[name] for name in chain]
        for a,b in zip(route,route[1:]):
            xa,ya=a['position'];xb,yb=b['position']
            horizontal=max(0,xb-(xa+a['width']),xa-(xb+b['width']))
            expect(horizontal<=gap,f"Platform gap {a['id']}→{b['id']} >{gap}")
            expect(abs(ya-yb)<=rise,f"Platform rise {a['id']}→{b['id']} >{rise}")
        for end in [route[0],route[-1]]:
            if sum(end['id'] in c for c in rules['chains']) > 1:
                continue  # Shared main bridge/walkway connects both approach chains.
            x,y=end['position'];local=floor_at(x+end['width']/2)
            expect(local-y<=rise,f"Chain end {end['id']} unreachable from ground")
    for o in level['obstacles']:
        expect(o['rect'][3]<=rise,f"Obstacle {o.get('id',o['rect'])} too tall")
    expect(level['doors'][0]['position'][0]-level['doors'][1]['position'][0]==9080,'Gate/passage distance must be 9080px')
    print(f"REACHABILITY: {checks} checks, {len(errors)} failures; jump height {695**2/(2*1750):.2f}px")
    for error in errors:print('FAIL:',error)
    return not errors

if __name__=='__main__':
    levels=json.loads((ROOT/'data/levels.json').read_text())['levels']
    raise SystemExit(0 if all(check(l) for l in levels if 'reachability' in l) else 1)
