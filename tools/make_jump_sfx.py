#!/usr/bin/env python3
"""Regenerate Nimrod's jump variations and short landing sound (numpy + wave)."""
import numpy as np

from audio_common import PROJECT_ROOT, band_noise, envelope, timeline, write_wav


def jump(seconds, fundamental, seed):
    t = timeline(seconds)
    rng = np.random.default_rng(seed)
    # ~40 ms leather/stone push-off; lowpassed noise avoids an electronic click.
    thud = (
        0.62 * np.sin(2.0 * np.pi * fundamental * t)
        + 0.16 * band_noise(len(t), rng, 30.0, 220.0)
    ) * envelope(t, attack=0.001, decay=0.012, duration=0.040)
    cloth_t = np.maximum(t - 0.012, 0.0)
    cloth = 0.105 * band_noise(len(t), rng, 1000.0, 4000.0)
    cloth *= envelope(cloth_t, attack=0.007, decay=0.040, duration=0.120)
    # Very quiet breath, at most -36 dBFS before mix normalization.
    breath = band_noise(len(t), rng, 450.0, 2600.0)
    breath /= max(np.max(np.abs(breath)), 1e-12)
    breath *= 10.0 ** (-36.0 / 20.0)
    breath *= envelope(np.maximum(t - 0.035, 0.0), attack=0.025, decay=0.080)
    return thud + cloth + breath


def landing():
    t = timeline(0.120)
    rng = np.random.default_rng(27182)
    foot = 0.60 * np.sin(2.0 * np.pi * 88.0 * t)
    foot += 0.20 * band_noise(len(t), rng, 40.0, 260.0)
    foot *= envelope(t, attack=0.001, decay=0.023)
    dust = 0.09 * band_noise(len(t), rng, 700.0, 4800.0)
    dust *= envelope(t, attack=0.004, decay=0.035)
    return foot + dust


def main():
    audio_dir = PROJECT_ROOT / "assets/audio"
    for name, seconds, pitch, seed in [
        ("jump_a", 0.200, 83.0, 317),
        ("jump_b", 0.220, 102.0, 911),
        ("jump_c", 0.240, 124.0, 1729),
    ]:
        write_wav(audio_dir / (name + ".wav"), jump(seconds, pitch, seed))
    write_wav(audio_dir / "land.wav", landing())
    print("Generated jump_a/b/c (0.20/0.22/0.24 s) and land (0.12 s).")


if __name__ == "__main__":
    main()
