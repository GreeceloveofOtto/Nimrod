#!/usr/bin/env python3
"""Validate continuous ground routes and connected upper routes under actual jump limits."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def check(level):
    errors=[];checks=0;rules=level['reachability'];rise=rules['max_rise'];gap=rules['max_gap'];reference=rules.get('floor_reference',level['floor_y'])
    ground=sorted(level['terrain'],key=lambda p:p['from'])
    def expect(ok,msg):
        nonlocal checks
        checks+=1
        if not ok:errors.append(msg)
    expect(ground[0]['from']==0 and ground[-1]['to']==level['width'],'Ground must cover both ends')
    for a,b in zip(ground,ground[1:]):
        expect(a['to']==b['from'],f"Ground gap/overlap {a['id']}")
        expect(abs(a['y']-b['y'])<=rise,f"Ground step >{rise}px {a['id']}")
    def floor_at(x):return next(p['y'] for p in ground if p['from']<=x<p['to'] or x==level['width']==p['to'])
    platforms={p['id']:p for p in level['platforms']};connections={id:set() for id in platforms};grounded=set()
    for p in platforms.values():
        x,y=p['position'];w=p['width'];local=[g['y'] for g in ground if g['from']<x+w and g['to']>x]
        expect(max(local)-y<=rules['max_local_platform_elevation'],f"{p['id']} exceeds local height")
        low,high=rules.get('elevation_limits',[-120,440]);expect(low<=reference-y<=high,f"{p['id']} elevation outside limits")
        # A painted one-way platform is reachable from a neighboring ground edge or directly below.
        approach=[g['y'] for g in ground if g['from']<=x+w+gap and g['to']>=x-gap]
        if any(0<=g-y<=rise for g in approach):grounded.add(p['id'])
        for q in platforms.values():
            xx,yy=q['position'];horizontal=max(0,xx-(x+w),x-(xx+q['width']))
            if horizontal<=gap and abs(y-yy)<=rise:connections[p['id']].add(q['id'])
    for chain in rules['chains']:
        route=[platforms[id] for id in chain]
        for a,b in zip(route,route[1:]):
            x,y=a['position'];xx,yy=b['position'];horizontal=max(0,xx-(x+a['width']),x-(xx+b['width']))
            expect(horizontal<=gap,f"Gap {a['id']}→{b['id']} >{gap}")
            expect(abs(y-yy)<=rise,f"Rise {a['id']}→{b['id']} >{rise}")
    reached=set(grounded);todo=list(grounded)
    while todo:
        for id in connections[todo.pop()]-reached:reached.add(id);todo.append(id)
    for id in platforms:expect(id in reached,f'{id} has no connected ascent from ground')
    for o in level['obstacles']:expect(o['rect'][3]<=rise,'Obstacle exceeds jump rise')
    for c in level.get('ceilings',[]):
        x,y,w,h=c['rect'];clearance=floor_at(x+w/2)-(y+h)
        expect(clearance==100 and 90<clearance<124,'Crouch tunnel must have 100px clearance')
    if level['id']=='CastleOutskirts':expect(abs(level['doors'][0]['position'][0]-level['doors'][1]['position'][0])==9080,'Exterior gate/passage distance9080')
    if 'door_distance' in rules:expect(abs(level['doors'][0]['position'][0]-level['doors'][1]['position'][0])==rules['door_distance'],'Door distance must remain10000')
    print(f"REACHABILITY {level['id']}: {checks} checks, {len(errors)} failures; jump height {695**2/(2*1750):.2f}px")
    for error in errors:print('FAIL:',error)
    return not errors
if __name__=='__main__':
    levels=json.loads((ROOT/'data/levels.json').read_text())['levels'];results=[check(l) for l in levels if 'reachability' in l]
    raise SystemExit(0 if all(results) else 1)
