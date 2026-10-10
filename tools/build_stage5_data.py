#!/usr/bin/env python3
"""Stage-five numerical specification; image requests are packed separately."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def save(path,obj):
    (ROOT/path).parent.mkdir(parents=True,exist_ok=True)
    (ROOT/path).write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n')

def clips(text):
    return [dict(name=p[0],frames=int(p[1]),duration=float(p[2]),loop=len(p)>3 and p[3]=='L') for p in [part.split() for part in text.split(';')]]

SPECS=[
('explosive_spitter','폭발 투사체 괴수','thick orange-brown toad with swollen throat sac',76,7,.30,80,650,[110,86],[640,640],[320,600], 'idle 6 .9 L;walk 8 .9 L;windup 4 .6;spit 3 .2;recovery 4 .5;turn 4 .3;hurt 2 .2;death 6 .7'),
('wall_diver','벽면 강하 괴수','bat-centipede hybrid, black-purple hide, many hooked legs and leathery wings',36,8,.25,230,600,[90,60],[640,640],[320,320], 'perch_ceiling 4 .8 L;perch_wall 4 .8 L;tell 3 .2;dive 3 .25 L;claw 4 .2;recovery 4 .5;crawl 8 .7 L;turn 4 .25;hurt 2 .2;death 6 .6'),
('root_spewer','뿌리 화염 괴수','plant-root and esophagus hybrid, green-brown bark, fleshy vertical throat',55,1,.25,0,540,[74,80],[640,640],[320,600], 'idle 6 1.2 L;windup 4 .5;spew 4 .4 L;recovery 4 .6;turn 4 .25;hurt 2 .2;death 6 .7'),
('boar_charger','돌진 괴수','boar and armored woodlouse hybrid, protruding bone shell, dark gray, red eyes',110,15,.45,120,700,[155,94],[768,640],[384,600], 'idle 6 1 L;walk 8 .9 L;telegraph 4 .5;charge 4 .3 L;crash_stun 4 .8;recovery 4 .6;turn 4 .45;hurt 2 .2;death 6 .8'),
('gas_sac','독가스 주머니 괴수','swollen jellyfish-pufferfish hybrid, yellow-green translucent sac, tentacles',40,6,.30,70,700,[88,90],[640,640],[320,320], 'float 6 .9 L;bump 3 .2;turn 4 .3;hurt 2 .2;death_swell 6 1;burst 5 .3'),
('wraith_ray','추적 환령','indistinct smoke-shaped manta ray, pale blue-gray vapor, ominous silhouette',18,5,.25,90,2000,[98,48],[640,640],[320,320], 'glide 8 1 L;turn 4 .25;hurt 2 .2;death 6 .6'),
('shell_scorpion','방어 갑피 괴수','turtle shell and scorpion claws hybrid, dark brown armored carapace and barbed tail',75,12,.50,70,450,[134,80],[640,640],[320,600], 'idle 6 1 L;walk 8 1.1 L;guard_block 3 .2;claw_windup 4 .5;claw_attack 3 .15;claw_recovery 4 .7;tail_windup 3 .3;tail_strike 3 .15;tail_recovery 4 .6;turn 6 .6;hurt 2 .2;death 6 .8'),
('corpse_bomber','자폭 시체','grotesquely bloated zombie, black-red swollen flesh, tattered clothing',30,18,.30,340,520,[62,88],[640,640],[320,600], 'idle 6 1 L;scream 4 .4;run 8 .6 L;fuse 6 .5 L;explode 6 .3;turn 4 .3;hurt 2 .2'),
('chain_beastman','사슬 꼬리 수인','large hulking beastman with articulated heavy chain tail, black iron hide and fur',160,10,.80,90,700,[180,178],[896,768],[448,720], 'idle 6 1.2 L;walk 8 1.2 L;tail_windup 5 .6;tail_sweep 4 .2;tail_recovery 5 .8;chain_windup 4 .4;chain_throw 4 .35;pull_hold 3 .35 L;smash_windup 4 .35;smash 3 .15;smash_recovery 5 .9;turn 6 .8;hurt 2 .2;death 8 1')]

def box(w,h,offset=10,top=None):return dict(width=w,height=h,offset_x=offset,top=-h if top is None else top)
def attack(id,damage,windup,active,recovery,range,cooldown=0,hitbox=None,**extra):return dict(id=id,damage=damage,windup=windup,active=active,recovery=recovery,range=range,cooldown=cooldown,hitbox=hitbox or box(100,80),**extra)

def main():
    data=json.loads((ROOT/'data/enemies.json').read_text());byid={e['id']:e for e in data['enemies']}
    for id,name,appearance,hp,damage,turn,speed,detect,body,frame,anchor,seq in SPECS:
        byid[id]=dict(id=id,display_name=name,appearance=appearance,hp=hp,contact_damage=damage,turn_delay=turn,move_speed=speed,detect_range=detect,body_size=body,body_offset_y=0 if anchor[1]==320 else -body[1]/2,visual_scale=.30,frame_size=frame,anchor=anchor,clips=clips(seq),hurt_sfx=id+'_hurt',death_sfx=id+'_death',drop_id='healing_vomit',drop_chance=.07 if id=='explosive_spitter' else .05,knockback_multiplier=.5 if id=='chain_beastman' else 1)
    byid['explosive_spitter'].update(preferred_distance=[380,520],retreat_distance=300,projectile=dict(speed=480,direct_damage=7,direct_stagger=.3,fuse=.3,radius=90,explosion_damage=14,knockback=220,collision_radius=12),attacks=[attack('spit',7,.6,.2,.5,650,2)])
    byid['wall_diver'].update(sensor_ceiling=[160,400],sensor_wall=[220,120],dive_speed=720,dive_seconds=.6,tell_seconds=.2,landing_recovery=.5,attacks=[attack('claw',8,.35,.12,.6,105,0,box(100,80,10,-45))])
    byid['root_spewer'].update(sensor=[360,400],attacks=[attack('spew',1,.5,1,.6,400,1.8,box(100,320,-50,-320),tick_count=10,tick_interval=.1,first_stagger=.18,interrupt_stun=.4)])
    byid['boar_charger'].update(charge_speed=640,charge_distance=800,crash_stun=.8,contact_knockback=260,attacks=[attack('charge',15,.5,1.25,.6,700,1.5,box(170,95,0,-95))])
    byid['gas_sac'].update(contact_interval=.8,death_swell_seconds=1,gas=dict(seconds=2,radius=110,height=160,tick_interval=.2,damage=1),attacks=[])
    byid['wraith_ray'].update(contact_interval=1,attacks=[])
    byid['shell_scorpion'].update(back_turn_delay=.6,back_range=220,tail_chance=.35,attacks=[attack('claw',12,.5,.15,.7,145,0,box(120,70,10,-70)),attack('tail',10,.3,.15,.6,220,0,box(110,60,10,-60))])
    byid['corpse_bomber'].update(fuse_seconds=1.5,scream_seconds=.4,explosion=dict(radius=110,damage=18,knockback=260),attacks=[])
    byid['chain_beastman'].update(chain=dict(range=520,throw_seconds=.35,pull_seconds=.35,pull_offset=90,escape_after=.15,miss_recovery=.7),attacks=[attack('tail',10,.6,.2,.8,220,0,box(240,90,0,-125)),attack('chain',16,.4,.35,.9,520,4,box(120,120,0,-120),smash_windup=.35,smash_active=.15)])
    data['enemies']=list(byid.values());data['common'].update(overlap_tick_seconds=.2,guard_spark_scale=.35,guard_spark_seconds=.18,chain_height_offset=-90,floating_floor_margin=50,ledge_probe_x=32,ledge_probe_down=100,corpse_beep_min=.06,corpse_beep_factor=.3,corpse_blink_start=12,corpse_blink_acceleration=20,gas_blink_rate=30)
    save('data/enemies.json',data)
    attacks=json.loads((ROOT/'data/player_attacks.json').read_text());attacks.update(direction_cancel=dict(enabled=True,keep_combo=True,buffer_during_hitstop=.12,air_limit=2,guard_recoil_pixels=50),pull=dict(escape_after=.15),movement=dict(crouch_speed=120));save('data/player_attacks.json',attacks)
    fx=[('spit_projectile',128,128,4,.4,True),('explosion',256,256,6,.35,False),('gas_cloud',256,256,6,.6,True),('guard_spark',192,192,5,.18,False),('chain_segment',64,24,1,1,True),('chain_hook',96,96,1,1,True)]
    save('data/stage5_fx.json',{'fx':[dict(name=n,path='res://assets/sprites/fx/'+n+'.png',frame_size=[w,h],frames=f,duration=d,loop=l) for n,w,h,f,d,l in fx]})
    ordered=['melee_beast','ranged_beast']+[s[0] for s in SPECS]
    save('data/passage_floors.json',{'interpretation':'ordered roster, sliding window of four; higher floors replace first with one new type','ordered_roster':ordered,'floors':[dict(floor=n,enemy_ids=ordered[n-1:n+3]) for n in range(1,9)]})
    audio={'sfx':[],'bgm':[]}
    for i,e in enumerate(SPECS):
        for j,(suffix,kind,dur) in enumerate([('windup','growl',.5),('attack','whoosh',.25),('hurt','hurt',.22),('death','death',.55)]):audio['sfx'].append(dict(name=e[0]+'_'+suffix,kind=kind,duration=dur,pitch=75+i*12+j*7,seed=55000+i*4+j))
    extra=[('spit_launch','whoosh',.2),('explosion_boom','impact',.4),('gas_burst','flame_start',.3),('gas_loop','flame_loop',.5),('chain_launch','rattle',.35),('chain_pull','rattle',.35),('guard_block','rattle',.16),('corpse_scream','screech',.4),('corpse_fuse_beep','screech',.06),('boar_charge_rumble','growl',.8),('wraith_wail_loop','flame_loop',.5),('wall_diver_screech','screech',.2)]
    for i,(name,kind,dur) in enumerate(extra):audio['sfx'].append(dict(name=name,kind=kind,duration=dur,pitch=100+i*17,seed=56000+i,loop=name.endswith('_loop'),volume_db=-14 if name=='wraith_wail_loop' else 0))
    for i,(name,freq) in enumerate([('passage_descent',[30,45,60,90]),('uruk_home_road',[43,64.5,86,129])]):audio['bgm'].append(dict(name=name,duration=48,frequencies=freq,gains=[.24,.12,.08,.035],string_harmonics=2,pulse_cycles=3,wind_gain=.02,wind_band=[70,1200],chime_every=8,chime_gain=.014,seed=57000+i,metal_percussion=dict(interval=6,gain=.025,frequencies=[140,271,423],decay=.7)))
    save('data/audio_stage5.json',audio)
    print('Stage5: nine numerical enemy specifications, direction cancel, FX, roster and audio saved.')

if __name__=='__main__':main()
