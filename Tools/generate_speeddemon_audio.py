"""Original deterministic motor/metal SFX, 22.05 kHz mono PCM."""
import math
import random
import wave
import struct
from pathlib import Path

DEST = Path(__file__).resolve().parents[1] / "Audio/Sfx/Melee/Speeddemon"
DEST.mkdir(parents=True, exist_ok=True)
RATE = 22050
for name, duration in [("start", .22), ("motor", 1), ("cut", 1), ("stop", .3), ("wall", .25)]:
    rng = random.Random(72)
    samples = []
    phase = 0.0
    for i in range(round(RATE * duration)):
        t = i / RATE
        x = t / duration
        frequency = 90 if name == "motor" else 170
        if name == "start": frequency = 40 + 180 * x
        if name == "stop": frequency = 160 - 120 * x
        phase += math.tau * frequency / RATE
        motor = sum(math.sin(phase * k) / k for k in (1, 2, 3, 5, 7)) * .22
        noise = rng.uniform(-1, 1)
        if name == "cut":
            value = .16 * math.sin(math.tau * 170 * t) + .12 * math.sin(math.tau * 1190 * t) + noise * .12
        elif name == "wall":
            value = (noise * .35 + math.sin(math.tau * 75 * t) * .3) * (1-x)**2
        else:
            value = motor * (.8 + .2 * math.sin(math.tau * 30 * t)) + noise * .025
        if name not in ("motor", "cut"):
            value *= min(1, t / .008) * min(1, (duration - t) / .04)
        samples.append(struct.pack("<h", round(max(-.9, min(.9, value)) * 32767)))
    with wave.open(str(DEST / f"{name}.wav"), "wb") as out:
        out.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        out.writeframes(b"".join(samples))
