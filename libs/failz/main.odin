package failz

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "libs:ansi"

INFO := ansi.colorize("  ", {65, 105, 225})
ERROR := ansi.colorize("  ", {220, 20, 60})
WARNING := ansi.colorize("  ", {147, 112, 219})
MESSAGE := ansi.colorize(" 󱥂 ", {30, 144, 255})

purple :: proc(str: string) -> string {
	return ansi.colorize(str, {147, 112, 219})
}

AllocError :: mem.Allocator_Error

ErrorKind :: enum {
	File,
}

SystemError :: struct {
	kind: ErrorKind,
	msg:  string,
}

Error :: union {
	AllocError,
	SystemError,
	Errno,
	bool,
}

Errno :: enum {
	ERROR_NONE      = 0,
	EPERM           = 1, /* Operation not permitted */
	ENOENT          = 2, /* No such file or directory */
	ESRCH           = 3, /* No such process */
	EINTR           = 4, /* Interrupted system call */
	EIO             = 5, /* Input/output error */
	ENXIO           = 6, /* Device not configured */
	E2BIG           = 7, /* Argument list too long */
	ENOEXEC         = 8, /* Exec format error */
	EBADF           = 9, /* Bad file descriptor */
	ECHILD          = 10, /* No child processes */
	EDEADLK         = 11, /* Resource deadlock avoided */
	ENOMEM          = 12, /* Cannot allocate memory */
	EACCES          = 13, /* Permission denied */
	EFAULT          = 14, /* Bad address */
	ENOTBLK         = 15, /* Block device required */
	EBUSY           = 16, /* Device / Resource busy */
	EEXIST          = 17, /* File exists */
	EXDEV           = 18, /* Cross-device link */
	ENODEV          = 19, /* Operation not supported by device */
	ENOTDIR         = 20, /* Not a directory */
	EISDIR          = 21, /* Is a directory */
	EINVAL          = 22, /* Invalid argument */
	ENFILE          = 23, /* Too many open files in system */
	EMFILE          = 24, /* Too many open files */
	ENOTTY          = 25, /* Inappropriate ioctl for device */
	ETXTBSY         = 26, /* Text file busy */
	EFBIG           = 27, /* File too large */
	ENOSPC          = 28, /* No space left on device */
	ESPIPE          = 29, /* Illegal seek */
	EROFS           = 30, /* Read-only file system */
	EMLINK          = 31, /* Too many links */
	EPIPE           = 32, /* Broken pipe */

	/* math software */
	EDOM            = 33, /* Numerical argument out of domain */
	ERANGE          = 34, /* Result too large */

	/* non-blocking and interrupt i/o */
	EAGAIN          = 35, /* Resource temporarily unavailable */
	EWOULDBLOCK     = EAGAIN, /* Operation would block */
	EINPROGRESS     = 36, /* Operation now in progress */
	EALREADY        = 37, /* Operation already in progress */

	/* ipc/network software -- argument errors */
	ENOTSOCK        = 38, /* Socket operation on non-socket */
	EDESTADDRREQ    = 39, /* Destination address required */
	EMSGSIZE        = 40, /* Message too long */
	EPROTOTYPE      = 41, /* Protocol wrong type for socket */
	ENOPROTOOPT     = 42, /* Protocol not available */
	EPROTONOSUPPORT = 43, /* Protocol not supported */
	ESOCKTNOSUPPORT = 44, /* Socket type not supported */
	ENOTSUP         = 45, /* Operation not supported */
	EOPNOTSUPP      = ENOTSUP,
	EPFNOSUPPORT    = 46, /* Protocol family not supported */
	EAFNOSUPPORT    = 47, /* Address family not supported by protocol family */
	EADDRINUSE      = 48, /* Address already in use */
	EADDRNOTAVAIL   = 49, /* Can't assign requested address */

	/* ipc/network software -- operational errors */
	ENETDOWN        = 50, /* Network is down */
	ENETUNREACH     = 51, /* Network is unreachable */
	ENETRESET       = 52, /* Network dropped connection on reset */
	ECONNABORTED    = 53, /* Software caused connection abort */
	ECONNRESET      = 54, /* Connection reset by peer */
	ENOBUFS         = 55, /* No buffer space available */
	EISCONN         = 56, /* Socket is already connected */
	ENOTCONN        = 57, /* Socket is not connected */
	ESHUTDOWN       = 58, /* Can't send after socket shutdown */
	ETOOMANYREFS    = 59, /* Too many references: can't splice */
	ETIMEDOUT       = 60, /* Operation timed out */
	ECONNREFUSED    = 61, /* Connection refused */
	ELOOP           = 62, /* Too many levels of symbolic links */
	ENAMETOOLONG    = 63, /* File name too long */

	/* should be rearranged */
	EHOSTDOWN       = 64, /* Host is down */
	EHOSTUNREACH    = 65, /* No route to host */
	ENOTEMPTY       = 66, /* Directory not empty */

	/* quotas & mush */
	EPROCLIM        = 67, /* Too many processes */
	EUSERS          = 68, /* Too many users */
	EDQUOT          = 69, /* Disc quota exceeded */

	/* Network File System */
	ESTALE          = 70, /* Stale NFS file handle */
	EREMOTE         = 71, /* Too many levels of remote in path */
	EBADRPC         = 72, /* RPC struct is bad */
	ERPCMISMATCH    = 73, /* RPC version wrong */
	EPROGUNAVAIL    = 74, /* RPC prog. not avail */
	EPROGMISMATCH   = 75, /* Program version wrong */
	EPROCUNAVAIL    = 76, /* Bad procedure for program */
	ENOLCK          = 77, /* No locks available */
	ENOSYS          = 78, /* Function not implemented */
	EFTYPE          = 79, /* Inappropriate file type or format */
	EAUTH           = 80, /* Authentication error */
	ENEEDAUTH       = 81, /* Need authenticator */

	/* Intelligent device errors */
	EPWROFF         = 82, /* Device power is off */
	EDEVERR         = 83, /* Device error, e.g. paper out */
	EOVERFLOW       = 84, /* Value too large to be stored in data type */

	/* Program loading errors */
	EBADEXEC        = 85, /* Bad executable */
	EBADARCH        = 86, /* Bad CPU type in executable */
	ESHLIBVERS      = 87, /* Shared library version mismatch */
	EBADMACHO       = 88, /* Malformed Macho file */
	ECANCELED       = 89, /* Operation canceled */
	EIDRM           = 90, /* Identifier removed */
	ENOMSG          = 91, /* No message of desired type */
	EILSEQ          = 92, /* Illegal byte sequence */
	ENOATTR         = 93, /* Attribute not found */
	EBADMSG         = 94, /* Bad message */
	EMULTIHOP       = 95, /* Reserved */
	ENODATA         = 96, /* No message available on STREAM */
	ENOLINK         = 97, /* Reserved */
	ENOSR           = 98, /* No STREAM resources */
	ENOSTR          = 99, /* Not a STREAM */
	EPROTO          = 100, /* Protocol error */
	ETIME           = 101, /* STREAM ioctl timeout */
	ENOPOLICY       = 103, /* No such policy registered */
	ENOTRECOVERABLE = 104, /* State not recoverable */
	EOWNERDEAD      = 105, /* Previous owner died */
	EQFULL          = 106, /* Interface output queue is full */
	ELAST           = 106, /* Must be equal largest errno */
}

catch :: proc(err: Error, msg: string = "", should_exit := true, location := #caller_location) {
	sb := strings.builder_make()
	fmt.sbprintf(&sb, "%s ", ERROR)
	fmt.sbprintf(&sb, "%s: %s\n", purple(location.procedure), msg)

	#partial switch e in err {
	case AllocError:
		fmt.sbprint(&sb, MESSAGE, e)
		fmt.sbprintf(&sb, "in %s at %d:%d", location.file_path, location.line, location.column)
		fmt.eprintln(strings.to_string(sb))
	case SystemError:
		fmt.sbprint(&sb, MESSAGE, e.msg)
		fmt.sbprintf(&sb, "in %s at %d:%d", location.file_path, location.line, location.column)
		fmt.eprintln(strings.to_string(sb))
	case Errno:
		if e == .ERROR_NONE {return}
		fmt.sbprint(&sb, MESSAGE, os.get_last_error_string())
		fmt.sbprintf(&sb, "in %s at %d:%d", location.file_path, location.line, location.column)
		fmt.eprintln(strings.to_string(sb))
	case bool:
		if !e {return}
		fmt.sbprint(&sb, MESSAGE)
		fmt.sbprintf(&sb, "in %s at %d:%d", location.file_path, location.line, location.column)
		fmt.eprintln(strings.to_string(sb))
	}

	if err != nil && should_exit {os.exit(1)}
}

warn :: proc(err: Error = true, msg := "") {
	#partial switch e in err {
	case AllocError:
		fmt.eprintln(WARNING, msg, e)
	case SystemError:
		fmt.eprintln(WARNING, msg, e.msg)
	case Errno:
		if e != .ERROR_NONE {fmt.eprintln(WARNING, msg, os.get_last_error_string())}
	case bool:
		if e {fmt.eprintln(WARNING, msg)}
	}
}
