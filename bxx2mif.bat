copy /b rom\bktests\boot.bxx .
bin2mif-e.exe boot.bxx boot.mif 16
C:\altera\90\quartus\bin\quartus_cdb  bk0010 -c bk0010 --update_mif
C:\altera\90\quartus\bin\quartus_asm --read_settings_files=on --write_settings_files=off bk0010 -c bk0010
C:\altera\90\quartus\bin\quartus_pgm -c USB-Blaster reports/bk0010.cdf