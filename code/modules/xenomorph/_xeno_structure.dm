/obj/structure/xeno
	hit_sound = "alien_resin_break"
	layer = RESIN_STRUCTURE_LAYER
	resistance_flags = UNACIDABLE
	///Bitflags specific to xeno structures
	var/xeno_structure_flags
	///Which hive(number) do we belong to?
	var/hivenumber = XENO_HIVE_NORMAL

/obj/structure/xeno/Initialize(mapload, _hivenumber)
	. = ..()
	if(!(xeno_structure_flags & IGNORE_WEED_REMOVAL))
		RegisterSignal(loc, COMSIG_TURF_WEED_REMOVED, PROC_REF(weed_removed))
	if(_hivenumber) ///because admins can spawn them
		hivenumber = _hivenumber
	LAZYADDASSOC(GLOB.xeno_structures_by_hive, hivenumber, src)
	if(xeno_structure_flags & CRITICAL_STRUCTURE)
		LAZYADDASSOC(GLOB.xeno_critical_structures_by_hive, hivenumber, src)

/obj/structure/xeno/Destroy()
	if(!locate(src) in GLOB.xeno_structures_by_hive[hivenumber]+GLOB.xeno_critical_structures_by_hive[hivenumber]) //The rest of the proc is pointless to look through if its not in the lists
		stack_trace("[src] not found in the list of (potentially critical) xeno structures!") //We dont want to CRASH because that'd block deletion completely. Just trace it and continue.
		return ..()
	GLOB.xeno_structures_by_hive[hivenumber] -= src
	if(xeno_structure_flags & CRITICAL_STRUCTURE)
		GLOB.xeno_critical_structures_by_hive[hivenumber] -= src
	return ..()

/obj/structure/xeno/ex_act(severity)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			take_damage(210, BRUTE, BOMB)
		if(EXPLODE_HEAVY)
			take_damage(140, BRUTE, BOMB)
		if(EXPLODE_LIGHT)
			take_damage(70, BRUTE, BOMB)
		if(EXPLODE_WEAK)
			take_damage(35, BRUTE, BOMB)

/obj/structure/xeno/attack_hand(mob/living/user)
	balloon_alert(user, "You only scrape at it")
	return TRUE

/obj/structure/xeno/flamer_fire_act(burnlevel)
	take_damage(burnlevel / 3, BURN, FIRE)

/obj/structure/xeno/fire_act()
	take_damage(10, BURN, FIRE)

/// Destroy the xeno structure when the weed it was on is destroyed
/obj/structure/xeno/proc/weed_removed()
	SIGNAL_HANDLER
	obj_destruction(damage_flag = MELEE)

/obj/structure/xeno/attack_alien(mob/living/carbon/xenomorph/X, damage_amount, damage_type, damage_flag, effects, armor_penetration, isrightclick)
	if(!(HAS_TRAIT(X, TRAIT_VALHALLA_XENO) && X.a_intent == INTENT_HARM && (tgui_alert(X, "Are you sure you want to tear down [src]?", "Tear down [src]?", list("Yes","No"))) == "Yes"))
		return ..()
	if(!do_after(X, 3 SECONDS, NONE, src))
		return
	X.do_attack_animation(src, ATTACK_EFFECT_CLAW)
	balloon_alert_to_viewers("\The [X] tears down \the [src]!", "We tear down \the [src].")
	playsound(src, "alien_resin_break", 25)
	take_damage(max_integrity) // Ensure its destroyed
