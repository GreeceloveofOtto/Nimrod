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
def check_maze(layout,level):
    errors=[];checks=0
    def expect(ok,msg):
        nonlocal checks
        checks+=1
        if not ok:errors.append(msg)
    cells={c['id']:c for c in layout['cells']};graph={id:set() for id in cells}
    for a,b in layout['connections']:
        expect(a in cells and b in cells,'Connection has unknown room')
        graph[a].add(b);graph[b].add(a)
        aa=cells[a];bb=cells[b]
        expect(abs(aa['column']-bb['column'])+abs(aa['row']-bb['row'])==1,'Rooms must be adjacent')
    paths={layout['entrance']:[layout['entrance']]};todo=[layout['entrance']]
    while todo:
        a=todo.pop(0)
        for b in graph[a]:
            if b not in paths:paths[b]=paths[a]+[b];todo.append(b)
    expect(len(paths)==len(cells),'Every branch must be reachable')
    expect(layout['exit'] in paths and len(paths[layout['exit']])>=14,'Shortest valid route needs14+rooms')
    expect(sum(len(v)>=3 for v in graph.values())>=4,'Four actual branching rooms required')
    expect(len(layout['dead_ends'])>=3,'At least three dead ends required')
    for id in layout['dead_ends']:expect(id in paths and len(graph[id])==1,'Dead end reachable and degree1')
    platforms={p['id']:p for p in level['platforms']}
    for chain in layout['platform_chains']:
        for a,b in zip(chain,chain[1:]):
            p=platforms[a];q=platforms[b];x,y=p['position'];xx,yy=q['position'];gap=max(0,xx-x-p['width'],x-xx-q['width'])
            expect(gap<=layout['max_gap'] and abs(y-yy)<=layout['max_rise'],'Maze chain exceeds jump limits')
        expect(len(chain)>=8,'640px ascent needs eight80px steps')
    # Room floors now share the one-way rule; graph doors retain intended navigation.
    for p in platforms.values():
        if p['id'].startswith('room_'):expect(p.get('one_way',False),'Room floor must support S+Space')
    print(f"MAZE {level['id']}: {checks} checks, {len(errors)} failures; {len(cells)} rooms, shortest path {len(paths.get(layout['exit'],[]))}")
    for err in errors:print('FAIL:',err)
    return not errors

if __name__=='__main__':
    levels=json.loads((ROOT/'data/levels.json').read_text())['levels'];results=[check(l) for l in levels if 'reachability' in l]
    layouts=json.loads((ROOT/'data/cedar_forest_layout.json').read_text())['layouts']
    results += [check_maze(lay,next(l for l in levels if l['id']==lay['level_id'])) for lay in layouts]
    raise SystemExit(0 if all(results) else 1)
