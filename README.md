# CAS-Audio-Player
A very simple audio player built in Delphi that runs ASIO drivers and decodes input files using ffmpeg.
You can load multiple audio files and see their waveform.
It's possible to edit the playlist, moving tracks up and down and removing them.

![](docs/current.png)  

# How to compile
- Checkout the last synced version ([v1.1](https://github.com/ah-jr/CAS-Audio-Player/commit/042628ab6d31a41984d9c0c19cdcf10b50915118)). This is important for the dependencies to work properly.
- Clone [CAS-Engine v1.7](https://github.com/ah-jr/CAS-Engine) inside "deps\CasAudioEngine\".
- Clone [TAcrylicForm v1.4](https://github.com/ah-jr/TAcrylicForm) inside "deps\TAcrylicForm\".
- Open "src\CAS_AudioPlayer" and compile.
