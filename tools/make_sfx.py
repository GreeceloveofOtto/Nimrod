#!/usr/bin/env python3
"""Create replaceable, seeded combat sounds, mono 44100 Hz 16-bit PCM."""
import numpy as np

from audio_common import PROJECT_ROOT, band_noise, envelope, timeline, write_wav

SOUNDS = {
    "axe_hit_flesh": (0.15, "impact", 93.0),
    "axe_hit_heavy": (0.30, "heavy", 67.0),
    "shockwave": (0.30, "wave", 52.0),
    "beast_melee_windup": (0.40, "growl", 71.0),
    "beast_melee_attack": (0.20, "whoosh", 78.0),
    "beast_melee_hurt": (0.24, "hurt", 105.0),
    "beast_melee_death": (0.55, "death", 68.0),
    "beast_ranged_windup": (0.50, "inhale", 126.0),
    "beast_ranged_flame_start": (0.22, "flame_start", 84.0),
    "beast_ranged_flame_loop": (0.50, "flame_loop", 84.0),
    "beast_ranged_hurt": (0.24, "hurt", 156.0),
    "beast_ranged_death": (0.60, "death", 124.0),
    "player_hurt": (0.23, "hurt", 141.0),
}


def synthesize(duration, kind, pitch, seed):
    t = timeline(duration)
    rng = np.random.default_rng(seed)
    low_noise = band_noise(len(t), rng, 35.0, 320.0)
    mid_noise = band_noise(len(t), rng, 280.0, 3300.0)
    high_noise = band_noise(len(t), rng, 1100.0, 7800.0)
    tone = np.sin(2.0 * np.pi * (pitch * t + 0.8 * np.sin(2.0 * np.pi * 8.0 * t)))
    if kind == "impact":
        return (0.65 * tone + 0.18 * low_noise + 0.08 * mid_noise) * envelope(t, decay=0.024)
    if kind == "heavy":
        return (0.75 * tone + 0.28 * low_noise + 0.05 * high_noise) * envelope(t, decay=0.060)
    if kind == "wave":
        return (0.60 * tone + 0.25 * low_noise + 0.10 * mid_noise) * envelope(t, attack=0.007, decay=0.075)
    if kind == "growl":
        growl = tone + 0.24 * np.sin(2.0 * np.pi * (pitch * 2.05) * t) + 0.13 * low_noise
        return growl * envelope(t, attack=0.045, decay=0.200)
    if kind == "whoosh":
        return (0.50 * low_noise + 0.12 * mid_noise + 0.18 * tone) * np.sin(np.pi * t / duration) ** 2
    if kind == "inhale":
        return (0.34 * mid_noise + 0.11 * high_noise) * (t / duration) ** 0.6 * np.sin(np.pi * t / duration)
    if kind == "flame_start":
        return (0.48 * mid_noise + 0.12 * high_noise + 0.24 * low_noise) * envelope(t, attack=0.006, decay=0.065)
    if kind == "flame_loop":
        # All modulation frequencies complete an integer number of cycles in 0.5 s.
        # FFT noise is periodic, so the entire loop crosses its boundary naturally.
        rumble = np.sin(2.0 * np.pi * 84.0 * t) + 0.3 * np.sin(2.0 * np.pi * 126.0 * t)
        flutter = 0.75 + 0.16 * np.sin(2.0 * np.pi * 6.0 * t)
        return (0.38 * mid_noise + 0.14 * high_noise + 0.18 * rumble) * flutter
    if kind in ("hurt", "death"):
        fall = pitch * (0.48 if kind == "death" else 0.20)
        voice = np.sin(2.0 * np.pi * (pitch * t - fall * t * t / (2.0 * duration)))
        voice += 0.15 * np.sin(2.0 * np.pi * pitch * 1.98 * t)
        return (0.65 * voice + 0.12 * low_noise + 0.07 * mid_noise) * envelope(t, attack=0.012, decay=duration / 3.0)
    raise ValueError(kind)


def main():
    out_dir = PROJECT_ROOT / "assets/audio/sfx"
    for index, (name, (duration, kind, pitch)) in enumerate(SOUNDS.items()):
        signal = synthesize(duration, kind, pitch, 5100 + index)
        write_wav(out_dir / (name + ".wav"), signal, fade_seconds=0.0 if kind == "flame_loop" else 0.004)
    print(f"Generated {len(SOUNDS)} replaceable combat effects; flame_loop is periodic.")


if __name__ == "__main__":
    main()
