# -*- coding: utf-8 -*-
"""Montaje de los videos para redes de FRANKEN-GUN (9:16), versión 2.

El juego se graba en horizontal normal (16:9, sin estirar). Acá se arma el video vertical:

  - arriba y abajo: arte del juego (fondo, marcos, título, subtítulos animados)
  - en el medio: una ventana CUADRADA del juego a tamaño real, con el HUD recortado en las esquinas
  - versión A: muda, con subtítulos
  - versión B: con "huecos" a pantalla completa (unos segundos) donde se pone el video de la cara

Los textos y animaciones se dibujan aparte (overlay.py, con Chromium) y llegan como capas.

Pasos (desde la raíz del proyecto):
  python Tools/director_clips/montaje.py Tools/director_clips/videos/FG_01.json planos
      corta los planos y escribe _tmp/FG_01_tiempos.json (duraciones reales)
  python Tools/director_clips/montaje.py Tools/director_clips/videos/FG_01.json componer A|B
      junta todo con las capas de _tmp/overlay/ y deja el mp4 en la carpeta de salida
"""
import json
import os
import re
import subprocess
import sys

FF = r"C:\Program Files\FFmepg\bin\ffmpeg.exe"
FP = r"C:\Program Files\FFmepg\bin\ffprobe.exe"
FPS = 30
W, H = 1080, 1920
VENT = 1080  # ventana cuadrada del juego
VENT_Y = 420
TOMAS = "Tools/director_clips/_salida"
TMP = "Tools/director_clips/_tmp"
OV = TMP + "/overlay"
SFX_ARRANQUE = "Audio/Sfx/IA/menu_inicio_arcade.mp3"
SFX_TEXTO = "Audio/Sfx/Fantasy_UI (8).wav"
SFX_CIERRE = "Audio/Sfx/SciFi reward.mp3"
CIERRE_DUR = 3.2

# Recortes del HUD en la grabación de 1920x1080 (x, y, ancho, alto) y dónde van en la ventana
HUD = [
    ("vida", (20, 20, 470, 180), (14, 14)),
    ("cuenta", (1700, 30, 200, 140), (VENT - 200 - 14, 14)),
    ("armas", (1600, 915, 300, 150), (VENT - 300 - 14, VENT - 150 - 14)),
]


def correr(args):
    print(">", " ".join(a if " " not in a else '"%s"' % a for a in args[:6]), "...")
    r = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        lineas = [l[:400] for l in r.stderr.splitlines()
                  if any(k in l for k in ("rror", "nvalid", "No such", "Unable", "not found", "No option", "Undefined"))]
        print("\n".join(lineas[:30]))
        print(r.stderr[-800:])
        raise SystemExit("ffmpeg falló")
    return r


def duracion(ruta):
    r = subprocess.run([FP, "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", ruta],
                       capture_output=True, text=True)
    return float(r.stdout.strip())


def ancho_video(ruta):
    r = subprocess.run([FP, "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width", "-of", "csv=p=0", ruta],
                       capture_output=True, text=True)
    return int(r.stdout.strip())


def datos_toma(toma):
    with open(os.path.join(TOMAS, toma + ".json"), encoding="utf-8") as f:
        d = json.load(f)
    return {m["id"]: m["seg"] for m in d["marcas"]}, d.get("pos", [])


# --- 1. Planos -------------------------------------------------------------------

def x_centro(pos, f0, f1):
    """Posición horizontal media de Lázaro en pantalla (unidades de 1920) entre dos cuadros."""
    xs = [p[1] for p in pos if len(p) == 3 and f0 <= p[0] <= f1]
    return sum(xs) / len(xs) if xs else 960.0


def plano(i, p, out):
    """Corta un plano: ventana cuadrada del juego + HUD en las esquinas (o la pantalla completa)."""
    dur = p["dur"]
    if "archivo" in p:  # tramo de una grabación real (la run de Marcos), sin telemetría
        m, pos = {}, []
        desde = p["desde"]
        src = p["archivo"]
    else:
        m, pos = datos_toma(p["toma"])
        desde = m[p.get("marca", "inicio")] + p.get("desde", 0.0)
        if "fin" in m:  # nunca más allá del final de la toma
            dur = max(0.5, min(dur, m["fin"] + 0.5 - desde))
        src = os.path.join(TOMAS, p["toma"] + ".avi")
    e = ancho_video(src) / 1920.0  # 2.0 si se grabó en 3840x2160
    cx = x_centro(pos, int(desde * FPS), int((desde + dur) * FPS)) if not p.get("centrado") else 960.0
    cw = int(VENT * e)
    x0 = max(0, min(int(1920 * e) - cw, int(cx * e - cw / 2)))
    z = p.get("zoom", 1.0)
    cz, cy = p.get("centro", [0.5, 0.5])
    f = []
    if p.get("completo"):
        # interfaz entera (inventario, O.M.N.I.A.): 16:9 a todo el ancho con el mismo juego borroso detrás
        f.append("[0:v]fps=%d,split[a0][b0];[b0]scale=%d:%d,boxblur=22:3,eq=brightness=-0.3[bg];"
                 "[a0]scale=%d:-2:flags=lanczos[fg];[bg][fg]overlay=0:(H-h)/2,setsar=1[g0]" % (FPS, VENT, VENT, VENT))
        ultimo = "g0"
    else:
        n = len(HUD) + 1
        f.append("[0:v]fps=%d,split=%d%s" % (FPS, n, "".join("[s%d]" % k for k in range(n))))
        f.append("[s0]crop=%d:%d:%d:0,scale=%d:%d:flags=lanczos,setsar=1[g0]" % (cw, int(1080 * e), x0, VENT, VENT))
        ultimo = "g0"
        if z != 1.0:  # zoom fijo hacia un punto
            zw, zh = int(VENT / z) // 2 * 2, int(VENT / z) // 2 * 2
            f.append("[g0]crop=%d:%d:%d:%d,scale=%d:%d:flags=lanczos[g1]" % (
                zw, zh, int((VENT - zw) * cz), int((VENT - zh) * cy), VENT, VENT))
            ultimo = "g1"
        entrada = p.get("entrada", "destello" if i > 0 else "golpe")
        if entrada in ("golpe", "temblor"):
            # zoom de golpe del 110% al 100% con un temblor que se apaga (como el arranque del menú)
            f.append("[%s]zoompan=z='if(lt(in,8),1.10-0.10*in/8,1)':x='iw/2-(iw/zoom/2)+if(lt(in,10),14*sin(in*2.7)*(1-in/10),0)'"
                     ":y='ih/2-(ih/zoom/2)+if(lt(in,10),14*cos(in*3.3)*(1-in/10),0)':d=1:s=%dx%d:fps=%d[g2]" % (ultimo, VENT, VENT, FPS))
            ultimo = "g2"
        for k, (nom, (hx, hy, hw, hh), (px, py)) in enumerate(HUD):
            f.append("[s%d]crop=%d:%d:%d:%d,scale=%d:%d:flags=lanczos[h%d]" % (
                k + 1, int(hw * e), int(hh * e), int(hx * e), int(hy * e), hw, hh, k))
            f.append("[%s][h%d]overlay=%d:%d[o%d]" % (ultimo, k, px, py, k))
            ultimo = "o%d" % k
        if entrada in ("destello", "golpe"):
            f.append("[%s]fade=t=in:st=0:d=0.18:color=white[o9]" % ultimo)
            ultimo = "o9"
    if p.get("lento"):
        f.append("[%s]setpts=%s*PTS[o10]" % (ultimo, p["lento"]))
        ultimo = "o10"
    f.append("[%s]scale=%d:%d:out_range=tv,setsar=1,format=yuv420p,setparams=range=tv:colorspace=bt470bg[v]" % (ultimo, VENT, VENT))
    af = ["aresample=48000", "aformat=channel_layouts=stereo"]
    if p.get("lento"):
        af.append("atempo=%s" % max(0.5, 1.0 / p["lento"]))
    if p.get("silencio"):
        af.append("volume=0")
    script = "%s/plano_%d_filtro.txt" % (TMP, i)
    with open(script, "w", encoding="utf-8") as fh:
        fh.write(";".join(f))
    correr([FF, "-y", "-ss", "%.3f" % desde, "-t", "%.3f" % dur, "-i", src,
            "-/filter_complex", script, "-map", "[v]", "-map", "0:a?", "-af", ",".join(af),
            "-t", "%.3f" % (dur * p.get("lento", 1.0)),
            "-c:v", "libx264", "-preset", "veryfast", "-crf", "14", "-pix_fmt", "yuv420p", "-color_range", "tv",
            "-c:a", "pcm_s16le", out])
    return duracion(out)


def bloque_negro(dur, out):
    """Negro con silencio (los huecos para la cara y la placa final van encima, desde las capas)."""
    correr([FF, "-y", "-f", "lavfi", "-i", "color=c=black:s=%dx%d:r=%d:d=%.3f" % (VENT, VENT, FPS, dur),
            "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", "%.3f" % dur,
            "-vf", "format=yuv420p,setparams=range=tv:colorspace=bt470bg",
            "-c:v", "libx264", "-preset", "veryfast", "-crf", "14", "-pix_fmt", "yuv420p", "-color_range", "tv",
            "-c:a", "pcm_s16le", out])
    return duracion(out)


def unir(segs, out, nombre):
    lista = "%s/%s_lista.txt" % (TMP, nombre)
    with open(lista, "w", encoding="utf-8") as f:
        for s in segs:
            f.write("file '%s'\n" % os.path.abspath(s).replace("\\", "/"))
    correr([FF, "-y", "-f", "concat", "-safe", "0", "-i", lista, "-c", "copy", out])


def cmd_planos(cfg):
    os.makedirs(TMP, exist_ok=True)
    nombre = cfg["id"]
    segs, durs = [], []
    for i, p in enumerate(cfg["planos"]):
        out = "%s/%s_p%02d.mkv" % (TMP, nombre, i)
        durs.append(plano(i, p, out))
        print("   plano %d: %.3f s" % (i, durs[-1]))
        segs.append(out)
    cierre = bloque_negro(CIERRE_DUR, "%s/%s_cierre.mkv" % (TMP, nombre))
    # versión A: sin huecos
    unir(segs + ["%s/%s_cierre.mkv" % (TMP, nombre)], "%s/%s_base_A.mkv" % (TMP, nombre), nombre + "_A")
    inicios_a = [sum(durs[:i]) for i in range(len(durs))]
    fin_a = sum(durs)
    # versión B: con los huecos de la cara (pantalla completa) entre planos
    huecos = cfg.get("huecos", [])
    segs_b, inicios_b, huecos_t = [], [], []
    t = 0.0
    for i, s in enumerate(segs):
        inicios_b.append(t)
        segs_b.append(s)
        t += durs[i]
        for k, h in enumerate(huecos):
            if h["despues"] == i:
                g = "%s/%s_hueco%d.mkv" % (TMP, nombre, k)
                d = bloque_negro(h["dur"], g)
                segs_b.append(g)
                huecos_t.append({"t0": t, "t1": t + d, "quien": h.get("quien", cfg.get("cara", "MARCOS")), "guion": h.get("guion", "")})
                t += d
    fin_b = t
    unir(segs_b + ["%s/%s_cierre.mkv" % (TMP, nombre)], "%s/%s_base_B.mkv" % (TMP, nombre), nombre + "_B")
    tiempos = {
        "id": nombre, "dur_planos": durs, "cierre": cierre,
        "A": {"inicios": inicios_a, "fin_juego": fin_a, "total": fin_a + cierre, "huecos": []},
        "B": {"inicios": inicios_b, "fin_juego": fin_b, "total": fin_b + cierre, "huecos": huecos_t},
    }
    with open("%s/%s_tiempos.json" % (TMP, nombre), "w", encoding="utf-8") as f:
        json.dump(tiempos, f, indent=1)
    print("TIEMPOS", nombre, "A=%.2f B=%.2f" % (fin_a + cierre, fin_b + cierre))


# --- 2. Composición final --------------------------------------------------------

SFX = {"titulo": (SFX_TEXTO, -12), "etiqueta": (SFX_TEXTO, -14), "numero": (SFX_TEXTO, -10),
       "jefe": (SFX_TEXTO, -12), "sub": (SFX_TEXTO, -24), "desarrollo": (SFX_TEXTO, -16)}


def audio_mezcla(cfg, spec, version, base, total, out_wav):
    """Mezcla juego + música original + golpes de interfaz y la deja a -14 LUFS (dos pasadas)."""
    mus = cfg["musica"]
    fin = spec["fin_juego"]
    huecos = spec.get("huecos", [])
    entradas = [FF, "-y", "-i", base,
                "-ss", "%.2f" % mus["desde"], "-t", "%.2f" % (total + 0.5), "-i", mus["archivo"],
                "-i", SFX_ARRANQUE, "-i", SFX_CIERRE]
    vol_mus = mus.get("vol", -9.0)
    duck = "".join(",volume=enable='between(t,%.3f,%.3f)':volume=0.22" % (h["t0"], h["t1"]) for h in huecos)
    ac = ("[1:a]aresample=48000,aformat=channel_layouts=stereo,volume=%.1fdB,afade=t=in:st=0:d=0.4,"
          "afade=t=out:st=%.2f:d=1.2%s[mus];" % (vol_mus, total - 1.2, duck))
    ac += "[0:a]aresample=48000,aformat=channel_layouts=stereo,volume=%.1fdB[jue];" % cfg.get("vol_juego", 0.0)
    ac += "[2:a]aresample=48000,aformat=channel_layouts=stereo,volume=-4dB[arr];"
    ms = int(fin * 1000)
    ac += "[3:a]aresample=48000,aformat=channel_layouts=stereo,volume=-6dB,adelay=%d|%d[cie];" % (ms, ms)
    mezcla = ["[jue]", "[mus]", "[arr]", "[cie]"]
    k = 0
    for el in spec["elementos"]:
        if el["tipo"] not in SFX:
            continue
        if el["tipo"] == "sub" and version != "A":
            continue
        arch, vol = SFX[el["tipo"]]
        entradas += ["-i", arch]
        ms = int(el["t0"] * 1000)
        ac += "[%d:a]aresample=48000,aformat=channel_layouts=stereo,volume=%ddB,adelay=%d|%d[s%d];" % (4 + k, vol, ms, ms, k)
        mezcla.append("[s%d]" % k)
        k += 1
    ac += "%samix=inputs=%d:normalize=0:duration=first,alimiter=limit=0.95[a]" % ("".join(mezcla), len(mezcla))
    script = "%s/%s_%s_audio.txt" % (TMP, cfg["id"], version)
    with open(script, "w", encoding="utf-8") as f:
        f.write(ac)
    crudo = "%s/%s_%s_crudo.wav" % (TMP, cfg["id"], version)
    correr(entradas + ["-/filter_complex", script, "-map", "[a]", "-t", "%.3f" % total, "-c:a", "pcm_s16le", crudo])
    # medir y normalizar a -14 LUFS / -1.5 dBTP
    r = subprocess.run([FF, "-hide_banner", "-i", crudo, "-af", "loudnorm=I=-14:TP=-1.5:LRA=11:print_format=json", "-f", "null", "-"],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    j = re.search(r"\{[^{}]*\"input_i\"[^{}]*\}", r.stderr, re.S)
    if j:
        d = json.loads(j.group(0))
        ln = ("loudnorm=I=-14:TP=-1.5:LRA=11:measured_I=%s:measured_TP=%s:measured_LRA=%s:measured_thresh=%s:offset=%s:linear=true"
              % (d["input_i"], d["input_tp"], d["input_lra"], d["input_thresh"], d["target_offset"]))
    else:
        ln = "loudnorm=I=-14:TP=-1.5:LRA=11"
    correr([FF, "-y", "-i", crudo, "-af", ln + ",aresample=48000", "-c:a", "pcm_s16le", out_wav])


def cmd_componer(cfg, version):
    nombre = cfg["id"]
    spec_ruta = "%s/%s_%s_spec.json" % (OV, nombre, version)
    with open(spec_ruta, encoding="utf-8") as f:
        spec = json.load(f)
    total = spec["total"]
    fin = spec["fin_juego"]
    base = "%s/%s_base_%s.mkv" % (TMP, nombre, version)
    wav = "%s/%s_%s_final.wav" % (TMP, nombre, version)
    audio_mezcla(cfg, spec, version, base, total, wav)

    pref = "%s/%s_%s" % (OV, nombre, version)
    plenos = []
    if os.path.exists(pref + "_plenos.json"):
        with open(pref + "_plenos.json", encoding="utf-8") as f:
            plenos = json.load(f)
    entradas = [FF, "-y", "-i", base,
                "-loop", "1", "-framerate", str(FPS), "-t", "%.3f" % total, "-i", pref + "_marco.png",
                "-c:v", "libvpx-vp9", "-i", pref + "_capas.webm"]
    for pl in plenos:
        entradas += ["-i", "%s/%s" % (OV, pl["archivo"])]
    entradas += ["-i", wav]
    f = ["color=c=0x0b0f12:s=%dx%d:r=%d:d=%.3f[fondo]" % (W, H, FPS, total),
         "[0:v]format=yuva420p[juego]",
         "[fondo][juego]overlay=0:%d:shortest=0[a]" % VENT_Y,
         "[a][1:v]overlay=0:0:format=auto[b]",
         "[b][2:v]overlay=0:0:format=auto[c]"]
    ultimo = "c"
    for k, pl in enumerate(plenos):
        f.append("[%d:v]setpts=PTS-STARTPTS+%.3f/TB[p%d]" % (3 + k, pl["t0"], k))
        f.append("[%s][p%d]overlay=0:0:enable='between(t,%.3f,%.3f)':eof_action=pass[d%d]" % (ultimo, k, pl["t0"], pl["t1"], k))
        ultimo = "d%d" % k
    f.append("[%s]format=yuv420p[v]" % ultimo)
    script = "%s/%s_%s_video.txt" % (TMP, nombre, version)
    with open(script, "w", encoding="utf-8") as fh:
        fh.write(";".join(f))
    sufijo = "A_mudo" if version == "A" else "B_cara"
    salida = os.path.join(cfg["salida"], "%s_%s.mp4" % (nombre, sufijo))
    os.makedirs(cfg["salida"], exist_ok=True)
    correr(entradas + ["-/filter_complex", script, "-map", "[v]", "-map", "%d:a" % (3 + len(plenos)), "-t", "%.3f" % total,
                       "-c:v", "libx264", "-preset", "medium", "-crf", "17", "-pix_fmt", "yuv420p", "-r", str(FPS),
                       "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", salida])
    print("LISTO", salida, "%.1f s" % total)


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as fh:
        cfg = json.load(fh)
    modo = sys.argv[2] if len(sys.argv) > 2 else "planos"
    if modo == "planos":
        cmd_planos(cfg)
    else:
        for v in (sys.argv[3:] or ["A", "B"]):
            cmd_componer(cfg, v)
