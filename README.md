These files for the Z80-MBC2 replaces CPM 2.2 CCP and BDOS with ZCPR1-D&J and ZSDOS 1.1.  
The minimum required files needed from this respository are "DS0N00.DSK" and "Z80_MBC2_ZCPM22.bin".
To install:  First save the original files "cpm22.bin" and "DS0N00.DSK" on the Z80-MBC2 microSD card.
Copy new "DSN00.DSK" to the Z80-MBC2 microSD card.  This contains the original Z80-MBC2 files with some ZSDOS files such as "copy.com".  DSN00 also contains the ZCPR and ZSDOS binaries on "Track 0".
Copy "Z80_MBC2_ZCPM.bin" to the microSD card and rename it to 'cpm22.bin".
Upon boot you should see the following: 
"Z80-MBC2 CP/M BIOS - S030818-R120923"
"ZCPR1-D&J 2021, ZSDOS1.1 (c) 1987 Cotrill & Bower"
Note:  Real Time Clock (RTC) functionality was not enabled.  RTC could be possible with the use of the QPM bios (see Z80-MBC2-QPM) repository
