#!/usr/bin/env python3
"""Synthesize a 48-second seamless Uruk rear-gate drone and slow percussion."""
import json
import numpy as np

from audio_common import PROJECT_ROOT, SAMPLE_RATE, band_noise, timeline, write_wav

LOOP_SECONDS = 48.0


def make_stage2_bgm(spec):
    duration = float(spec["duration"])
    t = timeline(duration)
    signal = np.zeros_like(t)
    frequencies = [round(float(hz) * duration) / duration for hz in spec["frequencies"]]
    for index, (frequency, gain) in enumerate(zip(frequencies, spec["gains"])):
        tone = np.zeros_like(t)
        for harmonic in range(1, int(spec["string_harmonics"]) + 1):
            tone += np.sin(2.0 * np.pi * frequency * harmonic * t + index * 0.3) / harmonic ** 2
        signal += float(gain) * tone
    signal *= 0.82 + 0.13 * np.sin(2.0 * np.pi * int(spec["pulse_cycles"]) * t / duration)
    rng = np.random.default_rng(int(spec["seed"]))
    wind = band_noise(len(t), rng, *spec["wind_band"])
    signal += float(spec["wind_gain"]) * wind * (0.8 + 0.15 * np.sin(2.0 * np.pi * t / duration))
    interval = float(spec["chime_every"])
    for index, start in enumerate(np.arange(0.0, duration, interval)):
        elapsed = (t - start) % duration
        frequency = frequencies[index % len(frequencies)] * 2.0
        # Periodic tail wrap avoids a loop-end discontinuity.
        bell = np.sin(2.0 * np.pi * frequency * elapsed) * np.exp(-elapsed / 1.8)
        bell *= np.minimum(elapsed / 0.12, 1.0)
        signal += float(spec["chime_gain"]) * bell
    path = write_wav(PROJECT_ROOT / "assets/audio/bgm" / (spec["name"] + ".wav"), signal, fade_seconds=0.0)
    print(f"Generated {path.name}: {duration:g}s periodic loop.")


def main():
    t = timeline(LOOP_SECONDS)
    # Integer cycle counts keep all tones/modulation periodic over 48 seconds.
    drone = (
        0.25 * np.sin(2.0 * np.pi * 46.0 * t)
        + 0.13 * np.sin(2.0 * np.pi * 69.0 * t + 0.6)
        + 0.10 * np.sin(2.0 * np.pi * 92.0 * t + 0.3)
        + 0.045 * np.sin(2.0 * np.pi * 115.0 * t)
    )
    drone *= 0.83 + 0.12 * np.sin(2.0 * np.pi * 2.0 * t / LOOP_SECONDS)
    rng = np.random.default_rng(16304)
    wind = band_noise(len(t), rng, 55.0, 650.0)
    drone += 0.012 * wind * (0.8 + 0.2 * np.sin(2.0 * np.pi * t / LOOP_SECONDS))
    percussion = np.zeros_like(t)
    # Every fourth second: deep, sparse temple drum. Its tail wraps across the seam.
    for index in range(12):
        since_hit = (t - (index * 4.0 + 0.6)) % LOOP_SECONDS
        phase = 2.0 * np.pi * (52.0 * since_hit + 31.0 * (1.0 - np.exp(-11.0 * since_hit)) / 11.0)
        drum = np.sin(phase) * np.exp(-since_hit / 0.19)
        drum *= np.minimum(since_hit / 0.003, 1.0)
        drum += 0.035 * wind * np.exp(-since_hit / 0.026)
        percussion += drum * (0.24 if index % 3 == 0 else 0.16)
    signal = drone + percussion
    path = write_wav(
        PROJECT_ROOT / "assets/audio/bgm/uruk_rear_gate.wav",
        signal,
        fade_seconds=0.0,
    )
    normalized = signal / np.max(np.abs(signal))
    # Compare the seam to a normal adjacent sample step; periodic sine/noise has no cut.
    seam = abs(normalized[0] - normalized[-1])
    print(f"Generated {path.name}: {LOOP_SECONDS:g} s, {SAMPLE_RATE} Hz, seamless periodic loop; seam step={seam:.6f}.")
    stage2 = json.loads((PROJECT_ROOT / "data/audio_stage2.json").read_text(encoding="utf-8"))
    for spec in stage2["bgm"]:
        make_stage2_bgm(spec)


if __name__ == "__main__":
    main()
