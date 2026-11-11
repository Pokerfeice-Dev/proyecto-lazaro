from pathlib import Path
import re
root=Path.cwd()
for p in root.rglob('*.import'):
 if '.godot' in p.parts or '.git' in p.parts: continue
 source=Path(str(p)[:-7])
 if not source.exists(): print(p)
