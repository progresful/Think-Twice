"""Build video.mp4: Kokoro voice per line, animated titles rendered from anim.html, app recordings shown through a phone-shaped
hole, captions on screen. Usage: python3 build.py      (run inside presentation/video; clips come from raw/)"""
import json, subprocess, os

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.path.join(HERE, 'tmp'); os.makedirs(TMP, exist_ok=True)
SIDE = dict(x=1290, y=60, w=442, h=960, r=42)            # whole phone screen on the right
ZOOM = dict(x=1010, y=90, w=800, h=900, r=56)            # close-up of the unlock counter
ZCROP = (560, 630, 35, 426)                              # the part of a 630x1368 clip shown in the close-up

# lines: [text, when it enters as a share of the segment]; *word* is lime. big: a number that counts up.
SEGMENTS = [
 dict(layout='full', tomb=True, ghost='R.I.P.', lines=[['Rest in peace,', 0], ['*paycheck.*', 0.2], ['You were so young.', 0.47], ['*Nine days.*', 0.78]],
      caption='Rest in peace, paycheck. You were so young. Nine days.',
      voice='Rest in peace, paycheck. You were so young. Nine days.'),
 dict(layout='full', ghost='1 IN 3', dots=True, big=dict(to=30, suffix=' %', at=0.0, first=True), lines=[["of Europeans can't cover", 0.3], ['*one surprise bill.*', 0.5]],
      source='Eurostat, EU-SILC 2024: 30.0 % of people in the EU could not face an unexpected financial expense.',
      caption="Almost one in three Europeans can't cover a single unexpected bill.",
      voice="Almost one in three Europeans can't cover a single unexpected bill."),
 dict(layout='side', ghost='238 €', lines=[['Not the rent.', 0], ['*10 small payments.*', 0.3]], big=dict(to=2866, suffix=' €', label='a year', at=0.62),
      source='One customer in S-Bank\'s synthetic dataset: 238,84 € on restaurants in August, times twelve.',
      caption="It's rarely the rent. Ten small payments: 238 € a month, almost 2 900 € a year.",
      voice="And it's rarely the rent. It's this. Ten small payments. Two hundred and thirty-eight euros a month. Almost twenty-nine hundred euros a year.",
      file='raw/cfr-a2-dash.mp4', src=1.2),
 dict(layout='side', ghost='LOCKED', lines=[['So we do', 0], ['something *rude.*', 0.1], ['*We lock your card.*', 0.55]],
      caption='So Think Twice does something rude. Past your own limit, it locks your card.',
      voice='So Think Twice does something rude. Past your own limit, it locks your card.',
      file='raw/cfr-d-lock.mp4', src=7.0),
 dict(layout='zoom', lines=[['Want it back?', 0], ['*Fifty taps.*', 0.3]], ripple=True,
      caption="Want it back? Fifty taps. Go on. We'll wait.",
      voice="Want it back? Fifty taps. Go on. We'll wait.",
      file='raw/cfr-d-lock.mp4', src=52.6),
 dict(layout='zoom', noslide=True, nowipe=True, ghost='SAVED', lines=[['Or skip.', 0], ['*Keep the money.*', 0.35]],
      caption='Or skip. And keep the money.',
      voice='Or skip. And keep the money.',
      file='raw/cfr-d-lock.mp4', src=57.6),
 dict(layout='full', ghost='BOLD', lines=[['A report is', 0.12], ['easy to ignore.', 0.2], ['*A locked card*', 0.45], ["*isn't.*", 0.55]],
      source='A design choice. Not yet tested with users.',
      caption="Why so bold? A report is easy to ignore. A locked card isn't.",
      voice="Why so bold? Because a report is easy to ignore. A locked card isn't. The pause comes at the till, when it still matters."),
 dict(layout='side', ghost='ASK', lines=[['Then ask', 0], ['your money', 0.08], ['*anything.*', 0.45]],
      caption='And it explains itself. Ask your own money anything, in plain words.',
      voice='And it explains itself. Ask your own money anything, in plain words.',
      file='raw/cfr-b-taxi.mp4', src=10.6),
 dict(layout='side', ghost='WHAT IF', lines=[['Three baskets.', 0], ['One safe number.', 0.33], ['*Drag the what-if.*', 0.66]],
      caption="Three baskets. One number that says what's safe this week. Every what-if is a slider.",
      voice="Three baskets show where it really goes. One number says what's safe this week. And every what-if is a slider.",
      file='raw/cfr-c-whatif.mp4', src=41.0),
 dict(layout='side', lines=[['Code does', 0], ['the maths.', 0.06], ['*Built for*', 0.45], ['*S-mobiili.*', 0.52]],
      source='22 unit tests pass on the money logic. Bank, card and decline are simulated in this demo.',
      caption="Every figure is computed by code, on S-Bank's data. Bank and card are simulated here.",
      voice="Every figure is computed by code, on S-Bank's data, for the bank's own app. In this demo, the bank and the card are simulated.",
      file='raw/cfr-a2-dash.mp4', src=0.0),
 dict(layout='full', icon=True, ghost='THINK TWICE', lines=[['Think Twice.', 0], ['*Talk with your money.*', 0.3], ['*Then keep it.*', 0.6]],
      caption='Think Twice. Talk with your money. Then keep it.',
      voice='Think Twice. Talk with your money. Then keep it.'),
]
VOICE, SPEED, PAUSE = 'af_heart', 1.08, 0.28      # Kokoro-82M

def run(*a, t=900): subprocess.run(a, check=True, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=t)
def dur(p): return float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', p]))

# 1. voice
json.dump([s['voice'] for s in SEGMENTS], open(f'{TMP}/lines.json', 'w', encoding='utf-8'), ensure_ascii=False)
run('uv', 'run', '--python', '3.12', '--with', 'kokoro', '--with', 'soundfile', '--with', 'pip', os.path.join(HERE, 'tts.py'),
    VOICE, str(SPEED), f'{TMP}/voice', f'{TMP}/lines.json')
t = 0.0
for i, s in enumerate(SEGMENTS):
    s['start'] = round(t, 3); s['dur'] = round(round((dur(f'{TMP}/voice/v{i}.wav') + PAUSE) * 30) / 30, 4); t = round(t + s['dur'], 4)
    s['hole'] = {'side': SIDE, 'zoom': ZOOM}.get(s['layout'])
    if s.get('ripple'): s['ripple'] = dict(x=ZOOM['x'] + (315 - ZCROP[2]) * ZOOM['w'] / ZCROP[0], y=ZOOM['y'] + (741 - ZCROP[3]) * ZOOM['h'] / ZCROP[1])
total = t
open(os.path.join(HERE, 'timeline.js'), 'w').write('const TIMELINE = ' + json.dumps(SEGMENTS, ensure_ascii=False) + ';\n')

# 2. animated titles, one transparent PNG per frame
if not os.environ.get('KEEP_FRAMES'):      # KEEP_FRAMES=1 reuses tmp/frames, after re-rendering a range with render.py
    run('rm', '-rf', f'{TMP}/frames')
    run('uv', 'run', '--python', '3.12', '--with', 'websockets', os.path.join(HERE, 'render.py'), str(total), f'{TMP}/frames', t=1800)

# 3. picture, one segment at a time: black, the app recording (sliding in, shaking while tapped), then the titles on top
parts = []
for i, s in enumerate(SEGMENTS):
    n0, cnt, out = round(s['start'] * 30), round(s['dur'] * 30), f'{TMP}/part{i}.mp4'
    ins = ['-framerate', '30', '-start_number', str(n0), '-i', f'{TMP}/frames/f%05d.png']
    if 'file' in s:
        h = s['hole']; crop = f'crop={ZCROP[0]}:{ZCROP[1]}:{ZCROP[2]}:{ZCROP[3]},' if s['layout'] == 'zoom' else ''
        slide = '' if s.get('noslide') else "+900*pow(1-min(1\\,t/0.45)\\,3)"
        shake = "+9*sin(45*t)*gt(t\\,0.9)" if s.get('ripple') else ''
        ins += ['-ss', str(s['src']), '-i', os.path.join(HERE, s['file'])]
        fc = (f"color=c=black:s=1920x1080:r=30[b];[1:v]fps=30,{crop}scale={h['w']}:{h['h']}:flags=lanczos,tpad=stop_mode=clone:stop_duration=30[c];"
              f"[b][c]overlay=x='{h['x']}{slide}{shake}':y={h['y']}[m];[m][0:v]overlay=0:0,format=yuv420p[v]")
    else:
        fc = 'color=c=black:s=1920x1080:r=30[b];[b][0:v]overlay=0:0,format=yuv420p[v]'
    run('ffmpeg', '-y', *ins, '-filter_complex', fc, '-map', '[v]', '-frames:v', str(cnt), '-r', '30', '-c:v', 'libx264', '-crf', '18', out)
    parts.append(out)
open(f'{TMP}/parts.txt', 'w').write(''.join(f"file '{p}'\n" for p in parts))
run('ffmpeg', '-y', '-f', 'concat', '-safe', '0', '-i', f'{TMP}/parts.txt', '-c', 'copy', f'{TMP}/picture.mp4')

# 4. sound: each line padded to its segment, then one loudness pass
ain, afil = [], []
for i, s in enumerate(SEGMENTS):
    ain += ['-i', f'{TMP}/voice/v{i}.wav']; afil.append(f"[{i}:a]aresample=48000,apad,atrim=0:{s['dur']}[a{i}]")
afil.append(''.join(f'[a{i}]' for i in range(len(SEGMENTS))) + f'concat=n={len(SEGMENTS)}:v=0:a=1,loudnorm=I=-16:TP=-1.5:LRA=11[a]')
run('ffmpeg', '-y', *ain, '-filter_complex', ';'.join(afil), '-map', '[a]', '-c:a', 'aac', '-b:a', '192k', os.path.join(HERE, 'voiceover.m4a'))
run('ffmpeg', '-y', '-i', f'{TMP}/picture.mp4', '-i', os.path.join(HERE, 'voiceover.m4a'), '-c:v', 'copy', '-c:a', 'copy', '-shortest',
    '-movflags', '+faststart', os.path.join(HERE, 'video.mp4'))

# 5. transcript and script
ts = lambda x: '%02d:%02d:%02d,%03d' % (x // 3600, x % 3600 // 60, x % 60, round(x % 1 * 1000) % 1000)
open(os.path.join(HERE, 'transcript.srt'), 'w').write(''.join(
    f"{n}\n{ts(s['start'])} --> {ts(s['start'] + s['dur'] - 0.1)}\n{s['caption']}\n\n" for n, s in enumerate(SEGMENTS, 1)))
open(os.path.join(HERE, 'transcript.md'), 'w').write('# Think Twice: video transcript\n\n' + '\n\n'.join(s['voice'] for s in SEGMENTS) + '\n')
words = sum(len(s['voice'].split()) for s in SEGMENTS)
title = lambda s: ' '.join(l[0] for l in s['lines']).replace('*', '')
rows = ''.join(f"| {s['start']:.1f}–{s['start'] + s['dur']:.1f} s | {s['voice']} | Title \"{title(s)}\"; "
               f"{('app recording ' + s['file'] + ' from ' + str(s['src']) + ' s' + (', close-up' if s['layout'] == 'zoom' else '')) if 'file' in s else 'full-screen title'} |\n"
               for s in SEGMENTS)
open(os.path.join(HERE, 'script.md'), 'w').write(
    f'# Think Twice: video script\n\n{words} spoken words, {total:.1f} seconds. Voice: Kokoro-82M, voice `{VOICE}`, speed {SPEED}. '
    'No music. Titles are animated from `anim.html`; the caption line is on screen and in `transcript.srt`.\n\n'
    '| Time | Voiceover | Visual |\n|---|---|---|\n' + rows)
print(f'total {total:.1f}s, {words} words')
