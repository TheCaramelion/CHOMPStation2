// ### CHOMP Preset machines  ###

//Relay

/obj/machinery/telecomms/relay/preset/casino
	id = "Casino Relay"
	autolinkers = list("casino_relay")
	produces_heat = 0

/obj/machinery/telecomms/server/presets/ntfd
	id = "NTFD Server"
	freq_listening = list(NTFD_FREQ)
	autolinkers = list("ntfd")
