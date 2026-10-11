"""Shared, deterministic PCM synthesis helpers. No external audio tools needed."""
from pathlib import Path
import wave

import numpy as np

SAMPLE_RATE = 44100
PEAK_LIMIT = 10.0 ** (-3.0 / 20.0)
PROJECT_ROOT = Path(__file__).resolve().parents[1]


def timeline(seconds):
    return np.arange(round(seconds * SAMPLE_RATE), dtype=np.float64) / SAMPLE_RATE


def band_noise(length, rng, low=0.0, high=20000.0):
    """FFT band-limit seeded noise, keeping the periodic waveform phase intact."""
    bins = np.fft.rfftfreq(length, 1.0 / SAMPLE_RATE)
    spectrum = np.fft.rfft(rng.standard_normal(length))
    spectrum[(bins < low) | (bins > high)] = 0.0
    result = np.fft.irfft(spectrum, n=length)
    rms = np.sqrt(np.mean(result * result))
    return result / max(rms, 1e-12)


def envelope(t, attack=0.002, decay=0.055, duration=None):
    env = np.minimum(t / attack, 1.0) * np.exp(-t / decay)
    if duration is not None:
        env *= np.clip((duration - t) / 0.008, 0.0, 1.0)
    return env


def write_wav(path, samples, normalize=True, fade_seconds=0.004):
    """Write mono 16-bit PCM, optionally keeping an already-periodic loop intact."""
    samples = np.asarray(samples, dtype=np.float64).copy()
    if fade_seconds:
        edge = min(round(fade_seconds * SAMPLE_RATE), len(samples) // 2)
        samples[:edge] *= np.linspace(0.0, 1.0, edge)
        samples[-edge:] *= np.linspace(1.0, 0.0, edge)
    peak = np.max(np.abs(samples))
    if peak > 0.0:
        gain = PEAK_LIMIT / peak
        if normalize or gain < 1.0:
            samples *= gain
    pcm = np.rint(np.clip(samples, -PEAK_LIMIT, PEAK_LIMIT) * 32767.0).astype("<i2")
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pcm.tobytes())
    from convert_audio_ogg import convert
    output = convert(path, archive=True)
    return output
