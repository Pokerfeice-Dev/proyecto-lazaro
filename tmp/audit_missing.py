from pathlib import Path
import re, collections
root=Path.cwd(); missing=collections.defaultdict(list)
for folder in ['Scenes','Scripts','Art','Tests']:
 for p in (root/folder).rglob('*'):
  if p.suffix not in ['.gd','.tscn','.tres','.godot']: continue
  s=p.read_text(encoding='utf-8-sig')
  for m in re.finditer(r'res://[^"\n\r]+',s):
   path=m.group()
   if any(x in path for x in ['%',' + ','*']): continue
   if not (root/path[6:]).exists(): missing[path].append(str(p.relative_to(root)))
for k,v in missing.items(): print(k, '=>', ', '.join(dict.fromkeys(v)))
