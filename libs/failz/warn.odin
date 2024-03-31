package failz

import "core:encoding/json"
import "core:fmt"
import "core:os"

warn :: proc(err: Error = true, msg := "") {
	#partial switch e in err {
	case AllocError:
		fmt.eprintln(WARNING, msg, e)
	case UnmarshalError:
		switch ue in e {
		case json.Error, json.Unmarshal_Data_Error, json.Unsupported_Type_Error:
			fmt.eprintln(WARNING, msg, ue)
		}
	case SystemError:
		fmt.eprintln(WARNING, msg, e.msg)
	case Errno:
		if e != .ERROR_NONE {fmt.eprintln(WARNING, msg, os.get_last_error_string())}
	case bool:
		if e {fmt.eprintln(WARNING, msg)}
	}
}
