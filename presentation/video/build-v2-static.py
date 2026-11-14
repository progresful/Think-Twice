"""Build video.mp4 from the simulator recording: one clip per script line, a spoken track and burnt-in captions.
Usage: python3 build.py      (run inside presentation/video; clips come from raw/)
The voice is Kokoro-82M (see tts.py)."""
import json, subprocess, sys, os

CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.path.join(HERE, 'tmp'); os.makedirs(TMP, exist_ok=True)

# headline (HTML), caption (shown and in the transcript), voice (spelled for speech), source (seconds into RAW, or an image)
SEGMENTS = [
 dict(headline='Cause of death: <b>brunch.</b>',
      caption='Your salary died on Sunday. Cause of death: brunch.',
      voice='Your salary died on Sunday. Cause of death: brunch.',
      file='raw/cfr-a-dash.mp4', src=0.0),
 dict(headline='Banking stops at <b>statements.</b>',
      caption='Ten restaurant payments in one month. 238,84 €. And your bank just shows a list.',
      voice='Ten restaurant payments in one month. Two hundred and thirty-eight euros. And your bank just shows a list.',
      file='raw/cfr-a-dash.mp4', src=2.6),
 dict(headline='Talk with <b>your own money.</b>',
      caption='Think Twice lets you talk with your own money. Ask anything, in plain words.',
      voice='Think Twice lets you talk with your own money. Ask anything, in plain words.',
      file='raw/cfr-b-taxi.mp4', src=10.6),
 dict(headline='Three baskets. <b>One number.</b>',
      caption='Every euro lands in one of three baskets: fixed, irregular or everyday. One number shows what is safe to spend this week.',
      voice='Every euro lands in one of three baskets: fixed, irregular, or everyday. One number shows what is safe to spend this week.',
      file='raw/cfr-d-lock.mp4', src=76.0),
 dict(headline='Ask <b>what if.</b>',
      caption='What would a cut save? Ask, then drag the slider.',
      voice='What would a cut save? Ask, then drag the slider.',
      file='raw/cfr-c-whatif.mp4', src=41.6),
 dict(headline='Then <b>it acts.</b>',
      caption='Then it acts. Past your own limit, the next payment is locked.',
      voice='Then, it acts. Past your own limit, the next payment is locked.',
      file='raw/cfr-d-lock.mp4', src=7.0),
 dict(headline='Earn it, or <b>keep the money.</b>',
      caption='Unlock it with a short game. Or skip, and keep the money.',
      voice='Unlock it with a short game. Or skip, and keep the money.',
      file='raw/cfr-d-lock.mp4', src=55.0),
 dict(headline='Code does the maths. <b>The model talks.</b>',
      caption='Every figure is computed by code, with 22 passing tests. The AI only puts it into words.',
      voice='Every figure is computed by code, with twenty-two passing tests. The AI only puts it into words.',
      file='raw/cfr-c-whatif.mp4', src=11.5),
 dict(headline='Built for <b>S-mobiili.</b>',
      caption='Built on S-Bank\'s dataset, for the bank\'s own app. In this demo the bank and the card are simulated.',
      voice='Built on S-Bank\'s dataset, for the bank\'s own app. In this demo, the bank and the card are simulated.',
      file='raw/cfr-a-dash.mp4', src=5.5),
 dict(headline='Think Twice.<br><b>Talk with your money. Then keep it.</b>',
      caption='Think Twice. Talk with your money. Then keep it.',
      voice='Think Twice. Talk with your money. Then keep it.', src='../deck/assets/welcome-new.png'),
]
VOICE, SPEED = 'af_heart', 1.0      # Kokoro-82M; af_heart is the top-graded voice in the model's own voice list
PAUSE = 0.35

def run(*a): subprocess.run(a, check=True, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=180)
def dur(p): return float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', p]))

open(os.path.join(HERE, 'segments.js'), 'w').write('const SEGMENTS = ' + json.dumps(SEGMENTS, ensure_ascii=False) + ';\n')
json.dump([x['voice'] for x in SEGMENTS], open(f'{TMP}/lines.json', 'w', encoding='utf-8'), ensure_ascii=False)
subprocess.run(['uv', 'run', '--python', '3.12', '--with', 'kokoro', '--with', 'soundfile', '--with', 'pip', os.path.join(HERE, 'tts.py'),
                VOICE, str(SPEED), f'{TMP}/voice', f'{TMP}/lines.json'], check=True, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
               stderr=subprocess.DEVNULL, timeout=900)
clips, t, cues = [], 0.0, []
for i, s in enumerate(SEGMENTS):
    aiff, bg, out = f'{TMP}/voice/v{i}.wav', f'{TMP}/bg{i}.png', f'{TMP}/seg{i}.mp4'
    d = round(dur(aiff) + PAUSE, 2)
    run(CHROME, '--headless', f'--user-data-dir={TMP}/chrome', '--hide-scrollbars', '--window-size=1920,1080', f'--screenshot={bg}',
        f'file://{HERE}/frames.html?i={i}')
    still = isinstance(s['src'], str)
    src = ['-loop', '1', '-i', os.path.join(HERE, s['src'])] if still else ['-ss', str(s['src']), '-i', os.path.join(HERE, s['file'])]
    run('ffmpeg', '-y', '-loop', '1', '-i', bg, *src, '-i', aiff, '-filter_complex',
        f'[1:v]fps=30,scale=442:960:flags=lanczos,tpad=stop_mode=clone:stop_duration=30[p];[0:v][p]overlay=1300:60,fade=t=in:st=0:d=0.18,format=yuv420p[v];'
        f'[2:a]aresample=48000,loudnorm=I=-16:TP=-1.5:LRA=11,apad[a]',
        '-map', '[v]', '-map', '[a]', '-t', str(d), '-r', '30', '-c:v', 'libx264', '-crf', '20', '-c:a', 'aac', '-b:a', '160k', out)
    clips.append(out); cues.append((t, t + d - 0.1, s['caption'])); t += d

open(os.path.join(HERE, 'clips.txt'), 'w').write(''.join(f"file '{c}'\n" for c in clips))
run('ffmpeg', '-y', '-f', 'concat', '-safe', '0', '-i', os.path.join(HERE, 'clips.txt'), '-c:v', 'libx264', '-crf', '20',
    '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', os.path.join(HERE, 'video.mp4'))
run('ffmpeg', '-y', '-i', os.path.join(HERE, 'video.mp4'), '-vn', '-c:a', 'copy', os.path.join(HERE, 'voiceover.m4a'))

ts = lambda x: '%02d:%02d:%02d,%03d' % (x // 3600, x % 3600 // 60, x % 60, round(x % 1 * 1000) % 1000)
open(os.path.join(HERE, 'transcript.srt'), 'w').write(''.join(f'{n}\n{ts(a)} --> {ts(b)}\n{c}\n\n' for n, (a, b, c) in enumerate(cues, 1)))
open(os.path.join(HERE, 'transcript.md'), 'w').write('# Think Twice: video transcript\n\n' + '\n\n'.join(c for _, _, c in cues) + '\n')
words = sum(len(s['voice'].split()) for s in SEGMENTS)
rows = ''.join(f"| {a:.0f}–{b + 0.1:.0f} s | {s['voice']} | {('Still: Welcome screen' if isinstance(s['src'], str) else 'App recording ' + s['file'] + ' from ' + str(s['src']) + ' s')}; headline \"{s['headline'].replace('<br>', ' ').replace('<b>', '').replace('</b>', '')}\" |\n"
               for (a, b, _), s in zip(cues, SEGMENTS))
open(os.path.join(HERE, 'script.md'), 'w').write(
    f'# Think Twice: video script\n\n{words} spoken words, {t:.1f} seconds. Voice: Kokoro-82M, voice `{VOICE}`, speed {SPEED}. '
    'No music. Captions are burnt into the picture and saved in `transcript.srt`.\n\n'
    '| Time | Voiceover | Visual |\n|---|---|---|\n' + rows)
print(f'total {t:.1f}s, {words} words')
