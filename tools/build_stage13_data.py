#!/usr/bin/env python3
"""Stage13 authored narrative and combat tuning. Images are produced separately."""
import json,copy
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def read(n):return json.loads((R/n).read_text())
def write(n,d):(R/n).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def main():
 talk=[('player','그대가 우트나피쉬팀이요? 단도직입적으로 말하겠어, 난 영생을 찾아 오랫동안 여행했지. 그대는 영생을 아는가?'),('utnapishtim','자네의 눈을 보아하니 숨쉬는 존재의 영원한 생명이 아니라, 흙으로 돌아간 자의 부활을 꿈꾸는군.'),('player','그래, 난 죽은 자를 되살리고자 해. 당신이 영원한 생명을 갖고 있다고 해서, 죽음의 바다를 건너 찾아왔어.'),('utnapishtim','나의 영원한 생명은 죽는 것에 실패하는 것과 같지.'),('utnapishtim','나는 지금도 끊임없이 죽기를 반복해. 그러나 사망에 실패할 뿐이야.'),('utnapishtim','미안하지만, 영생에 대해서는 해줄 말이 없네, 부활을 꿈꾼다면 더더욱.')]
 tiamat=[('tiamat','재밌구나, 재밌어. 나에게 오라. 나를 죽여다오.'),('tiamat','니므롯, 이 짧은 시대에 내가 너를 주인공으로 삼았다. 앞으로 더욱 재밌어질 거야. 고통에 신음하지말고, 내가 너에게 준 운명을 즐겨라!')]
 d=read('data/dialogue.json')
 for ident,lines,when,event in [('utnapishtim_talk',talk,{'all':['tiamat_arrived'],'none':['utnapishtim_done']},'utnapishtim_rampage'),('tiamat_talk',tiamat,{'all':['huluppu_boss_done'],'none':['tiamat_talk_done']},'')]:
  spec={'id':ident,'when':when,'first':[{'speaker':s,'text':t} for s,t in lines],'repeat':[],'flag':'dialogue_'+ident,'speakers':list(dict.fromkeys(['player']+[s for s,t in lines])),'on_finish':[{'event':'start_cutscene','cutscene':event}] if event else [{'event':'set_flag','flag':'tiamat_talk_done'}]}
  d['interactions'][ident]={'variants':[spec]}
 write('data/dialogue.json',d)
 d=read('data/npcs.json');next(n for n in d['npcs'] if n['id']=='utnapishtim').update(interactable=True,interaction='utnapishtim_talk',interact_range=120);write('data/npcs.json',d)
 d=read('data/story.json');d['stages']=[s for s in d['stages'] if s['stage']<19]+[{'stage':19,'flags':['utnapishtim_done','huluppu_boss_done','tiamat_talk_done']},{'stage':20,'flags':['system_laochachahra_selected','siyavash_started']}];write('data/story.json',d)
 d=read('data/cutscenes.json');d['cutscenes'].update({x:[{'type':'odyssey_event','event':x}] for x in ['utnapishtim_rampage','huluppu_climb','huluppu_victory']});write('data/cutscenes.json',d)
 write('data/choices.json',{'systems':[{'id':i,'label':l,'unlocked':i=='laochachahra','target':'HwaniraPlaza' if i=='laochachahra' else ''} for i,l in [('earth_union','지구 연합'),('lemuaren','레무아렌'),('laochachahra','라오차차흐라'),('dingir','딩이르')]]})
 write('data/siyavash.json',{'max_hp':100,'weapon':'none','skills':[],'sprite_set':'siyavash','age':20,'no_weapon_text':'아직 무기가 없다','cheeks':'rose red bilateral','animal_features':False})
 spec={'rage_after_cutscene':100,'death_suspended_until_crown_clear':True,'rampage_attack_seconds':3.0,'rampage_fade_seconds':2.5,'rampage_fade_in_seconds':1.2,'climb_x':1040,'climb_y':280,'climb_seconds':2.4,'climb_range':120,'tiamat_trigger_x':2380,'tiamat_body_x':2760,'tiamat_free_seconds':10.0,'darkness_seconds':3.0,'heal_interval':18.0,'heal_positions':[[450,880],[1050,880],[1700,880],[2650,880]],'major_attack_gap':.8,'crown_opening_seconds':1.2,'blood_position':[1450,862],'blood_size':[400,18],'plaza_bgm':'villa_calm'};write('data/odyssey.json',spec)
 enemies=read('data/enemies.json');enemies['enemies']=[e for e in enemies['enemies'] if e['id'] not in ['ninazu_mother','lilith','zu']]
 configs=[('ninazu_mother','니나즈의 어미',1930,.5,[300,260],55,{'poison':{'windup':.9,'active':.4,'recovery':1.1,'damage':2,'seconds':5.,'tick_interval':.25,'dps':8,'radius':160,'height':65,'cooldown':5.8,'box':[420,80]},'tail':{'windup':.7,'active':.2,'recovery':1.0,'damage':18,'stagger_seconds':.3,'cooldown':3.2,'box':[320,220]}},{'shockwave_stun':1.0}),('lilith','릴리스',2050,.2,[135,210],280,{'ambush':{'windup':.5,'active':.75,'recovery':1.0,'damage':10,'count':3,'interval':.25,'teleport_seconds':.1,'cooldown':5.5,'box':[150,160]},'charm':{'windup':.65,'active':.2,'recovery':.8,'damage':0,'reverse_seconds':2.5,'speed':480,'range':700,'cooldown':6.,'box':[200,160]},'ghost':{'windup':.2,'active':.4,'recovery':.8,'damage':0,'stagger_seconds':.5,'interval':4.5,'cooldown':4.5,'box':[350,240]}},{}),('zu','괴물새 주',1880,.35,[270,230],130,{'feathers':{'windup':.8,'active':.3,'recovery':1.2,'damage':11,'count':5,'speed':450,'spread_degrees':60,'cooldown':4.8,'box':[700,500]},'grab':{'windup':1.0,'active':1.25,'recovery':1.0,'damage':33,'dive_speed':720,'carry_seconds':.5,'cooldown':7.,'box':[150,150]}},{'air_fourth_stun':2.0})]
 for i,name,hp,turn,body,speed,patterns,extra in configs:
  for key,pat in patterns.items():pat.update(id=key,windup_clip=key+'_windup',active_clip=key+'_attack',recovery_clip='idle')
  e={'id':i,'display_name':name,'hp':hp,'turn_delay':turn,'body_size':body,'body_offset_y':-body[1]/2,'frame_size':[1280,1152],'anchor':[640,1100],'visual_scale':.3,'size_multiplier':1.,'art_height_px':body[1]/.3,'move_speed':speed,'detect_range':4000,'knockback_multiplier':.2,'drop_chance':0.,'hurt_sfx':'humbaba_hurt','death_sfx':'humbaba_death','patterns':patterns,'attacks':list(patterns.values()),'cooldown_offset':{'ninazu_mother':1.,'lilith':2.4,'zu':3.8}[i],**extra};enemies['enemies'].append(e)
 write('data/enemies.json',enemies)
 levels=read('data/levels.json');base=copy.deepcopy(next(l for l in levels['levels'] if l['id']=='TiamatZone'));next(l for l in levels['levels'] if l['id']=='TiamatZone')['npcs'][0]['interactable']=True
 levels['levels']=[l for l in levels['levels'] if l['id'] not in ['HuluppuCrown','TiamatCollapsed','HwaniraPlaza']]
 for ident,width,label in [('HuluppuCrown',3200,'훌루푸 나무 위'),('TiamatCollapsed',3000,'티아마트 구역'),('HwaniraPlaza',4000,'흐와니라 광장')]:
  l=copy.deepcopy(base);l.update(id=ident,scene='res://scenes/'+ident+'.tscn',width=width,display_name=label,camera_limits=[0,0,width,1120],walk_bounds=[0,width],terrain=[{'id':'ground','from':0,'to':width,'y':880}],platforms=[],decorations=[],npcs=[],spawns={'Spawn_Start':[250,880]},safe_zones=[] if ident=='HuluppuCrown' else [[0,-1000,width,3000]])
  if ident=='HuluppuCrown':
   l.update(bgm='cedar_boss',spawns={'Spawn_Entrance':[250,880]},enemies=[{'id':i,'position':at,'patrol_center':at[0],'patrol_range':1400} for i,at in [('ninazu_mother',[2050,880]),('lilith',[1350,880]),('zu',[2450,510])]])
   # Connected 90px rising chain; upper route brings air fourth strike within Zu's hurtbox.
   for side in [0,1]:
    for j in range(3):l['platforms'].append({'id':f'branch_{side}_{j}','position':[650+side*1400+j*180,790-j*90],'width':220,'art':'res://assets/tiles/huluppu/branch.png','art_height':48,'one_way':True})
   for j in range(4):l['platforms'].append({'id':f'crown_bridge_{j}','position':[1150+j*220,610],'width':220,'art':'res://assets/tiles/huluppu/branch.png','art_height':48,'one_way':True})
   l['floor_art']='res://assets/tiles/huluppu/branch.png';l['floor_art_size']=[512,200]
  if ident=='HwaniraPlaza':
   l.update(bgm='villa_calm',bg_dim=[1,1,1],spawns={'Spawn_Start':[650,880]},floor_art='res://assets/tiles/hwanira/plaza.png')
   l['backgrounds']=[{'name':'Hwanira','path':'res://assets/backgrounds/hwanira/plaza.webp','position':[0,0],'size':[4000,1120],'ratio':1.,'z':-40}]
   l['decorations']=[{'name':'Brazier','path':'res://assets/props/front_brazier.webp','position':[1900,620],'size':[150,260],'z':-2}] if (R/'assets/props/front_brazier.webp').exists() else []
  levels['levels'].append(l)
  (R/'scenes'/f'{ident}.tscn').write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/level_base.gd" id="1"]\n\n[node name="'+ident+'" type="Node2D"]\nscript = ExtResource("1")\nlevel_id = "'+ident+'"\n')
 for ident in ['ninazu_mother','lilith','zu']:levels['world']['enemy_scripts'][ident]='res://scripts/enemy_'+ident+'.gd'
 write('data/levels.json',levels)
 # Independent literal fixtures are authored in tests, not generated from dialogue data.
if __name__=='__main__':main()
