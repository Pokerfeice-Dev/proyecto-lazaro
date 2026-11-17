# Generador de salas del Núcleo (zona 3). Arma plataformas con el mismo marco que Level3_Room3
# (borde superior de festones, acantilado de raíces, puente entre cámaras, fosos) y las combina.
import json
from props import prop_block, CAT

WALL_TILE = (1, 1)           # tile de colisión casi invisible (2 píxeles) para la capa Walls
TAN_A, TAN_B = (17, 8), (18, 8)
MAUVE = [(28, 26), (29, 26), (30, 26)]
MARKS = [(40, 31), (41, 31), (40, 32), (41, 32)]   # tan con marcas (2x2)

PROPS = {}
def prop(name):
    if name not in PROPS: PROPS[name] = prop_block(name, *CAT[name])
    return PROPS[name]


class Room:
    def __init__(self, name, title):
        self.name, self.title = name, title
        self.floor, self.walls, self.objs = {}, {}, {}
        self.walk = set()          # celdas caminables (incluye pasillos de los puentes)
        self.interior = set()      # solo interiores de plataforma

        self.blocked = set()       # celdas con obstáculos
        self.plateaus = []
        self.spawns, self.barrels = [], []
        self.player = None
        self.door = None
        self.ygor = None           # tienda de Ygor: celda donde va Ygor
        self.reserve = set()       # celdas que los props sueltos no pueden ocupar

    # ---------------------------------------------------------------- plataforma
    def plateau(self, IL, IT, IW, IH, top='A', bottom='cliff', floor='tan', up=None, down=None, grow=True):
        """Plataforma con interior [IL, IL+IW) x [IT, IT+IH). up/down: columna (izquierda) del
        puente hacia arriba/abajo (el pasillo mide 2 de ancho)."""
        # las plataformas salían angostas: 1 o 2 tiles de más (menos en las que ya son grandes)
        if grow:
            IW += 2 if IW < 14 else 1
            IH += 2 if IH < 8 else 1
        IB = IT + IH
        if down is not None and not (IL + 3 <= down <= IL + IW - 2): raise ValueError('puente hacia abajo fuera de rango en la plataforma IL=%d' % IL)
        if up is not None and not (IL + 1 <= up <= IL + IW - 3): raise ValueError('puente hacia arriba fuera de rango en la plataforma IL=%d' % IL)
        base = TAN_A if bottom == 'cliff' else TAN_B
        for y in range(IT, IB):
            for x in range(IL, IL + IW):
                self.floor[(x, y)] = base
                self.walk.add((x, y)); self.interior.add((x, y))
            self.floor[(IL - 2, y)] = (26, 12); self.floor[(IL - 1, y)] = (27, 12)
            if bottom == 'solid': self.floor[(IL + IW, y)] = (24, 12); self.floor[(IL + IW + 1, y)] = (25, 12)
            else: self.floor[(IL + IW, y)] = (10, 32); self.floor[(IL + IW + 1, y)] = (11, 32)
        # borde superior (3 filas) -> Walls. El festón se repite cada 8 tiles (fases p0..p7): cada tramo
        # tiene que empezar en una fase y terminar en otra para que no quede cortado contra la esquina o
        # contra el puente; el sobrante de ancho se rellena con tiles bajos (p0).
        gap = (top == 'gap')
        x_first, x_last = IL - 1, IL + IW - 1
        if up is None: segs_top = [(x_first, x_last, 0, 0 if gap else 4)]
        else: segs_top = [(x_first, up - 2, 0, 0), (up + 3, x_last, 1, 0 if gap else 4)]
        for (xa, xb, p_start, p_end) in segs_top:
            n = xb - xa + 1
            if n <= 0: continue
            core_min = (p_end - p_start) % 8 + 1
            if n < core_min: phases = [0] * n
            else:
                fill = (n - core_min) % 8
                core = [(p_start + i) % 8 for i in range(core_min + (n - core_min - fill))]
                phases = [0] * fill + core
            for i, p in enumerate(phases):
                x = xa + i
                for y_off, row in ((-3, 12), (-2, 13), (-1, 14)):
                    if row == 12 and x < IL - 1: continue
                    if row != 12 and x < IL: continue
                    y = IT + y_off
                    if gap and p in (3, 4):
                        if row == 12: continue
                        self.walls[(x, y)] = (16, row)
                    else:
                        self.walls[(x, y)] = (16 + p, row)
        self.walls[(IL - 1, IT - 1)] = (44, 4)
        self.walls[(IL + IW, IT - 1)] = (42, 4)
        if gap: self.walls[(IL + IW + 1, IT - 1)] = (43, 4)
        if up is not None:
            cx = up
            for dx in range(4):
                x = cx - 1 + dx
                self.floor[(x, IT - 4)] = [(12, 32), (13, 32), (14, 32), (15, 32)][dx]
                self.floor[(x, IT - 3)] = [(12, 32), (13, 32), (14, 32), (15, 32)][dx]
                self.walls[(x, IT - 2)] = [(17, 13), (36, 2), (14, 32), (25, 13)][dx]
                self.walls[(x, IT - 1)] = [(17, 14), (18, 8), (18, 8), (16, 14)][dx]
            for x in (cx, cx + 1):
                self.walk.add((x, IT - 4)); self.walk.add((x, IT - 3)); self.walk.add((x, IT - 2)); self.walk.add((x, IT - 1))
        # borde inferior
        if bottom == 'cliff':
            for i in range(4):
                for j in range(3):
                    self.walls[(IL - 1 + i, IB + j)] = (16 + i, 9 + j)
            segs = [(IL + 3, IL + IW)] if down is None else [(IL + 3, down - 1), (down + 2, IL + IW)]
            for (a, b) in segs:
                for x in range(a, b + 1):
                    for j in range(4):
                        self.walls[(x, IB + j)] = (31 + (4 - ((b - x) % 5)), j)
            if down is not None:
                for j in range(4):
                    self.floor[(down, IB + j)] = (36, j)
                    self.floor[(down + 1, IB + j)] = (37, j)
                    self.walk.add((down, IB + j)); self.walk.add((down + 1, IB + j))
                self.walk.add((down, IB + 4)); self.walk.add((down + 1, IB + 4))
        else:
            self.floor[(IL - 2, IB)] = (26, 12)
            for x in range(IL - 1, IL + IW + 1):
                self.floor[(x, IB)] = (34 + ((x - (IL - 1)) % 2), 29)
                self.floor[(x, IB + 1)] = (34 + ((x - (IL - 1)) % 2), 30)
        self.plateaus.append(dict(IL=IL, IT=IT, IW=IW, IH=IH, IB=IB))
        return self.plateaus[-1]

    # ---------------------------------------------------------------- piso
    def zone(self, x0, y0, w, h, kind):
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                if (x, y) not in self.walk: continue
                if kind == 'mauve': self.floor[(x, y)] = MAUVE[(x * 7 + y * 3) % 3]
                elif kind == 'marks': self.floor[(x, y)] = MARKS[(x % 2) + 2 * (y % 2)]
                elif kind == 'tan': self.floor[(x, y)] = TAN_A

    def ring(self, cx, cy, r, kind):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + 1: self.zone(x, y, 1, 1, kind)

    # ---------------------------------------------------------------- obstáculos
    def root3(self, x, y):
        for j in range(3):
            for i in range(3):
                self.objs[(x + i, y + j)] = (24 + i, 8 + j)
                self.blocked.add((x + i, y + j))

    def pit(self, x, y):
        rows = [[(24, 8), (25, 8), (25, 8), (25, 8), (26, 8), (27, 8)],
                [(24, 9), (25, 9), (25, 9), (25, 9), (26, 9), (27, 9)],
                [(24, 12), (25, 12), None, None, (26, 12), (27, 12)],
                [(24, 12), (25, 12), None, None, (26, 12), (27, 12)],
                [(24, 13), (25, 13), None, None, (26, 13), (27, 13)],
                [(24, 14), (25, 14), (26, 14), (26, 14), (26, 14), (27, 14)]]
        for j, r in enumerate(rows):
            for i, t in enumerate(r):
                self.blocked.add((x + i, y + j))
                if t is not None: self.floor[(x + i, y + j)] = t
                else:
                    self.floor.pop((x + i, y + j), None)
                    self.walls[(x + i, y + j)] = WALL_TILE

    def prop(self, name, x, y):
        """Pone el objeto con su esquina superior izquierda en (x, y)."""
        p = prop(name)
        ox, oy = p['origin']
        for (a, b) in p['tiles']:
            self.objs[(x + a - ox, y + b - oy)] = (a, b)
            self.blocked.add((x + a - ox, y + b - oy))

    def scatter(self, names, n, seed, margin=0):
        """Reparte props chicos por los interiores, lejos de spawns, jugador y puerta."""
        import random
        rnd = random.Random(seed)
        keep = set()
        for p in self.spawns + self.barrels + [self.player, self.door]:
            for dy in range(-2, 3):
                for dx in range(-2, 3): keep.add((p[0] + dx, p[1] + dy))
        keep |= self.reserve
        placed = 0
        base = self.connected()      # si ya había puntos tapados por props a mano, no se exige
        cells = sorted(self.interior)
        for _ in range(400):
            if placed >= n: break
            name = rnd.choice(names)
            p = prop(name); ox, oy = p['origin']
            x, y = rnd.choice(cells)
            tiles = [(x + a - ox, y + b - oy) for a, b in p['tiles']]
            ok = True
            for c in tiles:
                if c not in self.interior or c in self.blocked or c in keep: ok = False; break
                # que quede separado del borde de la plataforma
                for dy in range(-margin, margin + 1):
                    for dx in range(-margin, margin + 1):
                        if (c[0] + dx, c[1] + dy) not in self.interior: ok = False
                if not ok: break
            if not ok: continue
            before = set(self.blocked)
            self.prop(name, x, y)
            if base and not self.connected():
                for c in tiles:
                    self.objs.pop(c, None)
                self.blocked = before
                continue
            placed += 1
        return placed

    # ---------------------------------------------------------------- cierre
    def finish(self):
        # anillo de colisión invisible: toda celda vacía a 2 o menos de algo dibujado
        used = set(self.floor) | set(self.walls) | set(self.objs)
        for (x, y) in list(used):
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    c = (x + dx, y + dy)
                    if c not in used and c not in self.walls:
                        self.walls[c] = WALL_TILE
        # una celda con tile real no lleva muro invisible
        for c in list(self.walls):
            if self.walls[c] == WALL_TILE and (c in self.floor or c in self.objs):
                del self.walls[c]
        # origen en (0, 0)
        allc = list(self.floor) + list(self.walls) + list(self.objs)
        self.minx = min(c[0] for c in allc); self.miny = min(c[1] for c in allc)

    def connected(self):
        """True si desde el jugador se llega a todos los spawns, barriles y la puerta sin pasar por obstáculos."""
        start = self.player
        seen = {start}; st = [start]
        while st:
            x, y = st.pop()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                c = (x + dx, y + dy)
                if c in seen or c not in self.walk or c in self.blocked: continue
                seen.add(c); st.append(c)
        goals = self.spawns + self.barrels + [self.door]
        return all(p in seen for p in goals)

    def free(self, x, y):
        return (x, y) in self.interior and (x, y) not in self.blocked

    def snap(self, p, taken):
        """Celda libre más cercana a p que no esté tomada."""
        if self.free(*p) and p not in taken: return p
        best = None
        for r in range(1, 8):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    if max(abs(dx), abs(dy)) != r: continue
                    c = (p[0] + dx, p[1] + dy)
                    if self.free(*c) and c not in taken: return c
        return p

    def snap_all(self):
        taken = set()
        out = []
        for lst_name in ('spawns', 'barrels'):
            new = []
            for p in getattr(self, lst_name):
                q = self.snap(p, taken); taken.add(q); new.append(q)
            setattr(self, lst_name, new)
        self.player = self.snap(self.player, taken); taken.add(self.player)
        self.door = self.snap(self.door, taken)

    def to_json(self):
        mx, my = self.minx, self.miny
        sh = lambda d: [[x - mx, y - my, a, b] for (x, y), (a, b) in sorted(d.items())]
        pl = lambda p: [p[0] - mx, p[1] - my]
        return {'name': self.name, 'title': self.title, 'floor': sh(self.floor), 'objects': sh(self.objs),
                'walls': sh(self.walls), 'spawns': [pl(p) for p in self.spawns], 'barrels': [pl(p) for p in self.barrels],
                'player': pl(self.player), 'door': pl(self.door)} | ({'kind': 'shop', 'ygor': pl(self.ygor)} if self.ygor else {})
