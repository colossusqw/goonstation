// Radio (headset etc) colors.
#define RADIOC_STANDARD "#008000"
#define RADIOC_INTERCOM "#008BA0"
#define RADIOC_NANOTRASEN "#bfc200"
#define RADIOC_COMMAND "#4F78A8"
#define RADIOC_SECURITY "#E00000"
#define RADIOC_DETECTIVE "#A00000"
#define RADIOC_ENGINEERING "#A86800"
#define RADIOC_MEDICAL "#3A88AC"
#define RADIOC_RESEARCH "#732DCE"
#define RADIOC_CIVILIAN "#A10082"
#define RADIOC_SYNDICATE "#962121"
#define RADIOC_SALVAGER "#A18146"
#define RADIOC_OTHER "#800080"

// Radio (headset etc) css classes.
#define RADIOCL_STANDARD "rstandard"
#define RADIOCL_INTERCOM "rintercom"
#define RADIOCL_NANOTRASEN "rnanotrasen"
#define RADIOCL_COMMAND "rcommand"
#define RADIOCL_SECURITY "rsecurity"
#define RADIOCL_DETECTIVE "rdetective"
#define RADIOCL_ENGINEERING "rengineering"
#define RADIOCL_MEDICAL "rmedical"
#define RADIOCL_RESEARCH "rresearch"
#define RADIOCL_CIVILIAN "rcivilian"
#define RADIOCL_SYNDICATE "rsyndicate"
#define RADIOCL_SALVAGER "rsalvager"
#define RADIOCL_INTERCOM_AI "rintercomai"
#define RADIOCL_OTHER "rother"

// Frequency defines for headsets & intercoms (Convair880).
/// Minimum "selectable" freq
#define R_FREQ_MINIMUM 1441
/// Maximum "selectable" freq
#define R_FREQ_MAXIMUM 1489
#define R_FREQ_DEFAULT 1459
#define R_FREQ_NANOTRASEN 1350
#define R_FREQ_COMMAND 1358
#define R_FREQ_SECURITY 1359
#define R_FREQ_DETECTIVE 1351
#define R_FREQ_ENGINEERING 1357
#define R_FREQ_RESEARCH 1354
#define R_FREQ_MEDICAL 1356
#define R_FREQ_CIVILIAN 1355
#define R_FREQ_SYNDICATE 1352
#define R_FREQ_PIRATE 1353
#define R_FREQ_SALVAGER 1349
#define R_FREQ_GANG 1400 // Placeholder, it's actually randomized in gang rounds.
#define R_FREQ_MULTI 1451
#define R_FREQ_INTERCOM_MEDICAL 1445
#define R_FREQ_INTERCOM_SECURITY 1485
#define R_FREQ_INTERCOM_BRIG 1489
#define R_FREQ_INTERCOM_RESEARCH 1443
#define R_FREQ_LOUDSPEAKERS 1438
#define R_FREQ_INTERCOM_ENGINEERING 1441
#define R_FREQ_INTERCOM_CARGO 1455
#define R_FREQ_INTERCOM_CATERING 1463
#define R_FREQ_INTERCOM_BOTANY 1446
#define R_FREQ_INTERCOM_AI 1447
#define R_FREQ_INTERCOM_BRIDGE 1442
#define R_FREQ_INTERCOM_MINING 1456

// let's start putting adventure zone factions in here
#define R_FREQ_WIZARD 1089 // magic number, used in many magic tricks
#define R_FREQ_INTERCOM_WIZARD 1089
#define R_FREQ_INTERCOM_OWLERY 1291
#define R_FREQ_INTERCOM_SYNDCOMMAND 6174 // kaprekar's constant, a unique and weird number
#define R_FREQ_INTERCOM_TERRA8 1156 // 34 squared, octahedral number, centered pentagonal number, centered hendecagonal number
#define R_FREQ_INTERCOM_HEMERA 777 // heh

// These are for the Syndicate headset randomizer proc.
#define R_FREQ_BLACKLIST list(R_FREQ_DEFAULT, R_FREQ_NANOTRASEN, R_FREQ_COMMAND, R_FREQ_SECURITY, R_FREQ_DETECTIVE, R_FREQ_ENGINEERING, R_FREQ_RESEARCH, R_FREQ_MEDICAL,\
R_FREQ_CIVILIAN, R_FREQ_SYNDICATE, R_FREQ_SALVAGER, R_FREQ_PIRATE, R_FREQ_GANG, R_FREQ_MULTI, R_FREQ_INTERCOM_MEDICAL, R_FREQ_INTERCOM_SECURITY, R_FREQ_INTERCOM_BRIG,\
R_FREQ_INTERCOM_RESEARCH, R_FREQ_INTERCOM_ENGINEERING, R_FREQ_INTERCOM_CARGO, R_FREQ_INTERCOM_CATERING, R_FREQ_INTERCOM_AI, R_FREQ_INTERCOM_BRIDGE,\
R_FREQ_INTERCOM_MINING, R_FREQ_WIZARD)

proc/default_frequency_color(freq)
	switch(freq)
		if(R_FREQ_DEFAULT)
			return RADIOC_STANDARD
		if(R_FREQ_NANOTRASEN)
			return RADIOC_NANOTRASEN
		if(R_FREQ_COMMAND)
			return RADIOC_COMMAND
		if(R_FREQ_SECURITY)
			return RADIOC_SECURITY
		if(R_FREQ_DETECTIVE)
			return RADIOC_DETECTIVE
		if(R_FREQ_ENGINEERING)
			return RADIOC_ENGINEERING
		if(R_FREQ_RESEARCH)
			return RADIOC_RESEARCH
		if(R_FREQ_MEDICAL)
			return RADIOC_MEDICAL
		if(R_FREQ_CIVILIAN)
			return RADIOC_CIVILIAN
		if(R_FREQ_SYNDICATE)
			return RADIOC_SYNDICATE
		if(R_FREQ_SALVAGER)
			return RADIOC_SALVAGER
		if(R_FREQ_PIRATE)
			return RADIOC_SYNDICATE
		if(R_FREQ_WIZARD)
			return RADIOC_CIVILIAN
		if(R_FREQ_GANG)
			return RADIOC_SYNDICATE
		if(R_FREQ_INTERCOM_MEDICAL)
			return RADIOC_MEDICAL
		if(R_FREQ_INTERCOM_SECURITY)
			return RADIOC_SECURITY
		if(R_FREQ_INTERCOM_BRIG)
			return "#FF5000"
		if(R_FREQ_INTERCOM_RESEARCH)
			return RADIOC_RESEARCH
		if(R_FREQ_INTERCOM_ENGINEERING)
			return RADIOC_ENGINEERING
		if(R_FREQ_INTERCOM_CARGO)
			return RADIOC_ENGINEERING
		if(R_FREQ_INTERCOM_CATERING)
			return RADIOC_CIVILIAN
		if(R_FREQ_INTERCOM_AI)
			return RADIOC_COMMAND
		if(R_FREQ_INTERCOM_BRIDGE)
			return RADIOC_COMMAND

/// A list of radio frequencies and their associated channel names.
var/list/headset_channel_lookup

/// If TRUE, all radios will initialise as bricked.
var/no_more_radios = FALSE

/// Bricks all radios globally.
/proc/no_more_radio()
	global.no_more_radios = TRUE
	for_by_tcl(radio, /obj/item/device/radio)
		radio.bricked = TRUE
