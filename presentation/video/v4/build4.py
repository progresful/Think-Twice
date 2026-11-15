"""Build the storyboard film: timing from the voice, frames from film.html, then picture + voice.
Usage: python3 build4.py [timing|render|mux]   (no argument runs all three)"""
import json, os, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__)); os.chdir(HERE)
LINES = json.load(open('lines.json'))
MIN = {5: 1.9}          # scenes that need time for their animation
LEAD = {9: 0.32}                                   # voice starts after the black beat
TAIL = {0: 0.3, 15: 0.6}
def dur(p): return float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', p]))
def run(*a): subprocess.run(a, check=True, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
step = sys.argv[1] if len(sys.argv) > 1 else 'all'
T, t = [], 0.0
for i in range(len(LINES)):
    v = dur(f'voice/t{i}.wav') if LINES[i] else 0; lead = LEAD.get(i, 0.05)
    d = round(max(MIN.get(i, 0), lead + v + TAIL.get(i, 0.06)) * 30) / 30
    T.append({'start': round(t, 4), 'dur': d, 'voice': round(t + lead, 4), 'vlen': round(v, 2)}); t += d
total = t
open('timing.js', 'w').write('const T=' + json.dumps(T) + ';\n')
print('total', round(total, 2), 's'); [print(i, x['start'], x['dur'], x['vlen'], LINES[i][:40]) for i, x in enumerate(T)]
if step in ('all', 'render'):
    subprocess.run(['uv', 'run', '--python', '3.12', '--with', 'websockets', 'render4.py', str(total), 'frames'], check=True)
if step in ('all', 'render', 'mux'):
    if step == 'mux': subprocess.run(['uv', 'run', '-q', '--python', '3.12', '--with', 'websockets', 'render4.py', str(total), '-'], check=True)
    subprocess.run(['uv', 'run', '-q', '--python', '3.12', '--with', 'numpy', '--with', 'soundfile', 'mix.py', str(total)], check=True)
    run('ffmpeg', '-y', '-framerate', '30', '-i', 'frames/f%05d.png', '-i', 'mix.wav', '-vf', 'scale=in_range=pc:out_range=tv,format=yuv420p', '-color_range', 'tv',
        '-c:v', 'libx264', '-crf', '15', '-profile:v', 'high', '-level', '4.1', '-af', 'loudnorm=I=-15:TP=-1.5', '-c:a', 'aac', '-b:a', '192k', '-ac', '2', '-ar', '48000',
        '-t', str(total), '-movflags', '+faststart', '../video-v6.mp4')
    srt = []
    for i, x in enumerate(T):
        if not LINES[i]: continue
        f = lambda s: '%02d:%02d:%06.3f' % (s // 3600, s % 3600 // 60, s % 60)
        srt.append(f"{i+1}\n{f(x['voice']).replace('.', ',')} --> {f(x['voice']+x['vlen']).replace('.', ',')}\n{LINES[i]}\n")
    open('../transcript-v6.srt', 'w').write('\n'.join(srt))
    print('wrote ../video-v6.mp4', round(dur('../video-v6.mp4'), 2), 's')
