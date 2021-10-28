C:\Users\death\Documents\C65\acme\acme -v9 --cpu m65 -l example.csv example.asm
pause
C:\Users\death\Documents\C65\GTK3VICE-3.5-win64\bin\c1541 -attach tremor.d81 -delete example -write example.prg example -list
call start /b "xemu" "c:\program files\xemu\xmega65" -8 tremor.d81
