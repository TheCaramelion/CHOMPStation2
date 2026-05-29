// DQAdd — synchronous file-logger for diagnosing silent DD crashes.
//
// log_world() buffers; if DD segfaults, the last few seconds of output never reach
// runtime.log. text2file with append mode forces an immediate write per call, so the
// trail survives a hard crash.
//
// File: data/dq_debug.log. Rotates after ~1MB to avoid growing forever.

/proc/dq_log(msg)
	var/static/list/header_written = list()
	var/path = "data/dq_debug.log"
	if(!header_written[path])
		header_written[path] = TRUE
		text2file("\n=== Session start [time_stamp()] ===\n", path)
	text2file("[time_stamp()] [msg]\n", path)

// Client lifecycle tracing — chases the "crash happens after I close my client" theory.
// If the last dq_debug.log line is "client Del: <ckey>" and DD dies right after, the
// disconnect path is the suspect. Note: client/New is hooked elsewhere typically; we
// only intercept Del/Destroy here so the trace covers the death window.

/client/New()
	. = ..()
	dq_log("client New: [ckey] mob=[mob?.type]")

/client/Del()
	dq_log("client Del enter: [ckey] mob=[mob?.type]")
	. = ..()
	dq_log("client Del exit: [ckey]")

/client/Destroy()
	dq_log("client Destroy enter: [ckey]")
	. = ..()
	dq_log("client Destroy exit: [ckey]")
