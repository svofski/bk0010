![http://bk0010.googlecode.com/svn/trunk/doc/top.jpg](http://bk0010.googlecode.com/svn/trunk/doc/top.jpg)

The FPGA replica of Electronika [BK-0010](http://en.wikipedia.org/wiki/Elektronika_BK) home computer. `CAGLRCCC.R`! The current state implements a full BK0010.01 and supports loading of programs and overlays from SD card. Floppy is not yet supported.

The project so far is a testbed for debuging VM1, a simple 16-bit CPU with PDP-11 instruction set. VM1 CPU alone takes less than 1500 LEs in an Altera Cyclone II chip and runs at speeds up to 50 MHz. The primary goal of the VM1 subproject is to create a PDP-11 compatible CPU usable in modern environment as a part of an embedded system, rather than to create a pin-to-pin or cycle-accurate replacement for old CPUs.

VM1 design borrows at large from the brilliant design of [POP-11](http://shimizu-lab.dt.u-tokai.ac.jp/pop11.html) by Yoshihiro Iida, with ALU and instruction decoder code by Alex Freed. The control unit and datapath are written from scratch.

BK-0010 code is based on original code by Alex Freed. Original sources are available in the archive.

For licensing information see [README](http://bk0010.googlecode.com/hg/README)

[Start here](GettingStarted.md)


---

Копия компьютера [БК-0010](http://ru.wikipedia.org/wiki/%D0%91%D0%9A) в программируемой логике. `АБРРРВАЛ.Г`! Проект реализует БК0010.01 в полном объеме, загрузка программ и оверлеев осуществляется с SD-карты. Дисковод не поддерживается.

Этот проект служит отладочной платформой для отладки VM1, простого 16-битного процессора с системой команд PDP-11. Процессор занимает менее 1500 LE в Altera Cyclone II и работает на частотах до 50 МГц. Основная цель разработки VM1 -- создать совместимый с PDP-11 процессор, который был бы применим в современных условиях, а не в том, чтобы сделать копию, такт в такт повторяющую какую-то определенную версию системы.

Архитектура VM1 базируется на блестящем дизайне [POP-11](http://shimizu-lab.dt.u-tokai.ac.jp/pop11.html) г-на Йосихиро Ииды. АЛУ и дешифратор инструкций были написаны Алексом Фридом. Управляющий блок и datapath написаны с нуля специально для VM1.

Код БК-0010 базируется на оригинальной разработке Алекса Фрида, исходники которой доступны в архиве без изменений.

Информация о лицензиях находится в [README](http://bk0010.googlecode.com/hg/README).

[Начните с чтения руководства](http://code.google.com/p/bk0010/wiki/GettingStarted?wl=ru)