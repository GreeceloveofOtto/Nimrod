#!/usr/bin/env python3
"""Data-authored level collision, routes and actors; no procedural visual art."""
import json
from pathlib import Path
from build_stage5_data import SPECS,save
ROOT=Path(__file__).resolve().parents[1]
PALETTES=[('로비 홀',[.50,.32,.65]),('계단 홀',[.32,.32,.62]),('3단 캣워크',[.20,.28,.51]),('심연 교량',[.19,.30,.22]),('기계 지주 숲',[.28,.44,.56]),('돌진 회랑',[.60,.37,.19]),('저천장 터널',[.37,.10,.16]),('최심부 수직 통로',[.48,.09,.14])]

def door(id,x,y,target,spawn,arrival,art='passage_door',direction=1,**extra):return dict(door_id=id,position=[x,y],target_level=target,target_spawn=spawn,arrival_spawn=arrival,door_art='res://assets/props/doors/'+art+'.png',exit_direction=direction,**extra)
def platform(id,x,e,w=180,folder='passage',art='platform',floor=620):return dict(id=id,position=[x,floor-e],width=w,art='res://assets/tiles/'+folder+'/'+art+'.png',art_height=48)
def terrain(segments,floor,folder):return [dict(id='ground_'+str(a),**{'from':a,'to':b},y=floor-e,art='res://assets/tiles/'+folder+'/ground_tile.png' if folder=='homeroad' else 'res://assets/tiles/passage/floor_tile.webp') for a,b,e in segments]
def ground_at(l,x):return next(g['y'] for g in l['terrain'] if g['from']<=x<g['to'] or x==l['width']==g['to'])
def enemy(l,id,x,y=None,patrol=180,**extra):
    l['enemies'].append(dict(id=id,position=[x,ground_at(l,x) if y is None else y],patrol_center=x,patrol_range=patrol,**extra))
def prop(l,name,x,y,w,h,z=-2):l['decorations'].append(dict(path='res://assets/props/'+name+'.png',position=[x,y],size=[w,h],z=z))
def main():
    registry=json.loads((ROOT/'data/levels.json').read_text());levels={l['id']:l for l in registry['levels']}
    registry['world']['enemy_scripts'].update({s[0]:'res://scripts/enemy_'+s[0]+'.gd' for s in SPECS})
    outside=levels['CastleOutskirts'];outside['spawns']['Spawn_FromPassage']=[640,680]
    for d in outside['doors']:
        if d['door_id']=='downtown_passage_entrance':
            d.update(locked=False,target_level='DowntownPassage_F8',target_spawn='Spawn_FromTop',arrival_spawn='Spawn_FromPassage',exit_direction=1,door_art='res://assets/props/doors/downtown_passage_door_anim.webp')
    roster=json.loads((ROOT/'data/passage_floors.json').read_text())
    for n in range(1,9):
        id='DowntownPassage_F'+str(n)
        height=960 if n in [4,8] else 800
        l=dict(id=id,scene='res://scenes/'+id+'.tscn',width=3600,floor_y=620,bgm='passage_descent',display_name=f'도심 방향 통로 {n}층',theme_name=PALETTES[n-1][0],palette=PALETTES[n-1][1],bg_dim=[.88,.88,.92],ceiling=True,camera_limits=[0,0,3600,height],safe_zones=[[0,-100,420,height+200],[3250,-100,350,height+200]],backgrounds=[dict(name='PassageInterior',path=f'res://assets/backgrounds/passage/passage_f{n}_bg.png',position=[0,0],size=[3600,height],ratio=1,z=-25)],spawns={'Spawn_FromAbove':[3330,620],'Spawn_FromBelow':[300,620]},doors=[],npcs=[],enemies=[],decorations=[],steps=[],platforms=[],obstacles=[],floor_art='res://assets/tiles/passage/floor_tile.webp',floor_art_size=[512,180],drop_rule=dict(mode='only_listed',listed={'explosive_spitter':.07}) if n<=3 else dict(mode='all',chance=.05),perches=[],ceilings=[],reachability=dict(max_rise=110,max_gap=200,max_local_platform_elevation=500,chains=[],floor_reference=620,elevation_limits=[-140,400],required_ground_route=[0,3600]))
        if n==8:l['spawns']['Spawn_FromTop']=[3330,620]
        l['doors']=[door('door_up',3450,620,'CastleOutskirts' if n==8 else 'DowntownPassage_F'+str(n+1),'Spawn_FromPassage' if n==8 else 'Spawn_FromBelow','Spawn_FromTop' if n==8 else 'Spawn_FromAbove', 'downtown_passage_door_anim' if n==8 else 'passage_door',-1),door('door_down',220,620,'HomeRoad' if n==1 else 'DowntownPassage_F'+str(n-1),'Spawn_FromPassage' if n==1 else 'Spawn_FromAbove','Spawn_FromBelow',direction=1)]
        segments=[(0,3600,0)]
        chains=[]
        if n==1:
            segments=[(0,900,0),(900,1200,60),(1200,1500,110),(1500,1800,60),(1800,3600,0)]
            l['platforms']=[platform('high',2500,110,500),platform('left_access',2320,55),platform('right_access',3000,55)]
            chains=[['left_access','high','right_access']]
        elif n==2:
            segments=[(0,900,0),(900,1200,60),(1200,1500,120),(1500,2100,180),(2100,2400,120),(2400,2700,60),(2700,3600,0)]
            l['platforms']=[platform('root_left',1320,200),platform('root_right',2150,200)]
            # Roots are reachable from raised adjacent terraces; both below jump limit.
        elif n==3:
            l['platforms']=[platform('middle',1000,120,2000),platform('upper',2100,240,1000),platform('left60',800,60),platform('left180',1920,180),platform('right60',3000,60),platform('right180',3100,180),platform('right120',3280,120),platform('right0',3280,60)]
            chains=[['left60','middle','right60'],['middle','left180','upper','right180','right120','right0','right60']]
        elif n==4:
            segments=[(0,700,0),(700,920,-70),(920,2680,-140),(2680,2900,-70),(2900,3600,0)]
            l['platforms']=[platform('bridge_left',780,0,900,art='bridge_plank'),platform('bridge_right',1920,0,900,art='bridge_plank'),platform('gap_step',1680,-70,240),platform('bottom_left_step',780,-70),platform('bottom_right_step',2660,-70)]
            chains=[['bottom_left_step','bridge_left','gap_step','bridge_right','bottom_right_step']]
            l['backgrounds'].insert(0,dict(name='FarAbyss',path='res://assets/backgrounds/passage/far_abyss_tile.webp',position=[0,0],size=[2048,960],ratio=.3,z=-30,repeat_size=[2048,0],repeat_times=4))
        elif n==5:
            segments=[(0,600,0),(600,3000,-60),(3000,3600,0)]
            ps=[('p0',740,30),('p1',1000,120),('p2',1260,210),('p3',1520,240),('p4',1780,210),('p5',2040,120),('p6',2300,30),('p7',2560,120),('p8',2820,60)]
            l['platforms']=[platform(name,x,e,180) for name,x,e in ps]
            chains=[['p0','p1','p2','p3','p4','p5','p6'],['p6','p7','p8']]
            for name,x,e in ps:prop(l,'passage_gear_pillar',x,620-e,180,500,-3)
        elif n==6:
            segments=[(0,1700,0),(1700,1950,100),(1950,3600,0)]
            l['platforms']=[platform('alcove_left',700,100,300),platform('alcove_right',2450,100,300)]
        elif n==7:
            l['ceilings']=[dict(rect=[1450,380,1200,140],art='res://assets/tiles/passage/low_tunnel_ceiling.webp',clearance=100)]
            l['platforms']=[platform('balcony_low',700,90),platform('balcony_high',900,180,300),platform('balcony_exit',1200,90)]
            chains=[['balcony_low','balcony_high','balcony_exit']]
        elif n==8:
            segments=[(0,750,0),(750,1050,90),(1050,1350,180),(1350,1650,90),(1650,3600,0)]
            l['platforms']=[platform('wall_l90',1680,90),platform('wall_l180',1510,180),platform('wall_l270',1680,270),platform('wall_r90',2410,90),platform('wall_r180',2580,180),platform('wall_r270',2410,270)]
            chains=[['wall_l90','wall_l180','wall_l270'],['wall_r90','wall_r180','wall_r270']]
        l['terrain']=terrain(segments,620,'passage');l['reachability']['chains']=chains
        placements={
          1:{'melee_beast':[(3100,None),(1900,None)],'ranged_beast':[(2800,510),(700,None)],'explosive_spitter':[(2200,None),(900,None)],'wall_diver':[(2000,140),(1100,390)]},
          2:{'ranged_beast':[(1550,None),(2100,None)],'explosive_spitter':[(2900,None),(780,None)],'wall_diver':[(2850,130),(1850,100),(680,360)],'root_spewer':[(1400,420),(2220,420)]},
          3:{'explosive_spitter':[(2800,380),(1500,500)],'wall_diver':[(2900,120),(1800,160),(650,350)],'root_spewer':[(1400,500),(2300,500)],'boar_charger':[(1700,None)]},
          4:{'wall_diver':[(2800,130),(1800,160),(850,140)],'root_spewer':[(980,620),(2440,620)],'boar_charger':[(1220,620)],'gas_sac':[(1600,690),(2400,690)]},
          5:{'root_spewer':[(1080,500),(1600,380),(2120,500)],'boar_charger':[(1800,None)],'gas_sac':[(1400,560),(2400,540)],'wraith_ray':[(2800,400),(1100,430)]},
          6:{'boar_charger':[(3100,None),(1100,None)],'gas_sac':[(2600,520),(800,500)],'wraith_ray':[(2200,450),(600,440)],'shell_scorpion':[(3200,None),(1300,None)]},
          7:{'gas_sac':[(2850,500),(2100,565)],'wraith_ray':[(2800,430),(1300,540)],'shell_scorpion':[(3000,None),(900,None)],'corpse_bomber':[(2000,None),(1200,None),(500,None)]},
          8:{'wraith_ray':[(3000,440),(1500,340),(600,420)],'shell_scorpion':[(3200,None),(900,None)],'corpse_bomber':[(2600,None),(1100,None),(480,None)],'chain_beastman':[(1900,None)]}}
        for kind,points in placements[n].items():
            for index,(x,y) in enumerate(points):
                extra={}
                if kind=='wall_diver':
                    extra['perch_kind']='wall' if index==len(points)-1 and n<=3 else 'ceiling'
                    l['perches'].append(dict(name='Perch_'+str(x),position=[x,y],kind=extra['perch_kind']))
                patrol=3600 if kind=='wraith_ray' else 350 if kind=='chain_beastman' else 420 if kind=='boar_charger' else 150
                enemy(l,kind,x,y,patrol,**extra)
        for x in [550,1200,2750]:prop(l,'passage_pillar_a' if n%2 else 'passage_pillar_b',x,0,220,620)
        prop(l,'passage_chandelier',1700,40,280,360)
        if n in [5,6]:prop(l,'passage_pipe_cluster',2800,100,420,300)
        levels[id]=l
    home=dict(id='HomeRoad',scene='res://scenes/HomeRoad.tscn',width=10800,floor_y=880,bgm='uruk_home_road',display_name='니므롯의 집 가는 길',bg_dim=[.88,.88,.92],ceiling=False,camera_limits=[0,0,10800,1240],safe_zones=[[0,-200,900,1800]],spawns={'Spawn_FromPassage':[10400,880],'Spawn_Debug':[5000,720]},doors=[door('passage_exit',10400,880,'DowntownPassage_F1','Spawn_FromBelow','Spawn_FromPassage','downtown_passage_door_anim',-1),door('nimrod_home_gate',400,880,'','','','nimrod_home_gate',1,locked=True,locked_message='아직 들어갈 수 없다')],npcs=[],enemies=[],decorations=[],steps=[],platforms=[],obstacles=[],floor_art='res://assets/tiles/homeroad/ground_tile.webp',floor_art_size=[512,200],backgrounds=[],reachability=dict(max_rise=110,max_gap=200,max_local_platform_elevation=440,chains=[],floor_reference=880,elevation_limits=[-120,440],required_ground_route=[0,10800],door_distance=10000))
    for name,file,w,ratio,z in [('Sky','sky',1792,.05,-40),('FarCity','far_tile',2048,.2,-30),('MidDistrict','mid_district_tile',2048,.45,-20)]:home['backgrounds'].append(dict(name=name,path='res://assets/backgrounds/homeroad/'+file+'.png',position=[0,0],size=[w,720],ratio=ratio,z=z,**(dict(repeat_size=[2048,0],repeat_times=6) if ratio>.05 else {})))
    home['backgrounds'] += [dict(name='HomeExterior',path='res://assets/props/nimrod_home_exterior.webp',position=[0,160],size=[1300,720],ratio=1,z=-10),dict(name='PassageExterior',path='res://assets/backgrounds/castle_front/downtown_passage_facade.webp',position=[9700,160],size=[1100,720],ratio=1,z=-10)]
    seg=[(0,1500,0),(1500,1800,0),(1800,2100,40),(2100,2400,80),(2400,2700,40),(2700,4000,0),(4000,4250,0),(4250,4500,80),(4500,4750,160),(4750,4900,240),(4900,5150,160),(5150,5400,80),(5400,6900,0),(6900,7100,-50),(7100,8100,-100),(8100,8300,-50),(8300,10800,0)]
    home['terrain']=terrain(seg,880,'homeroad')
    def hp(name,x,e,w=180,art='balcony_platform'):home['platforms'].append(platform(name,x,e,w,'homeroad',art,880))
    for name,x,e,w in [('balcony_left',8500,100,180),('balcony',8800,190,600),('balcony_right',9400,100,180),('canal_left_step',7000,-30,180),('slab1',7180,40,260),('slab2',7500,40,260),('slab3',7820,40,260),('canal_right_step',8080,-30,180),('market_left',6010,60,180),('market_roof',6190,120,260),('market_right',6450,60,180),('overpass_left',2800,75,180),('overpass1',2980,150,360),('overpass2',3440,150,360),('overpass3',3800,150,180),('overpass_right',3980,75,180)]:hp(name,x,e,w,'stone_slab_bridge' if name.startswith('slab') or name.startswith('overpass') else 'balcony_platform')
    home['reachability']['chains']=[['balcony_left','balcony','balcony_right'],['canal_left_step','slab1','slab2','slab3','canal_right_step'],['market_left','market_roof','market_right'],['overpass_left','overpass1','overpass2','overpass3','overpass_right']]
    for x,height in [(5800,60),(6150,80),(6600,60)]:home['obstacles'].append(dict(rect=[x,880-height,160,height],art='res://assets/props/market_stall_a.webp'))
    for x in [9900,8800,8500,7800,7200,6600,6100,5700,4600,3600,3000,2300,1800,1300]:enemy(home,'melee_beast',x,patrol=150)
    for x,y in [(9000,690),(7500,840),(6300,760),(4900,None),(4400,None),(3800,730),(3100,730),(2000,None)]:enemy(home,'ranged_beast',x,y,150)
    for name,x,y,w,h in [('house_ruin_a',8500,500,500,380),('house_ruin_b',9160,580,420,300),('broken_overpass',2870,730,1100,260),('canal_wall_left',6840,780,300,260),('canal_wall_right',8060,780,300,260),('market_stall_a',5650,710,260,170),('market_stall_b',6500,710,260,170),('garden_fence',1150,740,600,140),('lamp_post_ruined',9780,620,100,260),('shrub',2080,820,220,140)]:prop(home,name,x,y,w,h)
    home['regions']=[dict(id=i,span=[a,b],label=label) for i,a,b,label in [(1,9700,10800,'통로 앞 평지'),(2,8300,9700,'허물어진 주거지'),(3,6900,8300,'마른 수로'),(4,5400,6900,'시장 광장'),(5,4000,5400,'급경사 언덕'),(6,2700,4000,'부서진 고가 도로'),(7,1500,2700,'안개 정원'),(8,0,1500,'니므롯의 집')]]
    levels['HomeRoad']=home
    registry['levels']=list(levels.values());save('data/levels.json',registry)
    for id in [*(f'DowntownPassage_F{i}' for i in range(1,9)),'HomeRoad']:(ROOT/'scenes'/f'{id}.tscn').write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/level_base.gd" id="1"]\n\n[node name="'+id+'" type="Node2D"]\nscript = ExtResource("1")\nlevel_id = "'+id+'"\n')
    interaction=json.loads((ROOT/'data/interactions.json').read_text())
    for id,size in [('passage_door',[256,384]),('downtown_passage_door_anim',[320,460]),('nimrod_home_gate',[320,420])]:interaction['door_art'][id]=dict(frame_size=size,frames=6)
    save('data/interactions.json',interaction)
    print('Stage5: passage floors1-8 and HomeRoad authored; total',len(levels),'levels.')

if __name__=='__main__':main()
