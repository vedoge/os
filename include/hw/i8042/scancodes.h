#ifndef __SCANCODES_H
#define __SCANCODES_H
/* const */ unsigned char ansi_scancodes [] = {
	0,0,0,0,0,0,0,0,0,0,0,0,
	0,'\t','`',0,0,0,0,0,0,'q',
	'1', 0,0,0,'z', 's', 'a',
	'w', '2', 0, 0, 'c', 'x',
	'd','e','4','3',0,0,' ','v',
	'f','t','r','5', 0,0,'n','b',
	'h','g','y','6',0,0,0,'m','j',
	'u', '7', '8', 0, 0, ',', 'k',
	'i', 'o', '0','9',0,0,'.','/','l',
	';','p','-',0,0,0,'\'',0,'[','=',0,
	0,0/*CapsLk*/,0/*Rsh*/,	'\n',']',0,
	'\\',0,0,0,0,0,0,0,0,'\b',0,0,'1',
	0,'4','7',0,0,0,'0','.','2',
	'5','6','8',0 /*Esc*/,0 /*NumLk*/,
	0 /*F11*/,'+','3','-','*','9',0 /*ScrLk*/,
	0,0,0,0,0/*F7*/
};
unsigned char charmap [15] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

/* 
Alt+SysRq
Ctrl+Break
LWin (USB: LGUI)
RWin (USB: RGUI)
Menu
Sleep
Power
Wake
` ~
1 !
2 @
3 #
4 $
5 % E
6 ^
7 &
8 *
9 (
0 )
- _
= +
Backspace
Tab
Q
W
E
R
T
Y
U
I
O
P
[ {
] }
\ |
CapsLock
A
S
D
F
G
H
J
K
L
; :
' "
non-US-1
Enter
LShift
Z
X
C
V
B
N
M
, <
. >
/ ?
RShift
LCtrl
LAlt
space
RAlt
RCtrl
Insert
Delete
Left
Home
End
Up
Down
PgUp
PgDn
Right
NumLock
KP-7 / Home
KP-4 / Left
KP-1 / End
KP-/
KP-8 / Up
KP-5
KP-2 / Down
KP-0 / Ins
KP-*
KP-9 / PgUp
KP-6 / Right
KP-3 / PgDn
KP-. / Del
KP--
KP-+
KP-Enter
Esc
F1
F2
F3
F4
F5
F6
F7
F8
F9
F10
F11
F12
PrtScr
ScrollLock
Pause
*/
#endif
