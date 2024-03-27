package ansi

import "core:fmt"
import "core:strings"

END :: "\x1b[0m"
BOLD :: "\x1b[1m"
UNDERLINE :: "\x1b[1m"

FG_BLACK :: "\x1B[30m"
FG_RED :: "\x1B[31m"
FG_GREEN :: "\x1B[32m"
FG_YELLOW :: "\x1B[33m"
FG_BLUE :: "\x1B[34m"
FG_MAGENTA :: "\x1B[35m"
FG_CYAN :: "\x1B[36m"
FG_WHITE :: "\x1B[37m"

BG_BLACK :: "\x1B[40m"
BG_RED :: "\x1B[41m"
BG_GREEN :: "\x1B[42m"
BG_YELLOW :: "\x1B[43m"
BG_BLUE :: "\x1B[44m"
BG_MAGENTA :: "\x1B[45m"
BG_CYAN :: "\x1B[46m"
BG_WHITE :: "\x1B[47m"

BLUE :: "\x1B[38;2;0;0;210m"
YELLOW :: "\x1B[38;2;255;210;0m"

bold :: proc(str: string) -> string {
	return strings.concatenate({BOLD, str, END})
}

underline :: proc(str: string) -> string {
	return strings.concatenate({UNDERLINE, str, END})
}

colorize :: proc(str: string, color: [3]u8) -> string {
	color := fmt.tprintf("\x1B[38;2;%d;%d;%dm", color.r, color.g, color.b)
	return strings.concatenate({color, str, END})
}
