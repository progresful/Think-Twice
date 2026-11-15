"""Mix the voice and the sound effects into one track. Usage: uv run --with numpy --with soundfile mix.py <total_seconds>"""
import json, sys, numpy as np, soundfile as sf
SR, total = 48000, float(sys.argv[1])
T = json.loads(open('timing.js').read()[8:-2]); E = json.load(open('events.json')); L = json.load(open('lines.json'))
GAIN = {'whoosh': .30, 'swoosh': .42, 'click': .34, 'tick': .20, 'pop': .5, 'hit': .42, 'ding': .55, 'beep': .5, 'decline': .5, 'win': .45, 'tension': .16}
def load(p):
    a, sr = sf.read(p, dtype='float32'); a = a if a.ndim == 1 else a.mean(1); assert sr == SR, p
    return a
def norm(a): return a / max(1e-6, np.abs(a).max())
voice, fx = np.zeros(int(total * SR) + SR), np.zeros(int(total * SR) + SR)
def put(buf, a, t):
    i = max(0, int(t * SR)); a = a[:len(buf) - i]; buf[i:i + len(a)] += a
for i, x in enumerate(T):
    if L[i]: put(voice, norm(load(f'voice/t{i}.wav')) * .9, x['voice'])
S = {k: norm(load(f'sfx/{k}.wav')) for k in GAIN}
for e in E:
    t, name = e[0], e[1]; a = S[name]
    if name == 'pop' and len(e) > 2:                      # each rung a semitone-and-a-half higher
        r = 2 ** (e[2] * 1.5 / 12); a = np.interp(np.arange(0, len(a), r), np.arange(len(a)), a)
    if name == 'tension':                                 # under the hold scene only, swelling
        n = int(e[3] * SR); a = np.resize(a, n) * np.linspace(.35, 1, n); a[-int(.15 * SR):] *= np.linspace(1, 0, int(.15 * SR))
    CAP = {'tick': .09, 'pop': .22, 'click': .14, 'beep': .3, 'decline': .55, 'ding': .8, 'win': 1.2}
    if name in CAP: n = int(CAP[name] * SR); a = a[:n] * np.linspace(1, 0, len(a[:n])) ** .6
    if name in ('hit', 'swoosh', 'whoosh'): a = a[:int(.7 * SR)] * np.linspace(1, 0, min(len(a), int(.7 * SR))) ** .5
    put(fx, a * GAIN[name], t)
# duck the effects a little under the voice
env = np.convolve(np.abs(voice), np.ones(2400) / 2400, 'same'); fx *= 1 - .45 * np.clip(env / .08, 0, 1)
m = (voice + fx)[:int(total * SR)]; m = np.tanh(m * 1.1) / np.tanh(1.1)
sf.write('mix.wav', np.stack([m, m], 1), SR); print('events', len(E), 'peak', round(float(np.abs(m).max()), 2))
