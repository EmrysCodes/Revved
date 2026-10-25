# Free, local placeholder performance. No service, keys, downloads or payments.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Speech
$storyRoot=Split-Path $PSScriptRoot -Parent
$scriptData=Get-Content -LiteralPath (Join-Path $storyRoot 'story\last_light.json') -Raw | ConvertFrom-Json
$audioTarget=Join-Path $storyRoot 'assets\audio\story'
New-Item -ItemType Directory -Path $audioTarget -Force | Out-Null
$storyVoice=New-Object System.Speech.Synthesis.SpeechSynthesizer
$installedStoryVoices=$storyVoice.GetInstalledVoices()
if($installedStoryVoices.Count -eq 0){$storyVoice.Dispose();throw 'No offline speech voice is available in this PowerShell runtime. Run with the PowerShell runtime used to generate this project, or keep the already rendered WAV files.'}
$voiceName=$installedStoryVoices[0].VoiceInfo.Name
$storyVoice.SelectVoice($voiceName)
try {
 foreach($entry in $scriptData.scenes.PSObject.Properties) {
  $sceneValue=$entry.Value
  for($lineIndex=0;$lineIndex -lt $sceneValue.lines.Count;$lineIndex++) {
   $storyLine=$sceneValue.lines[$lineIndex]
   $castMember=$scriptData.cast.PSObject.Properties[$storyLine.speaker].Value
   $storyVoice.Rate=[int]$castMember.rate
   $storyVoice.Volume=100
   $audioFile=Join-Path $audioTarget ('{0}_{1:00}.wav' -f $sceneValue.id,$lineIndex)
   # Personal names remain in subtitles; a neutral address avoids a spoken name mismatch.
   $spokenText=$storyLine.text.Replace(', {driver}', '').Replace('{driver}', 'driver')
   $storyVoice.SetOutputToWaveFile($audioFile)
   $storyVoice.Speak($spokenText)
   $storyVoice.SetOutputToNull()
  }
 }
} finally { $storyVoice.Dispose() }
@{
 provider='Windows offline System.Speech'; voice=$voiceName
 description='Synthetic prototype dialogue; all characters use the available local voice with rate variation. Original Last Light screenplay. No actor imitation.'
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $audioTarget 'voice-manifest.json') -Encoding utf8
Write-Output 'Offline story voice generation complete.'
