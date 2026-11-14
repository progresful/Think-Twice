"""Speak lines with Kokoro-82M. Usage:
  uv run --python 3.12 --with kokoro --with soundfile --with pip tts.py <voice> <speed> <out_dir> <lines.json>
lines.json is a list of strings; writes <out_dir>/v0.wav, v1.wav, ... (24 kHz mono)."""
import sys, json, os
import numpy as np, soundfile as sf
from kokoro import KPipeline

voice, speed, out, lines = sys.argv[1], float(sys.argv[2]), sys.argv[3], json.load(open(sys.argv[4], encoding='utf-8'))
os.makedirs(out, exist_ok=True)
pipe = KPipeline(lang_code='b' if voice[0] == 'b' else 'a', repo_id='hexgrad/Kokoro-82M')
for i, text in enumerate(lines):
    if not text: continue
    parts = [np.asarray(a) for _, _, a in pipe(text, voice=voice, speed=speed)]
    audio = np.concatenate(parts)
    sf.write(os.path.join(out, f'v{i}.wav'), audio, 24000)
    print(i, round(len(audio) / 24000, 2), 's')
