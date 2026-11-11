from pathlib import Path
p=Path('Scripts/Enemies/boss1.gd');s=p.read_text(encoding='utf-8-sig');start=s.index('\nfunc _play_death_fx()');s=s[:start]+'\n';p.write_text(s,encoding='utf-8')
p=Path('Scenes/Main.tscn');s=p.read_text(encoding='utf-8-sig').replace('uid://lpsu8nbsyhl5','uid://c1av8534doktp');p.write_text(s,encoding='utf-8')
