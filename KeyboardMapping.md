All regular keys are mapped to produce their ASCII values.

### Special Keys ###

|ПОВТ  |201|F1 | Repeat last key |
|:---------|:--|:--|:----------------|
|КТ    |003|F2 | Kill line |
| =|=> |231|F3 | Kill EOL |
| |<=  |026|Delete| Delete and shift left at cursor |
| |=>  |xxx|Insert| Insert space at cursor |
|ИНД СУ|202| F6 | Toggle display of control characters |
|БЛОК РЕД |204| F7 | Toggle edit keys function |
|ШАГ|220| F8 | Step execution |
|СБР   |xx|F11| Clear screen/Screen mode toggle |
|**СТОП**|xx|F12| Halt |
|АР2   |xx|Alt| Secondary Function Modifier |
|ЛАТ   |xxx|RShift| Switch to Latin |
|РУС   |xxx|Caps Lock| Switch to Cyrillic |
|СТР|xxx| ? | Lowercase |
|ЗАГЛ|xxx| ? | Uppercase |
|СУ|xxx| Ctrl | Control Modifier |
|ВС|023| Home | Cursor home |
|ТАБ   |011| Tab | Tab |


See also http://pdp-11.ru/mybk/doc/programmirovanie_bk0010.txt

For scan codes see: http://www.computer-engineering.org/ps2keyboard/scancodes2.html

### Joystick Emulation ###
BK keyboard controller doesn't allow more than one key to be correctly detected at a time. Joystick was the only way around this limitation and most games support joystick. It is emulated on PS/2 keyboard numeric pad. The keys are:
> : **<sub>num</sub>8, <sub>num</sub>2, <sub>num</sub>4, <sub>num</sub>6** — the stick<br>
<blockquote>: <b><sub>num</sub>0, <sub>num</sub>5, <sub>num</sub>/, <sub>num</sub>Enter</b> — the buttons