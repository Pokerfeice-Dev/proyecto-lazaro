from pathlib import Path
import re
root=Path.cwd().resolve()
paths=[*root.glob('Scenes/Enemies/*.tscn'),root/'Scenes/Enemies/Crypt/crypt_enemy_base.tscn',root/'Scenes/UI/newgame.tscn']
for p in paths:
 s=p.read_text(encoding='utf-8-sig'); blocks=re.split(r'(?=^\[)',s,flags=re.M)
 removed={'Death_fx','Summon_anim'}
 if p.name=='EnemyTurret.tscn': removed.add('Sprite_BaseTurret')
 if p.name=='newgame.tscn': removed.add('Logo')
 kept=[]
 for b in blocks:
  m=re.match(r'\[node name="([^"]+)"',b)
  if m and m[1] in removed: continue
  kept.append(b)
 # Keep only resources reachable from nodes (including their transitive dependencies).
 resources={}
 for b in kept:
  m=re.match(r'\[(ext_resource|sub_resource).*? id="([^"]+)"',b)
  if m: resources[(('ExtResource' if m[1]=='ext_resource' else 'SubResource'),m[2])]=b
 refs=lambda text: set(re.findall(r'(ExtResource|SubResource)\("([^"]+)"\)',text))
 live=refs(''.join(b for b in kept if b.startswith('[node') or b.startswith('[connection')))
 while True:
  expanded=live|set().union(*(refs(resources.get(k,'')) for k in live))
  if expanded==live: break
  live=expanded
 result=[]
 for b in kept:
  m=re.match(r'\[(ext_resource|sub_resource).*? id="([^"]+)"',b)
  if m and (('ExtResource' if m[1]=='ext_resource' else 'SubResource'),m[2]) not in live: continue
  result.append(b)
 out=''.join(result)
 if out!=s:
  p.write_text(out,encoding='utf-8');print(p.relative_to(root))
for rel in ['Scenes/Enemies/Mannequin.tscn','Art/Enemies/Crypt/crypt_death_fx_frames.tres']:
 p=(root/rel).resolve(); assert p.is_relative_to(root)
 p.unlink();print('removed',rel)
p=root/'Scripts/UI/debug_menu.gd';s=p.read_text(encoding='utf-8-sig');p.write_text(s.replace('res://Scenes/Enemies/Mannequin.tscn','res://Scenes/Enemies/dummy.tscn'),encoding='utf-8')
