$Message = "Testing Message"
[Reflection.Assembly]::LoadWithPartialName('System.Speech')
$object = New-Object System.Speech.Synthesis.SpeechSynthesizer
$object.SetOutputToDefaultAudioDevice()
$object.Speak("$Message")