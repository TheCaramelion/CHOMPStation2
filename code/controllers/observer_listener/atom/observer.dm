// DQEdit — observer_events moved to /datum/component/observer_events.
// Component is sparse: only atoms that actually register listeners pay.
// `register`/`unregister` are /atom/procs (they existed before our refactor,
// keeping them as instance methods doesn't add proc-table cost). The internal
// list lookup goes through the global helper dq_get_listener_list_from_event.

/atom/Destroy()
	var/list/destroy_listeners = dq_get_listener_list_from_event(src, OBSERVER_EVENT_DESTROY)
	if(destroy_listeners)
		for(var/destroy_listener in destroy_listeners)
			call(destroy_listener, destroy_listeners[destroy_listener])(src)
	// Component qdels with the atom; no manual cleanup needed.
	return ..()

/atom/proc/register(event, procOwner, proc_call)
	var/list/listeners = dq_get_listener_list_from_event(src, event)
	listeners[procOwner] = proc_call

/atom/proc/unregister(event, procOwner)
	var/list/listeners = dq_get_listener_list_from_event(src, event)
	listeners -= procOwner
