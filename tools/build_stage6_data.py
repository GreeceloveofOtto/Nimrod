#!/usr/bin/env python3
"""Idempotent Stage6 registry extension; art comes exclusively from image generation."""
import json,copy
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def read(p):return json.loads((R/p).read_text())
def save(p,d):(R/p).parent.mkdir(parents=True,exist_ok=True);(R/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def clips(s):
 out=[]
 for term in s.split(';'):
  n,f,t,*loop=term.split();out.append(dict(name=n,frames=int(f),duration=float(t),loop=bool(loop)))
 return out
SPECS={
'cedar_sentinel':dict(display_name='삼나무 해골 파수꾼',appearance='weathered cedar skeleton soldier entangled with roots and vines, rusted dagger, wooden shield',hp=85,contact_damage=12,turn_delay=.3,move_speed=130,detect_range=700,body_size=[140,250],visual_scale=.45,frame_size=[768,768],anchor=[384,720],clips=clips('idle 6 1 loop;walk 8 .9 loop;windup 4 .4;thrust 3 .2;slash 3 .2;attack_recovery 4 .7;shield_up 3 .2;shield_hold 2 .2 loop;shield_break_stun 4 1;turn 4 .3;hurt 2 .2;death 6 .8'),shield=dict(chance=.5,damage_multiplier=.4,hold=.6,break_stun=1,broken_seconds=3),aliases={'attack':'thrust','recovery':'attack_recovery'}),
'cedar_colossus':dict(display_name='삼나무 대형 무두 해골',appearance='4 meter giant fused skeleton of many skeletons, huge cedar-root club',hp=165,contact_damage=22,turn_delay=.6,move_speed=90,detect_range=800,body_size=[300,440],visual_scale=.5,frame_size=[1024,1024],anchor=[512,980],clips=clips('idle 6 1.4 loop;walk 8 1.4 loop;slam_windup 6 1;slam 3 .2;slam_recovery 5 1.2;sweep_windup 5 .7;sweep 3 .2;sweep_recovery 5 .9;rear_poke 4 .4;turn 6 .6;hurt 2 .2;death 8 1.2'),rear_chance=.4,shockwave=dict(width=800,height=40,seconds=.5,knockback=220),aliases={'windup':'slam_windup','attack':'slam','recovery':'slam_recovery'}),
'cedar_archer':dict(display_name='석궁 해골 사수',appearance='skeleton with heavy bone crossbow, dark crimson glow in ribcage',hp=58,contact_damage=14,turn_delay=.2,move_speed=100,detect_range=900,body_size=[150,260],visual_scale=.45,frame_size=[768,768],anchor=[384,720],clips=clips('idle 6 1 loop;walk 8 .9 loop;windup 4 .5;shoot 3 .2;recovery 4 .4;hop_back 5 .4;turn 4 .2;hurt 2 .2;death 6 .7'),preferred_distance=[500,800],arrow=dict(speed=900,damage=14,range=1300),hop=dict(range=260,distance=220,seconds=.4,height=80,cooldown=3,spike_damage=10,spike_seconds=.6),aliases={'attack':'shoot'}),
'cedar_wisp':dict(display_name='저주받은 유골 부유령',appearance='legless floating spine and skull ghost with blue flammable flame',hp=32,contact_damage=9,turn_delay=.15,move_speed=80,detect_range=1100,body_size=[120,170],body_offset_y=0,visual_scale=.45,frame_size=[768,768],anchor=[384,384],clips=clips('float 6 1 loop;contact 3 .2;fuse 5 .5;explode 6 .3;turn 4 .15;hurt 2 .2'),fuse_seconds=.5,explosion=dict(radius=200,damage=15,seconds=.3),aliases={'idle':'float','walk':'float','windup':'fuse','attack':'contact','recovery':'float','death':'explode'}),
'cedar_demon':dict(display_name='삼나무 통곡의 해골 마귀',appearance='skeleton fiend with four arms hanging from cedar branches',hp=90,contact_damage=18,turn_delay=.25,move_speed=150,detect_range=700,body_size=[220,280],visual_scale=.45,frame_size=[768,768],anchor=[384,720],clips=clips('perch 4 1 loop;tell 3 .2;fall 3 .25 loop;land_stab 4 .3;claw_windup 4 .25;claws 6 .6;recovery 4 .8;idle 6 1 loop;walk 8 .8 loop;turn 4 .25;hurt 2 .2;death 6 .7'),perch_sensor=[160,700],fall_speed=900,claw_damage=[3,3,2,2],claw_interval=.15,aliases={'windup':'claw_windup','attack':'claws'}),
}
def atk(id,damage,windup,active,recovery,size,top=None,cooldown=0,range=None,**extra):
 return dict(id=id,damage=damage,windup=windup,active=active,recovery=recovery,cooldown=cooldown,range=range or size[0],hitbox=dict(width=size[0],height=size[1],offset_x=0,top=top if top is not None else -size[1]),**extra)
SPECS['cedar_sentinel']['attacks']=[atk('thrust',12,.4,.2,.7,[150,80],-120,range=170,forward_distance=90,combo_delay=.3),atk('slash',12,.3,.2,.7,[170,90],-130)]
SPECS['cedar_colossus']['attacks']=[atk('slam',22,1,.2,1.2,[260,200],cooldown=1),atk('sweep',16,.7,.2,.9,[360,140],cooldown=1),atk('rear_poke',8,.25,.15,.3,[160,120],cooldown=1)]
SPECS['cedar_archer']['attacks']=[atk('shoot',14,.5,.2,.4,[1,1],cooldown=1.8,range=800)]
SPECS['cedar_wisp']['attacks']=[]
SPECS['cedar_demon']['attacks']=[atk('claws',3,.25,.6,.8,[170,100],-130,cooldown=1.5),atk('land_stab',18,.2,.3,0,[120,160])]
BOSS_CLIPS=clips('idle 8 1.6 loop;walk 8 1.4 loop;whip_windup 5 .8;whip_swing 4 .25;whip_swing_back 4 .25;whip_recovery 5 1;slam_windup 5 .9;slam 3 .15;slam_recovery 5 1.2;summon 6 1.8;turn 6 .7;phase_transition 8 2;roar_windup 5 .8;roar_loop 4 .4 loop;roar_recovery 5 1.3;spines_back 4 .45;collapse 6 1;final_swing_windup 5 .8;final_swing 4 .2;death 8 1.5')
P2=['idle','walk','turn','whip_windup','whip_swing','whip_swing_back','whip_recovery','slam_windup','slam','slam_recovery']
BOSS_CLIPS += [dict(c,name=c['name']+'_p2') for c in BOSS_CLIPS if c['name'] in P2]
SPECS['kala_ushumgal']=dict(display_name='칼라-우쉬움갈',appearance='6 meter deformed skeleton giant built from thousands of skulls, crimson pulsing chest core, spinal bone whip right arm, decapitation blade growing from left shoulder',hp=1200,contact_damage=16,turn_delay=.7,move_speed=80,detect_range=1100,body_size=[520,560],visual_scale=.5,frame_size=[1536,1280],anchor=[768,1200],knockback_multiplier=.2,drop_chance=0,clips=BOSS_CLIPS,armor=dict(multiplier=.7,upper_ratio=.5),phase_two=dict(hp=600,transition_seconds=2,time_multiplier=1/1.2,turn_delay=.5),start_x=450,pattern_range=700,summon=dict(thresholds=[.75,.55],windup=1,recovery=.8,max_count=2,cooldown=20,positions=[[180,500],[1420,500]]),spikes=dict(distances=[260,460,660],delay=.3,interval=.12,seconds=.4,size=[90,200],damage=14),rear=dict(hits=2,window=2.5,cooldown=6),roar=dict(range=700,angle=60,ticks=14,interval=1.5/14,damage=2,origin_y=-360),death_sequence=dict(collapse=1,windup=.8,active=.2,fade=1.5,damage=30),death_lines=['억울하구나, 억울해. 애초에 이곳을 개척했던 것이 잘못이었지.','나에게 운명을 바꿀 힘이 있었다면, 그랬다면!!','헛되이 죽은 병사들 모두가 가족들과 행복한 삶을 살았을 것이다.','나는 비록 잠깐 사라지나, 기필코 다시 나타날 것이다.','본향의 형제들이 울부짖던 소리가 가슴을 찢는구나.'],attacks=[atk('whip',16,.8,.25,1,[560,180],-220,second_windup=.5),atk('slam',22,.9,.15,1.2,[240,160]),atk('summon',0,1,0,.8,[0,0]),atk('roar',2,.8,1.5,1.3,[700,404],-560),atk('spines',12,.3,.15,.3,[380,120],-160),atk('final',30,.8,.2,1.5,[640,220],-260)],aliases={'windup':'whip_windup','attack':'whip_swing','recovery':'whip_recovery','hurt':'idle'})
FX=[('bone_spike',[128,256],4,.4,False),('soul_flame_cone',[768,384],6,.6,True),('bone_arrow',[96,24],1,1,False),('bone_spike_ground',[128,128],3,.6,False),('blue_flame_explosion',[256,256],6,.3,False),('armor_hit_spark',[192,192],5,.15,False)]
def data():
 e=read('data/enemies.json');by={x['id']:x for x in e['enemies']}
 for id,entry in SPECS.items():
  item=copy.deepcopy(entry);item['id']=id;item.setdefault('knockback_multiplier',1);item.setdefault('drop_chance',.05);item.update(drop_id='healing_vomit',hurt_sfx=id+'_hurt',death_sfx=id+'_death');by[id]=item
 e['enemies']=list(by.values());save('data/enemies.json',e)
 n=read('data/npcs.json');ns={x['id']:x for x in n['npcs']};ns['enkidua']=dict(id='enkidua',display_name='엔키두아',height_ratio=1.04,sheet_dir='assets/sprites/npcs/enkidua',visual_scale_multiplier=1,three_way=True,face_player=True,initial_pose='front',interactable=False,clips=clips('idle 6 2.4 loop;idle_front 6 2.4 loop'));n['npcs']=list(ns.values());save('data/npcs.json',n)
 save('data/stage6_fx.json',{'fx':[dict(name=n,path='res://assets/sprites/fx/'+n+'.png',frame_size=s,frames=f,duration=d,loop=l) for n,s,f,d,l in FX]})
def door(id,x,y,art,target='',spawn='',arrival='',**k):return dict(door_id=id,position=[x,y],door_art='res://assets/props/doors/'+art+'.png',target_level=target,target_spawn=spawn,arrival_spawn=arrival,**dict({"exit_direction":1},**k))
def plat(id,x,y,w,art='root_platform'):return dict(id=id,position=[x,y],width=w,art='res://assets/tiles/cedar/'+art+'.png',art_height=48)
def prop(path,x,y,w,h,z=0,ground=True):return dict(path='res://assets/'+path+'.png',position=[x,y],size=[w,h],z=z,ground_contact=ground)
def enemy(id,x,y,r=250,**k):return dict(id=id,position=[x,y],patrol_center=x,patrol_range=r,**k)
def level(id,width,fy,display,bgm,art,height=None):return dict(id=id,scene='res://scenes/'+id+'.tscn',width=width,floor_y=fy,bgm=bgm,display_name=display,camera_limits=[0,0,width,height or fy+180],safe_zones=[],bg_dim=[.88,.88,.92] if fy>620 else [.8,.8,.84],ceiling=fy==620,floor_art='res://assets/'+art+'.png',floor_art_size=[512,180],spawns={},doors=[],npcs=[],enemies=[],backgrounds=[],decorations=[],platforms=[],steps=[],obstacles=[])
def bg(name,path,w,h,y=0,**k):return dict(name=name,path='res://assets/'+path+'.png',position=[0,y],size=[w,h],ratio=1,z=-10,**k)
PATH=[(0,4),(1,4),(2,4),(3,4),(3,3),(2,3),(1,3),(1,2),(2,2),(3,2),(3,1),(2,1),(1,1),(1,0),(2,0),(3,0)]
def maze(n):
 id=f'CedarForest_F{n}';cols,rows=4,5;cw,ch=1200,640;offset=128;width=cols*cw;fy=offset+rows*ch
 l=level(id,width,fy,f'삼나무 숲 {n}층','cedar_forest','tiles/cedar/root_floor_tile',fy+72);l['ceiling']=False
 l['backgrounds']=[bg('CedarFar','backgrounds/cedar/far_tile_2d',1024,1024,ratio_y=.1,repeat_size=[1024,1024],repeat_times=8),bg('CedarMid','backgrounds/cedar/mid_trunks_tile_2d',1024,1024,ratio_y=.35,repeat_size=[1024,1024],repeat_times=8)];l['backgrounds'][0]['ratio']=.1;l['backgrounds'][1]['ratio']=.35
 edges=[(a,b) for a,b in zip(PATH,PATH[1:])]+[((1,r),(0,r)) for r in range(4)]
 cells=[dict(id=f'{c}_{r}',column=c,row=r,rect=[c*cw,offset+r*ch,cw,ch]) for r in range(rows) for c in range(cols)]
 # One-way room floors provide intentional S+Space routes. Trunk walls have
 # openings only at graph connections; 500px clear openings fit the colossus.
 for r in range(rows):
  floor=offset+(r+1)*ch
  if r<rows-1:
   for c in range(cols):l['platforms'].append(plat(f'room_{c}_{r}',c*cw+40,floor,cw-80,'branch_platform'))
  for c in range(1,cols):
   connected=((c-1,r),(c,r)) in edges or ((c,r),(c-1,r)) in edges
   h=140 if connected else ch
   l['obstacles'].append(dict(rect=[c*cw-40,offset+r*ch,80,h],art='res://assets/tiles/cedar/wall_trunk_tile.png',role='wall'))
 chains=[]
 for a,b in edges:
  if a[0]==b[0]:
   c=a[0];lower=max(a[1],b[1]);floor=offset+(lower+1)*ch;chain=[]
   for i in range(1,9):
    pid=f'stair_{c}_{lower}_{i}';l['platforms'].append(plat(pid,c*cw+460+(i%2)*120,floor-i*80,320,'branch_platform'));chain.append(pid)
   chains.append(chain)
 l['terrain']=[dict(id='base',**{'from':0,'to':width,'y':fy})]
 l['spawns']={'Spawn_FromVilla' if n==1 else 'Spawn_FromBelow':[300,fy],'Spawn_FromAbove':[width-360,offset+ch]}
 l['doors']=[door('forest_entrance',220,fy,'cedar_portal','VillaBackyard' if n==1 else 'CedarForest_F1','Spawn_FromForest' if n==1 else 'Spawn_FromAbove','Spawn_FromVilla' if n==1 else 'Spawn_FromBelow',exit_direction=-1),door('forest_exit',width-220,offset+ch,'cedar_portal','CedarForest_F2' if n==1 else 'CedarBossRoom','Spawn_FromBelow' if n==1 else 'Spawn_FromForest','Spawn_FromAbove')]
 # Active monsters patrol the central, clear part of their own rooms.
 positions=[((c+.5)*cw,offset+(r+1)*ch) for c,r in PATH[1:-1]]
 ids=['cedar_sentinel']*7+['cedar_colossus']*3 if n==1 else ['cedar_archer']*5+['cedar_wisp']*5+['cedar_demon']*4
 for i,eid in enumerate(ids):
  x,y=positions[i%len(positions)];y-=240 if eid=='cedar_wisp' else (380 if eid=='cedar_demon' else 0)
  l['enemies'].append(enemy(eid,x,y,300,room_bounds=[x-cw*.5+80,offset+(int((y-offset)//ch))*ch,x+cw*.5-80,offset+(int((y-offset)//ch)+1)*ch]))
  if eid=='cedar_demon':l.setdefault('perches',[]).append(dict(name='Perch_'+str(i),position=[x,y],kind='branch'))
 l['drop_rule']={'mode':'all','chance':.05}
 l['pickups']=[dict(id='healing_vomit',position=[260,offset+(r+1)*ch]) for r in [0,2]]
 layout=dict(level_id=id,columns=cols,rows=rows,cell_width=cw,cell_height=ch,cells=cells,correct_path=[f'{c}_{r}' for c,r in PATH],connections=[[f'{a[0]}_{a[1]}',f'{b[0]}_{b[1]}'] for a,b in edges],entrance='0_4',exit='3_0',dead_ends=[f'0_{r}' for r in range(4)],branches=4,platform_chains=chains,max_rise=110,max_gap=200)
 l['maze_layout']=id
 return l,layout

def levels():
 d=read('data/levels.json');ls={l['id']:l for l in d['levels']}
 for id in SPECS:d['world']['enemy_scripts'][id]='res://scripts/enemy_'+id+'.gd'
 home=level('NimrodHome',1800,620,'니므롯의 집','nimrod_home','tiles/home/home_floor_tile');home['safe_zones']=[[0,-1000,1800,2500]];home['backgrounds']=[bg('HomeInterior','backgrounds/nimrod_home/home_interior_bg',1800,720)]
 home['spawns']={'Spawn_FromGate':[1560,620]};home['doors']=[door('home_exit',1650,620,'nimrod_home_inner_door','HomeRoad','Spawn_FromHome','Spawn_FromGate',exit_direction=-1)]
 home['npcs']=[dict(id='enkidua',position=[1000,620])];home['decorations']=[prop('props/home_bed',120,420,420,200),prop('props/home_table',1170,440,360,180),prop('props/home_shelf',650,200,300,420),prop('props/home_lamp',530,360,120,260),prop('props/home_rug',700,620,420,60,ground=False)]
 ls[home['id']]=home
 road=ls['HomeRoad'];gate=next(x for x in road['doors'] if x['door_id']=='nimrod_home_gate');gate.update(locked=False,target_level='NimrodHome',target_spawn='Spawn_FromGate',arrival_spawn='Spawn_FromHome',exit_direction=1);road['spawns']['Spawn_FromHome']=[520,road['floor_y']]
 for item in road['decorations']+road['backgrounds']:
  if 'nimrod_home_exterior' in item['path']:item.update(position=[0,233],ground_contact=True)
 v=ls['VillaF1'];back=next(x for x in v['doors'] if x['door_id']=='villa_back_door');back.update(locked=False,target_level='VillaBackyard',target_spawn='Spawn_FromBackDoor',arrival_spawn='Spawn_FromBackyard',exit_direction=-1);v['spawns']['Spawn_FromBackyard']=[1780,620]
 yard=level('VillaBackyard',1500,880,'샤마쉬와 아야의 별장 뒤뜰','villa_calm','tiles/homeroad/plaza_tile');yard['safe_zones']=[[0,-1000,1500,2500]];yard['spawns']={'Spawn_FromBackDoor':[360,880],'Spawn_FromForest':[640,880]};yard['backgrounds']=[bg('Backyard','backgrounds/villa_backyard/backyard_bg',1500,720,160)];yard['doors']=[door('villa_back_exterior',300,880,'villa_back_door_exterior','VillaF1','Spawn_FromBackyard','Spawn_FromBackDoor'),door('cedar_entrance',700,880,'cedar_forest_portal','CedarForest_F1','Spawn_FromVilla','Spawn_FromForest',exit_direction=-1)];yard['decorations']=[prop('props/garden_fence',900,740,600,140),prop('props/lamp_post_ruined',1120,620,100,260),prop('props/shrub',1200,740,220,140)];ls[yard['id']]=yard
 layouts=[]
 for n in [1,2]:l,lay=maze(n);ls[l['id']]=l;layouts.append(lay)
 boss=level('CedarBossRoom',1600,800,'삼나무 숲의 가장 깊은 곳','cedar_boss','tiles/cedar/bone_floor_tile',900);boss['ceiling']=True;boss['backgrounds']=[bg('BoneCavern','backgrounds/cedar/boss_bg',1600,960)];boss['spawns']={'Spawn_FromForest':[250,800]};boss['doors']=[door('boss_arrival',200,800,'cedar_portal','CedarForest_F2','Spawn_FromAbove','Spawn_FromForest')];boss['platforms']=[plat('summon_left',40,500,280,'boss_end_platform'),plat('summon_right',1280,500,280,'boss_end_platform')];boss['enemies']=[enemy('kala_ushumgal',900,800,500)];boss['drop_rule']={'mode':'all','chance':0};ls[boss['id']]=boss
 # Enlarge critical rooms and relocate ground monsters out of low tunnels.
 for n in range(1,9):
  l=ls[f'DowntownPassage_F{n}'];
  if l.get('clearance_revision')=='stage6':continue
  l['clearance_revision']='stage6';l['ceiling']=True;l['camera_limits'][1]=-180 if n==8 else -80;l['camera_limits'][3]=1100 if n==8 else 940
  if n==8:
   l['ceilings']=[]
   # Vertical battle room remains clear above the 534px chain beastman.
   for p in l['platforms']:
    if 1500<p['position'][0]<2400 and p['position'][1]>0:p['position'][1]-=350
   # Optional upper platforms receive a chain reaching from the room floor.
   chain=[]
   for i in range(1,7):
    p=plat('stage6_upper_'+str(i),1420+(i%2)*120,620-i*100,320);p['art']='res://assets/tiles/passage/platform.png';l['platforms'].append(p);chain.append(p['id'])
   l['reachability']['chains'].append(chain);l['reachability']['elevation_limits']=[-180,900];l['reachability']['max_local_platform_elevation']=900
  if n==7:
   # Preserve crouch route while every physical enemy starts in a tall room.
   for e in l['enemies']:
    if e['id']!='wraith_ray':
     oldx=e['position'][0];e['position'][0]=2900 if oldx>=1800 else 800;e['patrol_center']=e['position'][0];e['patrol_range']=130
  for p in l['platforms']:
   p['width']=max(p['width'],300)
  for e in l['enemies']:
   if e['id']=='gas_sac':e['position'][1]-=80
   if e['id']=='boar_charger':
    x=e['position'][0];e['patrol_range']=max(650,e.get('patrol_range',0));l.setdefault('clearance_lanes',[]).append([max(200,x-650),min(3400,x+650)])
  # Remove overhead platforms only where a large body would collide. Retain
  # routes elsewhere and use clear dedicated elevated enemy pads.
  for e in l['enemies']:
   if e['id'] in ['boar_charger','chain_beastman']:
    x,y=e['position'];bodyh=282 if e['id']=='boar_charger' else 534
    l['platforms']=[p for p in l['platforms'] if not (p['position'][0]<x+250 and p['position'][0]+p['width']>x-250 and y-bodyh-12<p['position'][1]<y)]
  valid={p['id'] for p in l['platforms']};l['reachability']['chains']=[[id for id in chain if id in valid] for chain in l['reachability']['chains']]
 # Scene files use a single shared, data-driven level implementation.
 for l in ls.values():
  if l['id'] in ['NimrodHome','VillaBackyard','CedarForest_F1','CedarForest_F2','CedarBossRoom']:
   (R/l['scene'].removeprefix('res://')).write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/level_base.gd" id="1"]\n\n[node name="'+l['id']+'" type="Node2D"]\nscript = ExtResource("1")\nlevel_id = "'+l['id']+'"\n')
 d['levels']=list(ls.values());save('data/levels.json',d);save('data/cedar_forest_layout.json',{'revision':'user-approved 4x5 expansion: 20 rooms, 16-room correct route','layouts':layouts})

def audio():
 s=[]
 for i,id in enumerate(SPECS):
  for j,(kind,duration) in enumerate([('growl',.4),('whoosh',.25),('hurt',.2),('death',.7)]):
   suffix=['windup','attack','hurt','death'][j];s.append(dict(name=id+'_'+suffix,kind=kind,duration=duration,pitch=65+i*21,seed=66000+i*4+j,loop=False,volume_db=-6 if id=='kala_ushumgal' else 0))
 special={'sentinel_shield_up':('rattle',.2),'sentinel_shield_break':('heavy',.35),'colossus_slam':('heavy',.3),'colossus_shockwave':('wave',.5),'archer_shot':('whoosh',.15),'bone_spike_pop':('rattle',.18),'wisp_wail_loop':('flame_loop',.5),'wisp_explode':('heavy',.35),'demon_screech':('screech',.3),'boss_whip_swing':('whoosh',.35),'boss_slam':('heavy',.5),'boss_spike_rise':('rattle',.25),'boss_roar_loop':('flame_loop',.5),'boss_phase_roar':('screech',1.5),'boss_core_throb':('flame_loop',.5),'boss_collapse':('death',1),'boss_final_swing':('whoosh',.4),'armor_hit':('rattle',.15),'speech_blip':('speech',.02),'buff_chime':('chime',.6)}
 for i,(name,(kind,duration)) in enumerate(special.items()):s.append(dict(name=name,kind=kind,duration=duration,pitch=100+i*17,seed=66500+i,loop=name.endswith('_loop') or name=='boss_core_throb',volume_db=-26 if name=='speech_blip' else (-15 if name.endswith('_loop') else 0)))
 b=[]
 base=read('data/audio_stage5.json')['bgm'][0]
 for i,(name,frequencies) in enumerate([('nimrod_home',[55,82.5,110,165]),('cedar_forest',[31,46.5,62,124]),('cedar_boss',[25,37.5,50,75])]):
  entry=copy.deepcopy(base);entry.update(name=name,frequencies=frequencies,seed=67000+i);entry['metal_percussion']['gain']=.005 if i==0 else (.015 if i==1 else .07);b.append(entry)
 save('data/audio_stage6.json',{'sfx':s,'bgm':b})
if __name__=='__main__':data();levels();audio()
