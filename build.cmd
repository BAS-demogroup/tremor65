d:\c64\acme\acme -v9 --cpu m65 -l example.labels example.asm
pause
d:\c64\GTK3VICE-3.5-win64\bin\c1541 -attach tremor.d81 -delete tremor.d81 example -write example.prg example -list
call start /b "xemu" "c:\program files\xemu\xmega65" -8 tremor.d81
