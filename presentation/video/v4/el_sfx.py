"""Generate the film's sound effects with ElevenLabs sound generation and trim them.
Usage: ELEVEN_API_KEY=... python3 el_sfx.py [name ...]"""
import json, os, subprocess, sys, urllib.request
key = os.environ['ELEVEN_API_KEY']; os.makedirs('sfx', exist_ok=True)
S = {'whoosh': ('short fast airy whoosh, clean swish transition, dry', 0.6),
     'swoosh': ('big smooth cinematic whoosh sweeping left to right, clean, no impact', 1.0),
     'click': ('single soft crisp user interface click, dry, very short', 0.5),
     'tick': ('single tiny dry tick, like a soft mouse click, very short', 0.5),
     'pop': ('single soft bubbly pop, bright user interface blip, very short', 0.5),
     'hit': ('deep tight cinematic bass impact thud, short, dry', 1.0),
     'ding': ('bright short smartphone notification chime, two notes', 1.0),
     'beep': ('single contactless payment terminal beep, short, clean', 0.5),
     'decline': ('payment terminal declined error tone, two low buzzing beeps', 0.9),
     'win': ('short bright success chime with sparkle, positive, clean', 1.5),
     'tension': ('low tense pulsing synth drone slowly building, heartbeat, no melody', 6.0)}
for name in (sys.argv[1:] or S):
    text, dur = S[name]
    req = urllib.request.Request('https://api.elevenlabs.io/v1/sound-generation', data=json.dumps({'text': text, 'duration_seconds': dur, 'prompt_influence': 0.6}).encode(),
                                 headers={'xi-api-key': key, 'Content-Type': 'application/json'})
    open(f'sfx/raw-{name}.mp3', 'wb').write(urllib.request.urlopen(req, timeout=180).read())
    trim = 'silenceremove=start_periods=1:start_threshold=-40dB:start_silence=0.005'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f'sfx/raw-{name}.mp3', '-af', trim if name == 'tension' else f'{trim},areverse,{trim},areverse', '-ar', '48000', '-ac', '1', f'sfx/{name}.wav'], check=True)
    d = float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f'sfx/{name}.wav']))
    print(name, round(d, 2))
