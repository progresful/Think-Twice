"""Speak lines.json with ElevenLabs, then trim the silence off both ends of each clip.
Usage: ELEVEN_API_KEY=... python3 el_voice.py <voice_id> [speed]   (the key is read from the environment, never stored)"""
import json, os, subprocess, sys, urllib.request
key, voice, speed = os.environ['ELEVEN_API_KEY'], sys.argv[1], float(sys.argv[2]) if len(sys.argv) > 2 else 1.1
lines = json.load(open('lines.json')); os.makedirs('voice', exist_ok=True)
for i, text in enumerate(lines):
    if not text: continue
    body = {'text': text, 'model_id': 'eleven_multilingual_v2',
            'voice_settings': {'stability': 0.4, 'similarity_boost': 0.8, 'style': 0.35, 'use_speaker_boost': True, 'speed': speed}}
    if i > 0 and lines[i-1]: body['previous_text'] = lines[i-1]
    if i + 1 < len(lines) and lines[i+1]: body['next_text'] = lines[i+1]
    req = urllib.request.Request(f'https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128',
                                 data=json.dumps(body).encode(), headers={'xi-api-key': key, 'Content-Type': 'application/json'})
    open(f'voice/raw{i}.mp3', 'wb').write(urllib.request.urlopen(req, timeout=120).read())
    trim = 'silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.02'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f'voice/raw{i}.mp3', '-af', f'{trim},areverse,{trim},areverse', '-ar', '48000', '-ac', '1', f'voice/v{i}.wav'], check=True)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f'voice/v{i}.wav', '-af', 'silenceremove=stop_periods=-1:stop_duration=0.24:stop_silence=0.13:stop_threshold=-42dB', f'voice/t{i}.wav'], check=True)
    d = float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f'voice/t{i}.wav']))
    print(i, round(d, 2), text[:50])
