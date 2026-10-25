"""Synthesize an original restrained night-drive menu loop; no sampled recordings."""
from pathlib import Path
import sys, wave
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'2026-10-18/referenced-chatgpt-conversation-this-is-an/work/geo_vendor'))
import numpy as np
root=Path(__file__).resolve().parents[1]
rate=22050; beat=.6; bars=16; duration=beat*4*bars
t=np.arange(round(rate*duration))/rate
sound=np.zeros_like(t)
def hz(note):return 440*2**((note-69)/12)
for section,chord in enumerate([[52,59,62,66],[48,55,59,64],[45,52,55,59],[47,54,57,64]]):
 start=section*9.6; local=t-start; mask=(local>=0)&(local<9.6); age=local[mask]
 envelope=np.minimum(1,age/1.2)*np.minimum(1,(9.6-age)/1.6)
 for note in chord:sound[mask]+=.027*envelope*np.sin(2*np.pi*hz(note)*age)*(1+.15*np.sin(2*np.pi*.18*age))
 for pulse in range(16):
  clock=local-pulse*beat; part=(clock>=0)&(clock<.28); a=clock[part]
  sound[part]+=.07*np.sin(2*np.pi*hz(chord[0]-12)*a)*np.exp(-a*18)
rng=np.random.default_rng(3407)
for onset in np.arange(0,duration,beat):
 age=t-onset; part=(age>=0)&(age<.13); a=age[part]
 sound[part]+=.07*np.sin(2*np.pi*(44*a+1.8*(1-np.exp(-a*40))))*np.exp(-a*30)
 if round(onset/beat)%2:
  sound[part]+=.018*rng.uniform(-1,1,a.shape)*np.exp(-a*55)
sound*=np.minimum(1,t/.05)*np.minimum(1,(duration-t)/.05)
left=sound; right=np.roll(sound,77)*.96
audio=np.column_stack((left,right)); audio=np.clip(audio,-.95,.95)
target=root/'assets/audio/interface/last_light_menu.wav'
with wave.open(str(target),'wb') as out:
 out.setnchannels(2);out.setsampwidth(2);out.setframerate(rate);out.writeframes((audio*32767).astype('<i2').tobytes())
print(f'Original menu loop: {duration:.1f}s / {target.stat().st_size} bytes')
