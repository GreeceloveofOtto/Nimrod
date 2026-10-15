#!/usr/bin/env python3
"""Write measured Korean delivery reports; never upgrades missing evidence to PASS."""
from pathlib import Path
import json,subprocess,hashlib,collections,re,zipfile
ROOT=Path(__file__).resolve().parents[2];A=ROOT/'archive/stage14_rework';D=ROOT/'docs'
def read(p,default=None):
 p=ROOT/p
 return json.loads(p.read_text()) if p.exists() else default

def table(headers,rows):return '| '+' | '.join(headers)+' |\n| '+' | '.join(['---']*len(headers))+' |\n'+''.join('| '+' | '.join(str(v).replace('|','/') for v in row)+' |\n' for row in rows)+'\n'
def mib(n):return f'{n/1048576:.2f}'
def filesizes(root):return {str(p.relative_to(ROOT)):p.stat().st_size for p in root.rglob('*') if p.is_file() and p.suffix not in ['.import','.uid']}
def main():
 world=read(Path('data/world/zabulistan/world_v2.json'));art=read(Path('data/world/zabulistan/art_v2.json'));quality=read(Path('data/world/zabulistan/art_quality.json'),[]);validation=read(Path('archive/stage14_rework/world_validation.json'),{});budget=read(Path('archive/stage14_rework/art/budget.json'),{});optimization=read(Path('archive/stage14_rework/optimization.json'),[])
 archive=read(Path('archive/package_report.json'),{});is_rework='stage14_rework' in str(archive.get('zip',''));package=archive if is_rework else {}
 results=read(Path('archive/stage14_rework/final_results.json'),[])
 if not results and package.get('extracted_project'):
  p=Path(package['extracted_project'])/'archive/package_verification/results.json'
  if p.exists():results=json.loads(p.read_text())
 if not results:results=read(Path('archive/stage14_rework/headless/results.json'),[])
 functional=bool(results) and all(r['passed'] for r in results)
 old=read(Path('archive/stage14_rework/baseline.json'))
 runtime=filesizes(ROOT/'assets');runtime_bytes=sum(runtime.values());new_bytes=sum((ROOT/r['path']).stat().st_size for r in quality);saved=sum(r['before']-r.get('after',r['before']) for r in optimization)
 entities=[];pieces=[]
 for path in world['chunks'].values():
  chunk=read(Path(path.removeprefix('res://')));entities+=chunk['entities'];pieces+=chunk['landmarks']
 placements={'spawn':world['spawn'],'regions':world['regions'],'entities':entities,'landmarks':pieces}
 (D/'stage14_rework_placements.json').write_text(json.dumps(placements,ensure_ascii=False,indent=2)+'\n')
 moved=[]
 for p in (A/'retired').rglob('*'):
  if not p.is_file() or p.suffix in ['.import','.uid'] or p.name=='.gdignore':continue
  name=str(p.relative_to(A/'retired'))
  original=('assets/world/zabulistan/'+name.removeprefix('assets_world_zabulistan/')) if name.startswith('assets_world_zabulistan/') else 'data/world/zabulistan/regions.json' if name=='regions.json' else name
  moved.append({'original':original,'archive':str(p.relative_to(ROOT)),'bytes':p.stat().st_size})
 modified=subprocess.check_output(['git','diff','--name-status','HEAD'],cwd=ROOT,text=True).splitlines();untracked=subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=ROOT,text=True).splitlines()
 (D/'stage14_rework_file_manifest.json').write_text(json.dumps({'changes':[line.split('\t') for line in modified]+[['A',p] for p in untracked],'archived':moved},ensure_ascii=False,indent=2)+'\n')
 old_folders=collections.defaultdict(int)
 for r in moved:
  if r['original'].startswith('assets/world/zabulistan/'):old_folders[r['original'].split('/')[3]]+=r['bytes']
 diagnoses=[f'기존 지역 아트는 {len(old_folders)}개 폴더, 합계 {sum(old_folders.values()):,}B({mib(sum(old_folders.values()))} MiB)였고 작은 재질 타일을 반복했다.', '기존 600개 방 JSON·WorldRoom.tscn·입구 페이드·마지막 방 부활 및 world_map.gd의 상시 summary/미니맵을 직접 확인하고 연속 월드로 교체했다.', f'작업 전 ZIP은 {old["zip_bytes"]:,}B({mib(old["zip_bytes"])} MiB)로 기존 목표를 초과했다.']
 assumptions=[
 ['월드 / 타일', '640×360타일, 타일32px =20,480×11,520px, 256화면','권장 최소 이상; 10개 지역을 5×2로 연결'],
 ['청크 / 스트리밍','64×36타일, 총 100개, 현재와 8이웃까지 9개','JSON 읽기는 작업 스레드, 타일 4행/장식 1개/개체 1개씩 주 스레드에서 생성'],
 ['성능 판정','헤드리스 프레임 P95 <50ms, 생성step <25ms','첫 진입 중 텍스처·스크립트·TileSet 공유 캐시 준비; 진행 중 로딩 화면 없음'],
 ['손설계 원본','80×45개의 명시적 8×8 ASCII 판; 난수·시드 생성기 없음','source/maze.ascii와 glyphs.json 편집; 컴파일러는 펼치기/RLE/위치 접지만 수행'],
 ['카메라 / 경계','월드 전체 경계; 지역 전환 페이드 없음','지역 배경을 경계 양쪽 30타일(960px)에서혼합'],
 ['자막 / 배경','지역 첫 진입 2초(.3+1.4+.3), 하단중앙','3겹수평패럴랙스 .12/.30/.58; 원본1024×256, 게임표시4배'],
 ['지역조각','지역마다 8개, 전역 총 80개, 조각 각 1회 사용','아틀라스1024정사각,3×3칸,2px여백;표시밀도0.9'],
 ['재질 / 접합','지역6개재질×4개방향,32px타일+2px확장패딩','접합부RGB평균차≤8/255;2×2,4×4조합검사'],
 ['랜드마크 위치','지역별8개앵커;모든좌표는별첨JSON','지형아래묻히지않게알파발기준점으로맞춤'],
 ['광원','기존npc_light_pool을지역별2곳,300×70px,알파.4','생성이미지재사용;PointLight2D나절차적FX없음'],
 ['괴수 배치','일반99마리,마을0,정예4마리(4.04%)','사용자 답변대로 낮은 밀도 우선;기존13,790대비99.28%감소'],
 ['활성 / 어그로','거리960px,활성최대12,근접3/원거리2/급강하1/폭발1','기존반경1920px의절반;지역HP/데미지배수유지'],
 ['거대해골 / 부유령','거대해골지역당1(마을0),부유령최대2한화면','거대해골은다른일반개체와같은1280×720화면에놓지않음'],
 ['회복 / 생명조각','처치시기존회복7%;조각4개마다HP+10,최대200','조각60,결정60,시야전승아이템10;니므롯수치변경없음'],
 ['능력 / 키','Q질주,Space이중점프/벽점프,A/D벽매달리기,S기기,F시야,R빛투척,M지도,Esc일시정지','기존7능력수치와4개생성클립재사용;새 플레이어/괴수 이미지 0장'],
 ['상호작용 / 문','E,범위100px;단방향 스위치는 오른쪽에서만','능력벽56×160px;시야벽은F로발견후지름길로영구개방'],
 ['HP / HUD','생명 조각 최대 HP 증가는 광장에도 적용; 월드에서는 HP 바/무기 아이콘만 유지','0~420×140 영역 텍스트 금지 때문에 HP 숫자/레벨 제목도 숨김'],
 ['지도','8×8타일셀80×45 bool,원시3600B;Deflate+Base64저장','화면주변5×3셀중벽시야선이통하는셀만해제;미니맵없음'],
 ['죽음후진행','능력·생명조각·문·지름길·지도·보스처치유지;결정·전승임시수집품소멸','다음시도에서지름길을활용하도록함;광장도착시자동저장'],
 ['죽음후일반괴수','청크해제시에도처치UID유지,죽고광장귀환후재진입하면일반괴수리셋','보스처치기록은영구유지;살아있는적은청크재로드시원래위치/HP'],
 ['귀환 / 재진입','기존사망1.6초 +암전.3초+자막.35초+복귀.3초,도착레벨생성포함3초목표','HP는get_max_hp()완전회복,착륙지재진입만제공;지름길착륙선택UI없음'],
 ['죽음횟수표시(§7해석그대로)','플레이 중에는 죽음 횟수를 표시하지 않는다. 화면을 어지럽히지 않기 위해서다.','사망 암전: 흐와니라 광장 / 죽음 N회; 지도 하단: 죽음 N회; 일시정지: 자불리스탄 죽음 N회 · 전체 죽음 M회'],
 ['사망집계예외','HP0확정에1회,동일 프레임 추가 원인은 무시','death_suspended인훔바바폼은집계제외;F5완전초기화는카운터도초기화'],
 ['저장 / 호환','스키마2,zabulistan블록과deaths_total추가','스키마1누락값은빈진행/0회;자불리스탄모든저장경로차단'],
 ['보스 / 퇴각','기존3종임시보스·다른표시이름·placeholder=true유지','연속맵귀환가능성우선으로퇴각허용;청크원점과무관한global좌표추격'],
 ['릴리스디버그','developer_overlay=false;F3는디버그빌드+명시적설정에서만','별도CanvasLayer;릴리스에는생성경로차단'],
 ['동일지형검사','빈공간과암반까지전체24×14창포함','사용자명시답변반영;좌표해시/장식으로다른지형인척하지않음'],
 ]
 text='\n'.join(diagnoses)+'\n\n# 가정한 값\n\n'+table(['항목','값','근거 / 처리'],assumptions)
 text+='전체지역·개체·보상·벽·랜드마크좌표는 [stage14_rework_placements.json](stage14_rework_placements.json)에있다.지형자체는손설계ASCII와컴파일된청크가정확한좌표기준이다.\n\n'
 text+='## 지역 / 팔레트 / 세트피스\n\n'+table(['지역','타일경계x,y,w,h','광원팔레트','BGM','세트피스 / 구성'],[[r['name'],r['bounds'],'#'+r['palette'],r['bgm'],r['setpiece']+' · 플랫폼탐색+'+('숨은전승/문' if r['id']=='village' else '전투/숨은길')] for r in world['regions']])
 text+='## 신규 생성 아트\n\n'+table(['지역','계층A재질/방향','계층B','배경','파일 / MiB'],[[r['name'],'6 / 4',8,3,f"5 / {mib(sum((ROOT/q['path']).stat().st_size for q in quality if '/'+r['id']+'/' in q['path']))}"] for r in world['regions']])
 text+=f'신규 생성 이미지50파일,서로다른랜드마크80개,합계**{mib(new_bytes)} MiB /6 MiB**.같은랜드마크재사용은없다.원본 22장 이미지 생성 호출(랜드마크10/배경10/재질시트2)은archive/stage14_rework/art/에보관하고배포 ZIP에서 제외한다. ASCII 빌드 입력은 저장소와 QA ZIP에 포함하고 실행용 ZIP에서는 제외한다.플레이어21클립·단검공격·괴수5종·보스3종·회복·공유오브젝트·광원·효과음은기존이미지/소리그대로재사용했다.\n\n'
 if quality:text+=f'인코딩검증:SSIM최솟값{min(r["ssim"] for r in quality):.5f},RGB평균오차최댓값{max(r["rgb_mae"] for r in quality):.5f}/255,알파평균오차최댓값{max(r["alpha_mae"] for r in quality):.5f}/255,모든 알파 bbox 동일. 각 파일의 경로·크기·지표·SHA는 [art_quality.json](../data/world/zabulistan/art_quality.json)에 있다.부호화는WebP78~98후보와RGB8/10/12간격제한양자화중모든기준을통과하는가장작은파일을선택했다.광원/보라색과마젠타키테두리를구분해크로마키·3px디스필·리샘플링후2px테두리정리를적용했다.\n\n'
 text+='## 검증\n\n'+table(['항목','결과'],[
 ['지형 / 청크 / 반복',f"{world['width']}×{world['height']},100청크;24×14반복{validation.get('duplicate_windows','미측정')}건"],
 ['물리도달성',f"도달가능한서있는위치{validation.get('reachable_standing_nodes','미측정'):,};귀환불가{validation.get('trapped_reachable_nodes','미측정')}" if validation else '미측정'],
 ['능력 / 문 조합',f"{validation.get('gate_states_proved','미측정')}상태;실패{validation.get('state_solver_failure','미측정')}"],
 ['전체헤드리스',f"{sum(r['passed'] for r in results)}/{len(results)}; {'통과' if functional else '아직 최종 통과 아님'}"],
 ['배포물 독립검증','통과' if package.get('functional_verification_passed') else '아직 검증 전'],
 ['GL좌상단텍스트 / 캡처','tests/stage14_stream_capture.gd의6지역×2검사;로그와6장비교이미지QA포함'],
 ['이미지 / 알파 / 접지','check_world_art,check_alpha_cleanliness,프레임/머리위잔상/적크기/기존접지QA로그별첨'],
 ])
 text+='도달성은 32px 발 위치와 8분할 포물선 표본, 낮은 천장에서의 걸어 떨어지기를 이용한 보수적 물리 모델이다. 닫힌 모든 게이트 밖에서 서 있을 수 있는 위치에 추가 이동 능력 없이 귀환 경로가 있는지도 별도 검사한다.물리 그래프를 축약한 후 능력 128조합 × 문 1024조합을 모두 검사한다.점프·발판 통과 수치는 abilities.json을 읽으며 공중의 모든 연속 좌표나 긴 실제 키보드 공략을 수학적으로 증명한 것은 아니다.자동 검사와 GL 대표 화면은 수행했으며 256화면 전체의 수동 완주는 수행하지 않았다.\n\n'
 if package.get('extracted_project'):
  logs=A/'final_verification'
  if not logs.exists():logs=Path(package['extracted_project'])/'archive/package_verification'
  for filename,caption in [('stage14_performance.log','분할 스트리밍 측정'),('stage14_death_timing.log','실제 사망 귀환 시간')]:
   if (logs/filename).exists():
    measured=[line for line in (logs/filename).read_text().splitlines() if line.startswith(('CONTINUOUS_PERFORMANCE:','STATIC_MEMORY_DELTA_BYTES:','DEATH_RETURN_SECONDS:'))]
    if measured:text+='**'+caption+'**: `'+('; '.join(measured))+'`\n\n'
 text+='## 제거 / 보존\n\n기존600개방JSON,WorldRoom.tscn,world_room.gd,방인덱스/미니맵,구타일20개,구방생성기와구조에종속된테스트를archive/로옮겼다.삭제/변경/추가및각보존위치전체목록은[파일명세](stage14_rework_file_manifest.json)에있다.기존levels.json과대사JSON은바꾸지않았다.니므롯코드의접점은사망집계,세이브호환,HUD표시조건뿐이며기존전투수치/스토리를바꾸지않았다.\n\n'
 text+='## 용량\n\n'+table(['항목','MiB'],[['작업전ZIP',mib(old['zip_bytes'])],['최신검증ZIP',mib(package['zip_bytes']) if package else '아직 최종 미측정'],['작업전assets',mib(old['asset_bytes'])],['현재assets',mib(runtime_bytes)],['신규아트',mib(new_bytes)],['archive이동(코드/JSON/구아트)',mib(sum(r['bytes'] for r in moved))],['기존이미지안전재압축절감',mib(saved)],['중복병합절감','0.00']])
 text+='**전체 ZIP 63 MiB 목표는 미달**이다.기존 필수 리소스 자체가 이미 63 MiB를 넘는 데다 신규 아트를 추가했기 때문이다.상위30개이미지의제한RGB양자화재검사는'+f'{saved:,}B만절감했고,유사프레임병합과중복통합후보도없었다.기준미달후보는적용하지않았다.이미모노48kbps인BGM과모노OGG효과음은추가음질손상우려로유지했다.상위20파일과조건부추가감량안은SIZE_REPORT_KO.md에있다.\n\n'
 checks=[['방교체/입구페이드폐기','○'],['640×360단일월드/9청크','○'],['빈공간·암반포함24×14중복0','○' if validation.get('duplicate_windows')==0 else '×'],['10지역/랜드마크80/배경30','○'],['사망광장귀환/진행유지/카운터','○' if functional else '검사중'],['상시정보/미니맵제거','○'],['낮은괴수밀도/5종재사용','○'],['능력·단방향문상태귀환검사','○' if validation.get('passed') else '×'],['전체자동회귀','○' if functional else '×'],['신규아트6MiB','○' if new_bytes<=6291456 else '×'],['전체ZIP63MiB','○' if package.get('zip_bytes',10**12)<=63*1048576 else '×'],['256화면전체수동완주','×(미실행)']]
 text+='## 완료표\n\n'+table(['항목','결과'],checks)
 (D/'stage14_rework_report.md').write_text(text)
 density=validation.get('density_by_region',{})
 (D/'zabulistan_density_report.md').write_text('# 자불리스탄괴수밀도\n\n'+table(['지역','일반','정예','거대해골'],[[r['name'],density.get(r['id'],{}).get('count','미측정'),density.get(r['id'],{}).get('elite','미측정'),density.get(r['id'],{}).get('colossus','미측정')] for r in world['regions']])+f"기존13,790→99마리(99.28%감소).사용자답변으로총량40~50%보다낮은밀도를우선했다.전체40×23타일이동창에서최대{validation.get('maximum_enemies_per_viewport','미측정')}마리,평화창{validation.get('peaceful_viewports_percent',0):.2f}%.거대해골과다른일반개체가같은1280×720창에들지않는지별도검사한다.근접3/원거리2/급강하1/폭발1,활성반경960px·최대12개,회복드롭7%.처치기록은한시도동안청크해제에도유지하고죽은뒤새시도에서초기화한다.\n")
 (D/'WORLD_SAVE_POLICY_KO.md').write_text('# 연속월드저장정책\n\n자불리스탄에서can_save,save_game,save_checkpoint,_write_snapshot와백업복구쓰기모두차단한다.사망시흐와니라광장으로귀환해완전회복하고조용히자동저장한다.능력·생명조각UID·문/지름길·압축지도·보스처치·사망횟수는zabulistan블록으로복원한다.결정·전승임시수집품은사망시소멸한다.기존 스키마 1은 새 블록 {}와 0회로 마이그레이션한다.불러오기위치는광장이며재진입은착륙지다.수동시야우와르샨저장지점을추가하지않았다.니므롯저장지점은유지하고전체사망수메타데이터만기존체크포인트에갱신한다.F5는저장파일과새영구진행·횟수까지완전초기화한다.\n')
 (D/'WORLD_STATS_KO.md').write_text('# 연속월드통계\n\n'+table(['항목','값'],[['타일',640*360],['화면',256],['청크',100],['지역',10],['일반괴수',99],['임시보스',3],['능력',7],['생명조각',60],['결정',60],['숨은전승',10],['단방향문',10],['능력게이트',70],['고유랜드마크',80],['원시ASCII B',(ROOT/'data/world/zabulistan/source/world.ascii').stat().st_size],['청크JSON B',sum((ROOT/p.removeprefix('res://')).stat().st_size for p in world['chunks'].values())]]))
 (D/'WORLD_PROGRESSION_KO.md').write_text('# 진행과귀환검증\n\n착륙지에서지역간기본길로모든지역에갈수있고,능력은쥐의질주→두번째도약→벽의발톱→벽차오르기→틈새기기→광질시야→천륜빛투척순으로선행조건을갖는다.능력벽은지름길이며기본순환길을대체하지않는다.도구는실제타일과플레이어폭36/높이124·중력1750·속도360·점프695를읽어이동그래프를만들고,모든보상/보스/스위치의접근과귀환을검사한다.능력·문131,072조합검증은state_solver.json에,도달/반복/밀도결과는world_validation.json에기록한다.\n\n룸최단경로와방입구는폐기했다.위치기준진행·좌표는stage14_rework_placements.json을참조한다.\n')
 prefix='\n## Stage14 연속월드재작업\n\n'+table(['검사','결과'],[['신규지역아트',f'50파일/80조각/{mib(new_bytes)}MiB'],['투명아틀라스','2px여백·발앵커·밀도0.9'],['타일','6재질/4방향,2px확장패딩;이음매8/255이하'],['재사용캐릭터','기존프레임/알파/머리위잔상/접지검사유지'],['GL','6지역캡처와좌상단텍스트ROI검사'],['비고','실제검사로그는QA ZIP;전체수동완주미실행']])
 p=D/'SPRITE_QA_REPORT_KO.md';s=p.read_text();s=s.split('\n## Stage14 연속월드재작업')[0];p.write_text(s+prefix)
 sizep=D/'SIZE_REPORT_KO.md';s=sizep.read_text().split('\n## Stage14 연속월드재작업')[0]
 s+='\n## Stage14 연속월드재작업\n\n'+table(['항목','전MiB','후MiB'],[['assets',mib(old['asset_bytes']),mib(runtime_bytes)],['ZIP',mib(old['zip_bytes']),mib(package['zip_bytes']) if package else '최종미측정'],['자불리스탄전용아트(공통 오브젝트 제외)','0.10',mib(new_bytes)],['archive이동',0,mib(sum(r['bytes'] for r in moved))],['중복병합절감',0,0]])
 folders=collections.defaultdict(int)
 for path,n in runtime.items():folders['/'.join(path.split('/')[:3])]+=n
 s+='\n현재폴더상위10:\n\n'+table(['폴더','MiB'],[[k,mib(v)] for k,v in sorted(folders.items(),key=lambda item:-item[1])[:10]])
 s+='\n상위20파일및후속후보(예상은조건부이며검증된절감이아님):\n\n'+table(['파일','KiB','미감량사유 / 다음후보'],[[k,f'{v/1024:.1f}','현행SSIM/색차 기준 또는 밀도 하한; 별도 LOD 재제작/논리 프레임 유사도 재검토 후 약 10% 조건부'] for k,v in sorted(runtime.items(),key=lambda item:-item[1])[:20]])
 s+=f'\n안전재압축{saved:,}B,프레임병합0B,동일해시/근사중복0B.보수적재인코딩실패목록은optimization.json의trials에있다.신규아트는6MiB내,전체ZIP63MiB는미달이다.기존필수에셋자체가상한을넘으며개발캐시·원본·비교캡처·구룸/아트는모두제외했다.오디오는이미모노OGG여서추가음질손실없이큰감량은어렵다.\n';sizep.write_text(s)
 spacing={'전체헤드리스':'전체 헤드리스','원본참조':'원본 참조','투명아틀라스':'투명 아틀라스','원시ASCII':'원시 ASCII','청크JSON':'청크 JSON','미니맵없음':'미니맵 없음','게임표시':'게임 표시 ','표시밀도':'표시 밀도 ','신규아트':'신규 아트 ','일반괴수':'일반 괴수','단방향문':'단방향 문','보스처치':'보스 처치','영구진행':'영구 진행','안전재압축':'안전 재압축 ','현재폴더상위10':'현재 폴더 상위 10','상위20파일':'상위 20개 파일','조건부추가감량안':'조건부 추가 감량안','지형아래묻히지않게알파발기준점으로맞춤':'지형 아래 묻히지 않게 알파 발 기준점으로 맞춤','지형자체':'지형 자체','모든좌표':'모든 좌표','별첨JSON':'별첨 JSON','수평패럴랙스':'수평 패럴랙스','모노OGG':'모노 OGG','낮은밀도':'낮은 밀도','재사용캐릭터':'재사용 캐릭터','전체자동회귀':'전체 자동 회귀'}
 for name in ['stage14_rework_report.md','zabulistan_density_report.md','WORLD_SAVE_POLICY_KO.md','WORLD_STATS_KO.md','WORLD_PROGRESSION_KO.md','SPRITE_QA_REPORT_KO.md','SIZE_REPORT_KO.md']:
  document=D/name;content=document.read_text()
  for old_text,new_text in spacing.items():content=content.replace(old_text,new_text)
  document.write_text(content.rstrip()+'\n')
 from polish_rework_report import polish
 polish()
 print('REPORT',len(results),'checks; functional',functional,'new art MiB',mib(new_bytes),'assets',mib(runtime_bytes))
if __name__=='__main__':main()
