#@echo off

if "%1"== "" goto message

if not exist %1 goto nofile

mzf2wav %1 %1.wav

wavext 1 22050 8 %1.wav

tapeload %1.new.wav

copy /b header.dat+out.dat %~n1.mzt

del %1.wav %1.new.wav header.dat out.dat

goto end

: nofile

echo Usage : mzf2mzt [filename]

goto end

: message

echo no arg

: end