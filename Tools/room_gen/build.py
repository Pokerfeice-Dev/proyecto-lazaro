import json, sys
from PIL import Image, ImageDraw
from gen import Room, WALL_TILE
from props import ATLAS

def rel(P, dx, dy): return (P['IL'] + dx, P['IT'] + dy)

def stack(R, A, IL, IW, IH, down_prev, **kw):
    """Plataforma justo debajo de A, unida por el puente en la columna down_prev (absoluta)."""
    return R.plateau(IL, A['IB'] + 8, IW, IH, up=down_prev, **kw)

def room5():
    R = Room('Level3_Room5', 'Pilares')
    A = R.plateau(0, 3, 12, 6, top='A', bottom='cliff', down=5)
    B = stack(R, A, 4, 14, 6, 5, top='gap', bottom='solid')
    R.zone(*rel(A, 3, 1), 6, 4, 'mauve')
    R.zone(*rel(B, 1, 1), 12, 2, 'marks')
    for dx, dy in ((1, 1), (9, 1), (1, 3)): R.prop('calaveras', *rel(A, dx, dy))
    R.root3(*rel(B, 9, 2)); R.prop('roca_marron_a', *rel(B, 2, 3)); R.prop('hueso', *rel(B, 6, 0))
    R.player = rel(A, 5, 0)
    R.spawns = [rel(A, 10, 4), rel(A, 3, 4), rel(B, 2, 1), rel(B, 12, 4), rel(B, 6, 4)]
    R.barrels = [rel(A, 0, 0), rel(B, 13, 0)]
    R.door = rel(B, 8, 4)
    return R

def room6():
    R = Room('Level3_Room6', 'Pasillo ancho')
    A = R.plateau(0, 3, 22, 5, top='A', bottom='cliff', down=14)
    B = stack(R, A, 8, 10, 7, 14, top='gap', bottom='solid')
    R.zone(*rel(A, 1, 1), 20, 3, 'marks')
    R.zone(*rel(B, 2, 2), 6, 4, 'mauve')
    R.pit(*rel(A, 5, 0)); R.root3(*rel(A, 17, 1))
    R.prop('hueso', *rel(A, 10, 3)); R.prop('esqueleto_a', *rel(B, 1, 3)); R.prop('coral', *rel(B, 7, 4))
    R.player = rel(A, 11, 0)
    R.spawns = [rel(A, 2, 3), rel(A, 19, 3), rel(A, 12, 0), rel(B, 1, 1), rel(B, 8, 5), rel(B, 4, 5)]
    R.barrels = [rel(A, 20, 0), rel(B, 8, 0)]
    R.door = rel(B, 5, 5)
    return R

def room7():
    R = Room('Level3_Room7', 'Zigzag')
    A = R.plateau(0, 3, 9, 4, top='A', bottom='cliff', down=5)
    C = stack(R, A, 3, 8, 3, 5, top='gap', bottom='cliff', down=8)
    B = stack(R, C, 4, 9, 5, 8, top='gap', bottom='solid')
    R.zone(*rel(C, 1, 0), 6, 3, 'mauve')
    R.prop('hierba_ojos_fina', *rel(A, 0, 0)); R.prop('calaveras2', *rel(B, 1, 3))
    R.prop('planta_ojos', *rel(B, 6, 0)); R.root3(*rel(A, 6, 1))
    R.player = rel(A, 4, 0)
    R.spawns = [rel(A, 7, 3), rel(C, 1, 1), rel(C, 6, 1), rel(B, 2, 1), rel(B, 7, 3)]
    R.barrels = [rel(A, 1, 3), rel(B, 8, 0)]
    R.door = rel(B, 4, 3)
    return R

def room8():
    R = Room('Level3_Room8', 'Altar')
    A = R.plateau(0, 3, 17, 12, top='A', bottom='solid')
    R.ring(*rel(A, 8, 6), 5, 'mauve'); R.ring(*rel(A, 8, 6), 3, 'marks')
    R.prop('circulo_piedras', *rel(A, 5, 3))
    R.prop('hierba_ojos_a', *rel(A, 0, 0)); R.prop('calaveras', *rel(A, 14, 1)); R.prop('esqueleto_b', *rel(A, 13, 8))
    R.root3(*rel(A, 1, 8))
    R.player = rel(A, 8, 0)
    R.spawns = [rel(A, 3, 3), rel(A, 14, 4), rel(A, 3, 10), rel(A, 13, 6), rel(A, 8, 10)]
    R.barrels = [rel(A, 1, 6), rel(A, 15, 10)]
    R.door = rel(A, 8, 10)
    return R

def room9():
    R = Room('Level3_Room9', 'Galería')
    A = R.plateau(0, 3, 22, 5, top='A', bottom='cliff', down=4)
    B = stack(R, A, 0, 12, 6, 4, top='gap', bottom='solid')
    R.zone(*rel(A, 1, 1), 20, 3, 'marks')
    for dx in (7, 12, 17): R.root3(*rel(A, dx, 0))
    R.prop('cerebro_b', *rel(B, 5, 1)); R.pit(*rel(B, 8, 0)) if False else None
    R.prop('coral', *rel(B, 9, 3)); R.prop('hueso', *rel(A, 2, 2))
    R.player = rel(A, 11, 3)
    R.spawns = [rel(A, 2, 0), rel(A, 20, 4), rel(A, 14, 4), rel(B, 1, 1), rel(B, 10, 4), rel(B, 6, 4)]
    R.barrels = [rel(A, 20, 0), rel(B, 10, 0)]
    R.door = rel(B, 2, 4)
    return R

def room10():
    R = Room('Level3_Room10', 'Cuatro rocas')
    A = R.plateau(0, 3, 15, 13, top='gap', bottom='solid')
    R.zone(*rel(A, 5, 0), 5, 13, 'mauve'); R.zone(*rel(A, 0, 5), 15, 3, 'mauve')
    for dx, dy in ((2, 2), (10, 2), (2, 9), (10, 9)): R.prop('roca_grande_a', *rel(A, dx, dy))
    R.pit(*rel(A, 6, 4))
    R.player = rel(A, 7, 0)
    R.spawns = [rel(A, 1, 6), rel(A, 13, 6), rel(A, 7, 11), rel(A, 6, 3)]
    R.barrels = [rel(A, 0, 0), rel(A, 14, 12)]
    R.door = rel(A, 7, 11)
    return R

def room11():
    R = Room('Level3_Room11', 'Carriles')
    A = R.plateau(0, 3, 6, 7, top='A', bottom='cliff', down=3)
    B = stack(R, A, -4, 15, 6, 3, top='gap', bottom='solid')
    R.zone(*rel(A, 1, 0), 4, 7, 'marks'); R.zone(*rel(B, 2, 1), 12, 4, 'mauve')
    R.prop('hierba_ojos_fina', *rel(B, 1, 0)); R.prop('cuerno', *rel(B, 11, 3)); R.root3(*rel(B, 6, 2))
    R.prop('huesito_a', *rel(A, 3, 3))
    R.player = rel(A, 2, 0)
    R.spawns = [rel(A, 0, 3), rel(A, 4, 5), rel(B, 1, 3), rel(B, 13, 1), rel(B, 8, 5)]
    R.barrels = [rel(A, 5, 0), rel(B, 14, 5)]
    R.door = rel(B, 9, 4)
    return R

def room12():
    R = Room('Level3_Room12', 'Cámara chica')
    A = R.plateau(0, 3, 13, 9, top='A', bottom='solid')
    R.ring(*rel(A, 6, 4), 2, 'mauve')
    R.prop('cerebro_a', *rel(A, 4, 2)); R.prop('coral', *rel(A, 0, 0)); R.prop('huevo', *rel(A, 10, 5))
    R.player = rel(A, 6, 0)
    R.spawns = [rel(A, 1, 4), rel(A, 11, 3), rel(A, 3, 7), rel(A, 10, 7)]
    R.barrels = [rel(A, 11, 0)]
    R.door = rel(A, 6, 7)
    return R

def room13():
    R = Room('Level3_Room13', 'Escombros')
    A = R.plateau(0, 3, 15, 6, top='A', bottom='cliff', down=9)
    B = stack(R, A, 4, 10, 8, 9, top='gap', bottom='solid')
    R.zone(*rel(A, 1, 1), 5, 4, 'mauve'); R.zone(*rel(B, 1, 2), 6, 4, 'marks')
    R.prop('arco_piedra_a', *rel(A, 1, 1)); R.prop('roca_grande_b', *rel(A, 10, 1)); R.prop('piedras_bajas_a', *rel(A, 6, 4))
    R.prop('esqueleto_a', *rel(B, 6, 0)); R.prop('hueso', *rel(B, 1, 5)); R.root3(*rel(B, 5, 3)); R.prop('calaveras', *rel(B, 8, 5))
    R.player = rel(A, 9, 0)
    R.spawns = [rel(A, 13, 4), rel(A, 5, 0), rel(A, 8, 4), rel(B, 1, 1), rel(B, 8, 1), rel(B, 4, 6)]
    R.barrels = [rel(A, 14, 0), rel(B, 0, 6)]
    R.door = rel(B, 5, 6)
    return R

def room14():
    R = Room('Level3_Room14', 'Encrucijada')
    A = R.plateau(0, 3, 10, 5, top='A', bottom='cliff', down=4)
    C = stack(R, A, 1, 6, 3, 4, top='gap', bottom='cliff', down=4)
    B = stack(R, C, -3, 17, 7, 4, top='gap', bottom='solid')
    R.zone(*rel(B, 5, 1), 7, 5, 'mauve'); R.zone(*rel(A, 2, 1), 6, 3, 'marks')
    R.prop('ojo_gigante_a', *rel(B, 4, -1)) if False else None
    R.prop('planta_carnivora', *rel(B, 1, 0)); R.prop('cerebro_b', *rel(B, 12, 2)); R.prop('hueso', *rel(B, 7, 4))
    R.prop('hierba_ojos_fina', *rel(A, 7, 0)); R.root3(*rel(A, 1, 2))
    R.player = rel(A, 4, 0)
    R.spawns = [rel(A, 8, 3), rel(A, 1, 0), rel(B, 1, 5), rel(B, 15, 1), rel(B, 9, 2)]
    R.barrels = [rel(A, 9, 0), rel(B, 8, 5)]
    R.door = rel(B, 8, 5)
    return R

ROOMS = [room5, room6, room7, room8, room9, room10, room11, room12, room13, room14]

SMALL = ['huesito_a', 'huesito_b', 'huesito_c', 'piedras_bajas_a', 'piedras_bajas_b', 'calaveras', 'calaveras2', 'espinas',
         'huevo', 'coral', 'planta_ojos', 'cuerno', 'roca_marron_a', 'roca_marron_b', 'hierba_ojos_fina', 'esqueleto_a', 'esqueleto_b']
EXTRA = {5: 6, 6: 10, 7: 5, 8: 7, 9: 10, 10: 6, 11: 7, 12: 5, 13: 8, 14: 11}

def check(R):
    R.snap_all()
    R.scatter(SMALL, EXTRA[int(R.name.split('Room')[-1])], seed=int(R.name.split('Room')[-1]) * 31)
    bad = []
    for kind, pts in (('spawn', R.spawns), ('barril', R.barrels), ('jugador', [R.player]), ('puerta', [R.door])):
        for p in pts:
            if not R.free(*p): bad.append((kind, p))
    return bad

def render(R, scale=2):
    R.finish()
    mx, my = R.minx, R.miny
    cells = list(R.floor) + list(R.walls) + list(R.objs)
    W = max(c[0] for c in cells) - mx + 1; H = max(c[1] for c in cells) - my + 1
    im = Image.new('RGBA', (W * 16, H * 16), (20, 16, 28, 255))
    for layer in (R.floor, R.objs, R.walls):
        for (x, y), (ax, ay) in layer.items():
            t = ATLAS.crop((ax * 16, ay * 16, ax * 16 + 16, ay * 16 + 16))
            im.alpha_composite(t, ((x - mx) * 16, (y - my) * 16))
    d = ImageDraw.Draw(im)
    def mark(p, col, r=5):
        cx, cy = (p[0] - mx) * 16 + 8, (p[1] - my) * 16 + 8
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col, width=2)
    for p in R.spawns: mark(p, (255, 60, 60, 255))
    for p in R.barrels: mark(p, (255, 200, 40, 255), 4)
    mark(R.player, (60, 255, 90, 255)); mark(R.door, (80, 160, 255, 255), 6)
    return im.resize((im.width * scale, im.height * scale), Image.NEAREST)

if __name__ == '__main__':
    import os, argparse
    here = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser(description='Genera las salas del Núcleo (Level3_Room5-14) como JSON.')
    ap.add_argument('--out', default=os.path.join(here, '..', 'level3_rooms.json'))
    ap.add_argument('--preview', default=None, help='carpeta donde guardar una imagen por sala')
    ap.add_argument('rooms', nargs='*', help='números de sala (por defecto todas)')
    a = ap.parse_args()
    out = []
    for fn in ROOMS:
        R = fn()
        if a.rooms and R.name.split('Room')[-1] not in a.rooms: continue
        bad = check(R)
        im = render(R)
        if a.preview:
            os.makedirs(a.preview, exist_ok=True); im.save(os.path.join(a.preview, f'{R.name}.png'))
        print(R.name, R.title, im.size, 'PROBLEMAS:' if bad else 'ok', bad)
        out.append(R.to_json())
    json.dump(out, open(a.out, 'w'), separators=(',', ':'))
