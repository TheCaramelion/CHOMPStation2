// Deleted-engine compatibility stubs.
//
// CHOMP's R-UST fusion engine source files are restored, but a handful of
// item types didn't have their original definitions and live as inert stubs
// here. With the broader CHOMP atmos machinery + R-UST fusion now back in the
// build, most of the previously-stubbed types are real — this file shrunk to
// just the genuinely-orphaned ones.

// soft_assert — CHOMP-era helper. Was in code/_helpers/something_admin.dm
// originally; lives here until its real home is found.
/proc/soft_assert(condition, message = "soft_assert failed")
	if(condition)
		return
	stack_trace(message)
	log_world("soft_assert: [message]")
