// Per-atom observer-event listener list. Component-backed, sparse.
// Global helpers (not /atom methods) to avoid bloating proc-tables of every /atom subtype.
/datum/component/observer_events
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/list/events

/datum/component/observer_events/Initialize()
	events = list()

/datum/component/observer_events/Destroy(force)
	if(events)
		for(var/list/listeners in events)
			listeners.Cut()
		events = null
	return ..()

/proc/dq_get_listener_list_from_event(atom/a, observer_event)
	var/datum/component/observer_events/c = a.GetComponent(/datum/component/observer_events)
	if(!c)
		c = a.AddComponent(/datum/component/observer_events)
	var/list/listeners = c.events[observer_event]
	if(!listeners)
		listeners = list()
		c.events[observer_event] = listeners
	return listeners
