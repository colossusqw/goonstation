ADMIN_INTERACT_PROCS(/mob/living/silicon, proc/pick_law_rack)
/mob/living/silicon
	mob_flags = USR_DIALOG_UPDATES_RANGE
	gender = NEUTER
	var/syndicate = FALSE // Do we get Syndicate laws?
	var/syndicate_possible = FALSE //  Can we become a Syndie robot?
	var/emagged = FALSE // Are we emagged, removing all laws?
	var/emaggable = FALSE // Can we be emagged?
	robot_talk_understand = TRUE
	see_infrared = TRUE
	var/list/req_access = list()

	var/killswitch = FALSE
	var/killswitch_at = 0
	var/weapon_lock = FALSE
	var/weaponlock_time = 120
	var/obj/item/card/id/botcard //An ID card that the robot "holds" invisibly

	var/mob/living/silicon/ai/mainframe = null // where to go back to when we die, if we have one, for hivebots/robots
	var/dependent = 0 // if we're host to a mainframe's mind
	var/shell = 0 // are we available for use as a shell for an AI

	var/obj/machinery/lawrack/law_rack_connection = null // which rack we're getting our laws from
	/// a list of strings used as fake laws that may be stated via the State Fake Laws command, to deceive people as a rogue silicon
	var/list/fake_laws = list()

	var/obj/item/cell/cell = null

	var/static/regex/monospace_say_regex = new(@"`([^`]+)`", "g")

	can_bleed = FALSE
	blood_id = "oil"
	use_stamina = FALSE
	can_lie = FALSE
	canbegrabbed = FALSE // silicons can't be grabbed, they're too bulky or something
	grabresistmessage = "but can't get a good grip!"

	dna_to_absorb = 0 //robots dont have DNA for fuck sake


	//voice_type = "robo"

/mob/living/silicon/New()
	..()
	src.botcard = new /obj/item/card/id(src)
	if(src.syndicate)
		src.law_rack_connection = ticker?.ai_law_rack_manager.default_ai_rack_syndie
		logTheThing(LOG_STATION, src, "New cyborg [src] connects to default SYNDICATE rack [constructName(src.law_rack_connection)]")
	else
		src.law_rack_connection = ticker?.ai_law_rack_manager.default_ai_rack
		logTheThing(LOG_STATION, src, "New cyborg [src] connects to default rack [constructName(src.law_rack_connection)]")
	APPLY_ATOM_PROPERTY(src, PROP_MOB_CAN_CONSTRUCT_WITHOUT_HOLDING, src)

/mob/living/silicon/disposing()
	req_access = null
	return ..()

/mob/living/silicon/can_eat()
	return FALSE

/mob/living/silicon/can_drink()
	return FALSE

///mob/living/silicon/proc/update_canmove()
//	..()
	//canmove = !(src.hasStatus(list("knockdown", "unconscious", "stunned")) || buckled)

/mob/living/silicon/proc/use_power()
	return

/mob/living/silicon/proc/cancelAlarm()
	return

/mob/living/silicon/proc/triggerAlarm()
	return

/mob/living/silicon/proc/show_laws()
	return

/mob/living/silicon/proc/return_mainframe()
	if (mainframe)
		mainframe.return_to(src)
	else
		boutput(src, SPAN_ALERT("You lack a dedicated mainframe!"))
		return

/mob/living/silicon/proc/become_eye()
	if (!mainframe)
		return
	src.return_mainframe()
	mainframe.eye_view()
	mainframe.eyecam.set_loc(get_turf(src))

// Moves this down from ai.dm so AI shells and AI-controlled cyborgs can use it too.
// Also made it a little more functional and less buggy (Convair880).
#define STUNNED (src.stat || src.getStatusDuration("stunned") || src.getStatusDuration("knockdown")) || (src.dependent && (src.mainframe.stat || src.mainframe.getStatusDuration("stunned") || src.mainframe.getStatusDuration("knockdown")))
/mob/living/silicon/proc/open_nearest_door_silicon()
	if (!src || !issilicon(src))
		return
	if (!isAI(src) && !(src.dependent && src.mainframe && isAI(mainframe)))
		usr.show_text("You have no mainframe to relay this command to!", "red")
		return

	if (STUNNED)
		usr.show_text("You cannot use this command when your shell or mainframe is incapacitated.", "red")
		return

	var/list/creatures = sortList(get_mobs_trackable_by_AI(), /proc/cmp_text_asc)
	var/target_name = tgui_input_list(usr, "Open doors nearest to which creature?", "Open Door", creatures)

	if (!target_name)
		return

	target_name = creatures[target_name]

	// Find us some doors.
	var/list/valid_doors = list()
	for (var/obj/machinery/door/D in view(target_name, 1))
		if (istype(D, /obj/machinery/door/airlock))
			valid_doors["[D.name] #[length(valid_doors) + 1] at [get_area(D)]"] += D // Don't remove the #[number] part here.
		else if (istype(D, /obj/machinery/door/window))
			valid_doors["[D.name] #[length(valid_doors) + 1] at [get_area(D)]"] += D
		else
			continue
	// Attempt to open said doors.
	var/obj/machinery/door/our_door
	if (!length(valid_doors))
		usr.show_text("Couldn't find a controllable airlock near [target_name].", "red")
		return
	var/t1 = tgui_input_list(usr, "Please select a door to control.", "Target Selection", valid_doors)
	if (!t1)
		return
	our_door = valid_doors[t1]

	if (STUNNED)
		usr.show_text("You cannot use this command when your shell or mainframe is incapacitated.", "red")
		return
	if (!our_door || !istype(our_door, /obj/machinery/door/))
		usr.show_text("Couldn't find a controllable airlock near [target_name].", "red")
		return

	var/turf/door_loc = get_turf(our_door)
	if (door_loc && isrestrictedz(door_loc.z)) // Somebody will find a way to abuse it if I don't put this here.
		usr.show_text("Unable to interface with door due to unknown interference.", "red")
		return
	if(isAI(src) && door_loc?.z == get_z(z) )
		usr.show_text("Your mainframe was unable relay this command that far away!", "red")
		return

	if (istype(our_door, /obj/machinery/door/airlock/))
		var/obj/machinery/door/airlock/A = our_door
		if (A.canAIControl())
			if (A.open())
				boutput(usr, SPAN_NOTICE("[A.name] opened successfully."))
			else
				boutput(usr, SPAN_ALERT("Attempt to open [A.name] failed. It may require manual repairs."))
		else
			boutput(usr, SPAN_ALERT("Cannot interface with airlock \"[A.name]\". It may require manual repairs."))

	else if (istype(our_door, /obj/machinery/door/window))
		if (our_door.open())
			boutput(usr, SPAN_NOTICE("[our_door.name] opened successfully."))
		else
			boutput(usr, SPAN_ALERT("Attempt to open [our_door.name] failed."))

	return
#undef STUNNED

/mob/living/silicon/has_any_hands()
	// no hands :(

	// unless...
	. = istype(src.equipped(), /obj/item/magtractor)

/mob/living/silicon/put_in_hand(obj/item/I, hand)
	if (!I) return 0
	if (src.equipped() && istype(src.equipped(), /obj/item/magtractor))
		var/obj/item/magtractor/M = src.equipped()
		if (M.pickupItem(I, src))
			actions.start(new/datum/action/magPickerHold(M, M.highpower), src)
			return 1
	return 0 // we have no hands doofus

/mob/living/silicon/click(atom/target, params, location, control)
	if (src.targeting_ability)
		..()
	if (!src.stat && !src.restrained() && !src.getStatusDuration("knockdown") && !src.getStatusDuration("unconscious") && !src.getStatusDuration("stunned") && !src.getStatusDuration("low_signal"))
		if(src.client.check_any_key(KEY_OPEN | KEY_BOLT | KEY_SHOCK) && istype(target, /obj) )
			var/obj/O = target
			if(O.receive_silicon_hotkey(src)) return

	var/inrange = in_interact_range(target, src)
	var/obj/item/equipped = src.equipped()
	if (params["ctrl"] || src.client.check_any_key(KEY_EXAMINE | KEY_POINT) || (equipped && (inrange || (equipped.flags & EXTRADELAY))) || istype(target, /turf) || ishelpermouse(target)) // slightly hacky, oh well, tries to check whether we want to click normally or use attack_ai
		..()
	else
		if (GET_DIST(src, target) > 0) // temporary fix for cyborgs turning by clicking
			set_dir(get_dir(src, target))

		if(!src.getStatusDuration("low_signal"))
			target.attack_ai(src, params, location, control)

/*
/mob/living/key_down(key)
	if (key == "shift")
		update_cursor()
	..()

/mob/living/key_up(key)
	if (key == "shift")
		update_cursor()
	..()
*/

/mob/living/silicon/update_cursor()
	if (src.client)
		if (src.client.check_key(KEY_OPEN))
			src.set_cursor('icons/cursors/open.dmi')
			return
		if (src.client.check_key(KEY_BOLT))
			src.set_cursor('icons/cursors/bolt.dmi')
			return
		if(src.client.check_key(KEY_SHOCK))
			src.set_cursor('icons/cursors/shock.dmi')
			return
	return ..()
/mob/living/silicon/say(var/message)
	if (!message)
		return

	if (src.client && src.client.ismuted())
		boutput(src, "You are currently muted and may not speak.")
		return

	if (isdead(src))
		message = trimtext(copytext(sanitize(message), 1, MAX_MESSAGE_LEN))
		return src.say_dead(message)

	// wtf?
	if (src.stat)
		return

	if (length(message) >= 2)
		if (copytext(lowertext(message), 1, 3) == ":s")
			message = copytext(message, 3)
			message = trimtext(copytext(sanitize(message), 1, MAX_MESSAGE_LEN))
			src.robot_talk(message)
		else
			return ..(message)
	else
		return ..(message)

/mob/living/silicon/say_decorate(message)
	. = monospace_say_regex.Replace(message, SPAN_MONOSPACE("$1"))

/mob/living/proc/process_killswitch()
	return

/mob/living/proc/process_locks()
	return

/mob/living/proc/robot_talk(var/message)

	logTheThing(LOG_DIARY, src, ": [message]", "say")

	message = trimtext(html_encode(message))
	message = src.check_singing_prefix(message)

	if (!message)
		return

	var/message_a = src.say_quote(message)
	var/rendered = SPAN_ROBOTICSAY("Robotic Talk, <span class='name' data-ctx='\ref[src.mind]'>[src.name]</span> [SPAN_MESSAGE("[message_a]")]")
	for (var/mob/living/S in mobs)
		if(!S.stat)
			if(S.robot_talk_understand)
				if(S.robot_talk_understand == src.robot_talk_understand)
					var/thisR = rendered
					if (S.client && S.client.holder && src.mind)
						thisR = "<span class='adminHearing' data-ctx='[S.client.chatOutput.getContextFlags()]'>[rendered]</span>"
					S.show_message(thisR, 2)
			else if(istype(S, /mob/living/intangible/flock) || istype(S, /mob/living/critter/flock/drone))
				var/flockrendered = SPAN_ROBOTICSAY("[radioGarbleText("Robotic Talk", FLOCK_RADIO_GARBLE_CHANCE / 2)], <span class='name' data-ctx='\ref[src.mind]'>[radioGarbleText(src.name, FLOCK_RADIO_GARBLE_CHANCE / 2)]</span> [SPAN_MESSAGE("[radioGarbleText(message_a, FLOCK_RADIO_GARBLE_CHANCE / 2)]")]")
				S.show_message(flockrendered, 2)

	var/list/listening = hearers(1, src)
	listening |= src

	var/list/heard = list()
	for (var/mob/M in listening)
		if(!issilicon(M) && !M.robot_talk_understand)
			heard += M


	if (length(heard))
		var/message_b

		message_b = "beep beep beep"
		message_b = src.say_quote(message_b)
		message_b = "<i>[message_b]</i>"

		rendered = SPAN_ROBOTICSAY("<span class='name' data-ctx='\ref[src.mind]'>[src.voice_name]</span> [SPAN_MESSAGE("[message_b]")]")

		for (var/mob/M in heard)
			var/thisR = rendered
			if (M.client && (istype(M, /mob/dead/observer)||M.client.holder) && src.mind)
				thisR = "<span class='adminHearing' data-ctx='[M.client.chatOutput.getContextFlags()]'>[rendered]</span>"
			M.show_message(thisR, 2)

	message = src.say_quote(message)

	rendered = SPAN_ROBOTICSAY("Robotic Talk, <span class='name' data-ctx='\ref[src.mind]'>[src.name]</span> [SPAN_MESSAGE("[message_a]")]")

	for (var/mob/M in mobs)
		if (istype(M, /mob/new_player))
			continue
		if (isdead(M) && !istype(M, /mob/dead/target_observer))
			var/thisR = rendered
			if (M.client && M.client.holder && src.mind)
				thisR = "<span class='adminHearing' data-ctx='[M.client.chatOutput.getContextFlags()]'>[rendered]</span>"
			M.show_message(thisR, 2)

/mob/living/silicon/lastgasp(allow_dead=FALSE)
	..(allow_dead, grunt=pick("BZZT","WONK","ZAP","FZZZT","GRRNT","BEEP","BOOP"))

/mob/living/silicon/proc/allowed(mob/M)
	//check if it doesn't require any access at all
	if(src.check_access(null))
		return 1
	if(src.check_access(M.equipped()))
		return 1
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		//if they are holding or wearing a card that has access, that works
		if(src.check_access(H.wear_id))
			return 1
	return 0

/mob/living/silicon/proc/check_access(obj/item/I)
	if(!istype(src.req_access, /list)) //something's very wrong
		return 1

	var/obj/item/card/id/id_card = get_id_card(I)
	var/list/L = src.req_access
	if(!L.len) //no requirements
		return 1
	if(!istype(id_card, /obj/item/card/id) || !id_card:access) //not ID or no access
		return 0
	for(var/req in src.req_access)
		if(!(req in id_card:access)) //doesn't have this access
			return 0
	return 1

/proc/list_robots()
	var/list/L = list()
	for (var/mob/living/silicon/robot/M in mobs)
		L += M
	return L

/datum/module_editor
	var/obj/item/current = null

	proc/show_interface(var/client/cli, var/obj/item/robot_module/D)
		var/output = {"<html><head><style>
table {
	border:none;
}
tr {
	border:none;
}
td {
	border:none;
}
</style></head><body><h2>Module editor</h2><h3>Current items</h3><table style='width:100%'><tr><td style='width:80%'><b>Module</b></td><td style='width:10%'>&nbsp;</td><td style='width:10%'>&nbsp;</td></tr>"}

		for (var/obj/item/I in D.tools)
			output += "<tr><td><b>[I.name]</b> ([I.type])</td><td><a href='?src=\ref[src];edit=\ref[I];mod=\ref[D]'>(EDIT)</a><a href='?src=\ref[src];del=\ref[I];mod=\ref[D]'>(DEL)</a></td></tr>"

		output += "</table><br><br><h3>Add new item</h3>"
		output += "<a href='?src=\ref[src];create=1;mod=\ref[D]'>Create new item</a><br><br>"
		if (current)
			output += "<b>Currently adding: </b> [current.name] <a href='?src=\ref[src];edcurr=1;mod=\ref[D]'>(EDIT)</a><br>"
			output += "<a href='?src=\ref[src];addcurr=1;mod=\ref[D]'>Add to module</a>"
		usr.Browse(output, "window=module_editor;size=400x600")

	Topic(href, href_list)
		USR_ADMIN_ONLY
		var/obj/item/robot_module/D = locate(href_list["mod"])
		if (!D)
			boutput(usr, SPAN_ALERT("Missing module reference!"))
			return
		if (href_list["edit"])
			var/obj/item/I = locate(href_list["edit"])
			if (!istype(I))
				boutput(usr, SPAN_ALERT("Item no longer exists!"))
				show_interface(usr.client, D)
				return
			if (!(I in D.tools))
				boutput(usr, SPAN_ALERT("Item no longer in module!"))
				show_interface(usr.client, D)
				return
			usr.client:debug_variables(I)
		if (href_list["del"])
			var/obj/item/I = locate(href_list["del"])
			if (!istype(I))
				boutput(usr, SPAN_ALERT("Item no longer exists!"))
				show_interface(usr.client, D)
				return
			if (!(I in D.tools))
				boutput(usr, SPAN_ALERT("Item no longer in module!"))
				show_interface(usr.client, D)
				return
			D.tools -= I
			qdel(I)
		if (href_list["edcurr"])
			if (!current)
				boutput(usr, SPAN_ALERT("No current item!"))
				show_interface(usr.client, D)
				return
			usr.client:debug_variables(current)
		if (href_list["create"])
			var/path_match = input("Enter a type path or part of a type path.", "Type match", null) as text
			var/path = get_one_match(path_match, /obj/item)
			if (!path)
				boutput(usr, SPAN_ALERT("Invalid path!"))
				show_interface(usr.client, D)
				return
			current = new path(null)
		if (href_list["addcurr"])
			if (!current)
				show_interface(usr.client, D)
				return
			D.tools += current
			current.set_loc(D)
			current = null
			boutput(usr, SPAN_NOTICE("Added item to module!"))
		show_interface(usr.client, D)

var/global/list/module_editors = list()

/client/proc/edit_module(var/mob/living/silicon/robot/M as mob in list_robots())
	set name = "Edit Module"
	set desc = "Module editor! Woo!"
	SET_ADMIN_CAT(ADMIN_CAT_PLAYERS)
	set popup_menu = 0
	ADMIN_ONLY
	SHOW_VERB_DESC

	if (!istype(M))
		boutput(src, SPAN_ALERT("That thing has no module!"))
		return

	if (!M.module)
		if(tgui_alert(src, "Would you like to give them a module?", "No module yet", list("Yes", "No")) == "Yes")
			var/list/module_types = concrete_typesof(/obj/item/robot_module)
			var/module_type = tgui_input_list(src, "Select a module type", "Module type", module_types)
			if (!module_type)
				return
			M.set_module(new module_type)
			M.freemodule = FALSE
		else
			return

	var/datum/module_editor/editor = module_editors[ckey]
	if (!editor)
		module_editors[ckey] = new /datum/module_editor
		editor = module_editors[ckey]
	editor.show_interface(src, M.module)

/mob/living/silicon/understands_language(var/langname)
	if (langname == "english" || !langname)
		return 1
	if (langname == "silicon" || langname == "binary")
		return 1
	if (langname == "monkey" && monkeysspeakhuman)
		return 1
	return 0

/mob/living/silicon/get_special_language(var/secure_mode)
	if (secure_mode == "s")
		return "silicon"
	return null

/mob/living/silicon/isBlindImmune()
	return 1

/mob/living/silicon/isAIControlled()
	return (isAI(src) || (!isAI(src) && src.mainframe))

/mob/living/silicon/change_eye_blurry(var/amount, var/cap = 0)
	if (amount < 0)
		return ..()
	else
		return 1

/mob/living/silicon/take_eye_damage(var/amount, var/tempblind = 0)
	if (amount < 0)
		return ..()
	else
		return 1

/mob/living/silicon/take_ear_damage(var/amount, var/tempdeaf = 0)
	if (amount < 0)
		return ..()
	else
		return 1

/mob/living/silicon/choose_name(var/retries = 3, var/what_you_are = null, var/default_name = null, var/force_instead = 0)
	var/newname
	if(isnull(default_name))
		default_name = src.real_name
	for (retries, retries > 0, retries--)
		if(force_instead)
			newname = default_name
		else
			newname = tgui_input_text(src, "You are a Robot. Would you like to change your name to something else?", "Name Change", default_name)
			if(newname && newname != default_name)
				phrase_log.log_phrase("name-cyborg", newname, no_duplicates=TRUE)
		if (!newname)
			src.real_name = borgify_name("Robot")
			break
		else
			newname = strip_html(newname, MOB_NAME_MAX_LENGTH, 1)
			if (!length(newname) || copytext(newname,1,2) == " ")
				src.show_text("That name was too short after removing bad characters from it. Please choose a different name.", "red")
				continue
			else
				if (alert(src, "Use the name [newname]?", newname, "Yes", "No") == "Yes")
					src.real_name = newname
					break
				else
					continue
	if (!newname)
		src.real_name = borgify_name("Robot")

	src.UpdateName()

/mob/living/silicon/UpdateName()
	..()
	src.botcard.registered = src.name

/mob/living/silicon/robot/choose_name(var/retries = 3, var/what_you_are = null, var/default_name = null, var/force_instead = 0)
	. = ..()
	src.internal_pda.name = "[src.name]'s Internal PDA Unit"
	src.internal_pda.owner = "[src.name]"

/proc/borgify_name(var/start_name = "Robot")
	if (!start_name) // somehow
		start_name = "Robot"
	. += start_name + " "
	. += pick("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega")
	. += "-[rand(1, 99)]"

///converts a cyborg/AI to a syndicate version, taking the causing agent as an argument
/mob/living/silicon/proc/make_syndicate(var/cause)
	if (!src.mind) //you need a mind to be evil
		return FALSE
	if(src.dependent) //if you're a shell
		src.show_text("Failsafe engaged. Synchronized lawset with your mainframe to avoid law ROM corruption.", "red")
		return FALSE
	if(src.emagged) // Syndie laws don't matter if we're emagged.
		return FALSE

	if (src.syndicate || src.syndicate_possible)
		if (src.mind.add_antagonist(ROLE_SYNDICATE_ROBOT, respect_mutual_exclusives = FALSE, source = ANTAGONIST_SOURCE_CONVERTED))
			logTheThing(LOG_STATION, src, "[src] was made a Syndicate robot at [log_loc(src)]. [cause ? " Source: [constructTarget(cause,"combat")]" : ""]")
			logTheThing(LOG_STATION, src, "[src.name] is connected to the default Syndicate rack [constructName(src.law_rack_connection)] [cause ? " Source: [constructTarget(cause,"combat")]" : ""]")
			return TRUE

	return FALSE

/mob/living/silicon/is_cold_resistant()
	.= 1

/mob/living/silicon/shock(var/atom/origin, var/wattage, var/zone, var/stun_multiplier = 1, var/ignore_gloves = 0)
	return 0

/mob/living/silicon/electric_expose(var/power = 1)
	return 0

/mob/living/silicon/hitby(atom/movable/AM, datum/thrown_thing/thr)
	. = ..()

	src.visible_message(SPAN_ALERT("[src] has been hit by [AM]."))
	logTheThing(LOG_COMBAT, src, "is struck by [AM] [AM.is_open_container() ? "[log_reagents(AM)]" : ""] at [log_loc(src)].")
	random_brute_damage(src, AM.throwforce,1)

	#ifdef DATALOGGER
	game_stats.Increment("violence")
	#endif

	if(AM.throwforce >= 40)
		src.throw_at(get_edge_target_turf(src,get_dir(AM, src)), 10, 1)

	. = 'sound/impact_sounds/Metal_Clang_3.ogg'

/mob/living/silicon/get_id(not_worn = FALSE)
	. = ..()
	if(. || not_worn)
		return
	return src.botcard

/mob/living/silicon/proc/singify_text(var/text)
	var/adverb = pick("robotically", "synthetically", "electronically")
	var/speech_verb = pick("sings", pick("croons", "intones", "warbles"))
	var/note_img = "<img class='icon misc' style='position: relative; bottom: -3px;' src='[resource("images/radio_icons/noterobot.png")]'>"
	if (src.singing & LOUD_SINGING)
		note_img = "[note_img][note_img]"
	return "[adverb] [speech_verb],[note_img]<span class='robotsing'><i>[text]</i></span>[note_img]"

/mob/living/silicon/Exited(Obj, newloc)
	. = ..()
	if(Obj == src.cell)
		src.cell = null

/mob/living/silicon/proc/set_law_rack(obj/machinery/lawrack/rack, mob/user)
	if(!(rack in ticker.ai_law_rack_manager.registered_racks))
		return
	src.law_rack_connection = rack
	logTheThing(LOG_STATION, src, "[src.name] is connected to the rack at [constructName(src.law_rack_connection)][user ? " by [constructName(user)]" : ""]")
	if (user)
		var/area/A = get_area(src.law_rack_connection)
		boutput(user, "You connect [src.name] to the stored law rack at [A.name].")
	src.playsound_local(src, 'sound/misc/lawnotify.ogg', 100, flags = SOUND_IGNORE_SPACE)
	src.show_text("<h3>You have been connected to a law rack</h3>", "red")
	src.show_laws()

/mob/living/silicon/proc/pick_law_rack()
	set name = "Set law rack"
	var/list/racks = list()
	for (var/obj/machinery/lawrack/rack in ticker.ai_law_rack_manager.registered_racks)
		racks[get_area(rack)] = rack
	var/chosen = tgui_input_list(usr, "Select a rack to link", "Law racks", racks)
	if (chosen)
		src.set_law_rack(racks[chosen])

/mob/living/silicon/proc/add_radio_upgrade(var/obj/item/device/radio_upgrade/upgrade)
	return FALSE

/mob/living/silicon/proc/remove_radio_upgrade()
	return FALSE

/mob/living/silicon/proc/set_fake_laws()
	#define FAKE_LAW_LIMIT 12
	var/law_base_choice = tgui_input_list(usr,"Which lawset would you like to use as a base for your new fake laws?", "Fake Laws", list("Real Laws", "Fake Laws"))
	if (!law_base_choice)
		return
	var/law_base = ""
	if(law_base_choice == "Real Laws")
		if(src.law_rack_connection)
			law_base = src.law_rack_connection.format_for_logs("\n")
		else
			law_base = ""
	else if(law_base_choice == "Fake Laws")
		for(var/fake_law in src.fake_laws)
			// this is just the default input for the user, so it should be fine
			law_base += "[html_decode(fake_law)]\n"

	var/raw_law_text = tgui_input_text(usr, "Please enter the fake laws you would like to be able to state via the State Fake Laws command! Each line is one law.", "Fake Laws", law_base, multiline = TRUE)
	if(!raw_law_text)
		return
	// split into lines
	var/list/raw_law_list = splittext_char(raw_law_text, "\n")
	// return if we input an excessive amount of laws
	if (length(raw_law_list) > FAKE_LAW_LIMIT)
		boutput(usr, SPAN_ALERT("You cannot set more than [FAKE_LAW_LIMIT] laws."))
		return
	// clear old fake laws
	src.fake_laws = list()
	// cleanse the lines and add them as our laws
	for(var/raw_law in raw_law_list)
		var/nice_law = trimtext(strip_html(raw_law))
		// empty lines would probably be an accident and result in awkward pauses that might give the AI away
		if (!length(nice_law))
			continue
		fake_laws += nice_law

	src.show_message(SPAN_BOLD("Your new fake laws are: "))
	for(var/a_law in src.fake_laws)
		src.show_message(a_law)
	#undef FAKE_LAW_LIMIT

/mob/living/silicon/proc/state_fake_laws()
	if (ON_COOLDOWN(src,"state_laws", 20 SECONDS))
		boutput(src, SPAN_ALERT("Your law processor needs time to cool down!"))
		return

	var/list/laws = src.shell ? src.mainframe.fake_laws : src.fake_laws

	for(var/a_law in laws)
		sleep(1 SECOND)
		// decode the symbols, because they will be encoded again when the law is spoken, and otherwise we'd double-dip
		src.say(html_decode(a_law))
		logTheThing(LOG_SAY, usr, "states a fake law: \"[a_law]\"")
