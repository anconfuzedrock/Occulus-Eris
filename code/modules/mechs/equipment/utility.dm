/obj/item/mech_equipment/clamp
	name = "mounted clamp"
	desc = "A large, heavy industrial cargo loading clamp."
	icon_state = "mech_clamp"
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_UTILITY)
	var/obj/carrying
	origin_tech = list(TECH_MATERIAL = 2, TECH_ENGINEERING = 2)

/obj/item/mech_equipment/clamp/attack()
	return 0

/obj/item/mech_equipment/clamp/afterattack(var/atom/target, var/mob/living/user, var/inrange, var/params)
	. = ..()

	if(. && !carrying)

		///// OCCULUS EDIT START
		// Mechs did not check if they were actually in range before trying to use drills or clamps.
		// The proc has been adjusted with the following clause in mind.

		if (!inrange)
			to_chat(user, SPAN_NOTICE("You must be adjacent to [target] to use the hydraulic clamp."))
		else

			if(istype(target, /obj))


				var/obj/O = target
				if(O.buckled_mob)
					return
				if(locate(/mob/living) in O)
					to_chat(user,"<span class='warning'>You can't load living things into the cargo compartment.</span>")
					return

				if(istype(target, /obj/structure/scrap_spawner))
					owner.visible_message(SPAN_NOTICE("\The [owner] begins compressing \the [O] with \the [src]."))
					if(do_after(owner, 20, O, 0, 1))
						if(istype(O, /obj/structure/scrap_spawner))
							var/obj/structure/scrap_spawner/S = O
							S.make_cube()
							owner.visible_message(SPAN_NOTICE("\The [owner] compresses \the [O] into a cube with \the [src]."))
					return

				if(O.anchored)
					to_chat(user, "<span class='warning'>[target] is firmly secured.</span>")
					return


				owner.visible_message(SPAN_NOTICE("\The [owner] begins loading \the [O]."))
				if(do_after(owner, 20, O, 0, 1))
					O.forceMove(src)
					carrying = O
					owner.visible_message(SPAN_NOTICE("\The [owner] loads \the [O] into its cargo compartment."))


			//attacking - Cannot be carrying something, cause then your clamp would be full
			else if(istype(target,/mob/living))
				var/mob/living/M = target
				if(user.a_intent == I_HURT)
					admin_attack_log(user, M, "attempted to clamp [M] with [src] ", "Was subject to a clamping attempt.", ", using \a [src], attempted to clamp")
					owner.setClickCooldown(owner.arms ? owner.arms.action_delay * 3 : 30) //This is an inefficient use of your powers
					if(prob(33))
						owner.visible_message(SPAN_DANGER("[owner] swings its [src] in a wide arc at [target] but misses completely!"))
						return
					M.attack_generic(owner, (owner.arms ? owner.arms.melee_damage * 1.5 : 0), "slammed") //Honestly you should not be able to do this without hands, but still
					M.throw_at(get_edge_target_turf(owner ,owner.dir),5, 2)
					to_chat(user, "<span class='warning'>You slam [target] with [src.name].</span>")
					owner.visible_message(SPAN_DANGER("[owner] slams [target] with the hydraulic clamp."))
				else
					step_away(M, owner)
					to_chat(user, "You push [target] out of the way.")
					owner.visible_message("[owner] pushes [target] out of the way.")

		///// OCCULUS EDIT END

/obj/item/mech_equipment/clamp/attack_self(var/mob/user)
	. = ..()
	if(.)
		if(!carrying)
			to_chat(user, SPAN_WARNING("You are not carrying anything in \the [src]."))
		else
			owner.visible_message(SPAN_NOTICE("\The [owner] unloads \the [carrying]."))
			carrying.forceMove(get_turf(src))
			carrying = null

/obj/item/mech_equipment/clamp/get_hardpoint_maptext()
	if(carrying)
		return carrying.name
	. = ..()

// A lot of this is copied from floodlights.
/obj/item/mech_equipment/light
	name = "floodlight"
	desc = "An exosuit-mounted light."
	icon_state = "mech_floodlight"
	item_state = "mech_floodlight"
	restricted_hardpoints = list(HARDPOINT_HEAD)
	mech_layer = MECH_INTERMEDIATE_LAYER

	var/on = FALSE
	var/l_max_bright = 0.9
	var/l_inner_range = 1
	var/l_outer_range = 6
	origin_tech = list(TECH_MATERIAL = 1, TECH_ENGINEERING = 1)

/obj/item/mech_equipment/light/attack_self(var/mob/user)
	. = ..()
	if(.)
		on = !on
		to_chat(user, "You switch \the [src] [on ? "on" : "off"].")
		update_icon()
		owner.update_icon()

/obj/item/mech_equipment/light/on_update_icon()
	. = ..()
	if(on)
		icon_state = "[initial(icon_state)]-on"
		//set_light(l_max_bright, l_inner_range, l_outer_range)
		set_light(l_outer_range, l_max_bright, "#ffffff")
	else
		icon_state = "[initial(icon_state)]"
		//set_light(0, 0)
		set_light(0, 0)

#define CATAPULT_SINGLE 1
#define CATAPULT_AREA   2

/obj/item/mech_equipment/catapult
	name = "gravitational catapult"
	desc = "An exosuit-mounted gravitational catapult."
	icon_state = "mech_clamp"
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_UTILITY)
	var/mode = CATAPULT_SINGLE
	var/atom/movable/locked
	equipment_delay = 30 //Stunlocks are not ideal
	origin_tech = list(TECH_MATERIAL = 4, TECH_ENGINEERING = 4, TECH_MAGNET = 4)

/obj/item/mech_equipment/catapult/get_hardpoint_maptext()
	var/string
	if(locked)
		string = locked.name + " - "
	if(mode == 1)
		string += "Pull"
	else string += "Push"
	return string


/obj/item/mech_equipment/catapult/attack_self(var/mob/user)
	. = ..()
	if(.)
		mode = mode == CATAPULT_SINGLE ? CATAPULT_AREA : CATAPULT_SINGLE
		to_chat(user, SPAN_NOTICE("You set \the [src] to [mode == CATAPULT_SINGLE ? "single" : "multi"]-target mode."))
		update_icon()


/obj/item/mech_equipment/catapult/afterattack(var/atom/target, var/mob/living/user, var/inrange, var/params)
	. = ..()
	if(.)

		switch(mode)
			if(CATAPULT_SINGLE)
				if(!locked)
					var/atom/movable/AM = target
					if(!istype(AM) || AM.anchored || !AM.simulated)
						to_chat(user, SPAN_NOTICE("Unable to lock on [target]."))
						return
					locked = AM
					to_chat(user, SPAN_NOTICE("Locked on [AM]."))
					return
				else if(target != locked)
					if(locked in view(owner))
						locked.throw_at(target, 14, 1.5, owner)
						log_and_message_admins("used [src] to throw [locked] at [target].", user, owner.loc)
						locked = null

						var/obj/item/cell/C = owner.get_cell()
						if(istype(C))
							C.use(active_power_use * CELLRATE)

					else
						locked = null
						to_chat(user, SPAN_NOTICE("Lock on [locked] disengaged."))
			if(CATAPULT_AREA)

				var/list/atoms = list()
				if(isturf(target))
					atoms = range(target,3)
				else
					atoms = orange(target,3)
				for(var/atom/movable/A in atoms)
					if(A.anchored || !A.simulated) continue
					var/dist = 5-get_dist(A,target)
					A.throw_at(get_edge_target_turf(A,get_dir(target, A)),dist,0.7)


				log_and_message_admins("used [src]'s area throw on [target].", user, owner.loc)
				var/obj/item/cell/C = owner.get_cell()
				if(istype(C))
					C.use(active_power_use * CELLRATE * 2) //bit more expensive to throw all



#undef CATAPULT_SINGLE
#undef CATAPULT_AREA


/obj/item/material/drill_head
	var/durability = 0
	name = "drill head"
	desc = "A replaceable drill head usually used in exosuit drills."
	icon_state = "exodrillhead"
	default_material = MATERIAL_STEEL

/obj/item/material/drill_head/Initialize()
	. = ..()
	// OCCULUS EDIT -- durability was not being properly applied because material during this proc is null
	//durability = 2 * (material ? material.integrity : 1)

///// OCCULUS EDIT BEGIN
// Drills crafted from the crafting menu actually call Created().
// var/creator is a dummy var to avoid any issues with the call.

/obj/item/material/drill_head/Created(var/creator)
	src.ApplyDurability()

///// OCCULUS EDIT END

/obj/item/material/drill_head/steel/New(var/newloc)
	..(newloc,MATERIAL_STEEL)
	src.ApplyDurability()	// OCCULUS EDIT -- apply durability to drills properly

/obj/item/material/drill_head/plasteel/New(var/newloc)
	..(newloc,MATERIAL_PLASTEEL)
	src.ApplyDurability()	// OCCULUS EDIT -- apply durability to drills properly

/obj/item/material/drill_head/diamond/New(var/newloc)
	..(newloc,MATERIAL_DIAMOND)
	src.ApplyDurability()	// OCCULUS EDIT -- apply durability to drills properly

///// OCCULUS EDIT -- handy verb to prevent copy/pasting durability in each New proc
/obj/item/material/drill_head/verb/ApplyDurability()
	durability = 2 * (material ? material.integrity : 1)

/obj/item/mech_equipment/drill
	name = "drill"
	desc = "This is the drill that'll pierce the heavens!"
	icon_state = "mech_drill"
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_UTILITY)
	equipment_delay = 10

	//Drill can have a head
	var/obj/item/material/drill_head/drill_head
	origin_tech = list(TECH_MATERIAL = 2, TECH_ENGINEERING = 2)



/obj/item/mech_equipment/drill/Initialize()
	. = ..()
	drill_head = new /obj/item/material/drill_head(src, "steel")//You start with a basic steel head
	drill_head.ApplyDurability()	// OCCULUS EDIT -- apply durability to drills properly

/obj/item/mech_equipment/drill/attack_self(var/mob/user)
	. = ..()
	if(.)
		if(drill_head)
			owner.visible_message(SPAN_WARNING("[owner] revs the [drill_head], menancingly."))
			playsound(src, 'sound/weapons/circsawhit.ogg', 50, 1)


/obj/item/mech_equipment/drill/afterattack(var/atom/target, var/mob/living/user, var/inrange, var/params)
	. = ..()
	if(.)

		///// OCCULUS EDIT START
		// Mechs did not check if they were actually in range before trying to use drills or clamps.
		// The proc has been adjusted with the following clause in mind.

		if (!inrange)
			to_chat(user, SPAN_NOTICE("You must be adjacent to [target] to use the mounted drill."))
			return
		else
			if(isobj(target))
				var/obj/target_obj = target
				if(target_obj.unacidable)
					return
			if(istype(target,/obj/item/material/drill_head))
				var/obj/item/material/drill_head/DH = target
				if(drill_head)
					owner.visible_message(SPAN_NOTICE("\The [owner] detaches the [drill_head] mounted on the [src]."))
					drill_head.forceMove(owner.loc)
				DH.forceMove(src)
				drill_head = DH
				owner.visible_message(SPAN_NOTICE("\The [owner] mounts the [drill_head] on the [src]."))
				return

			if(drill_head == null)
				to_chat(user, SPAN_WARNING("Your drill doesn't have a head!"))
				return

			var/obj/item/cell/C = owner.get_cell()
			if(istype(C))
				C.use(active_power_use * CELLRATE)
			playsound(src, 'sound/weapons/circsawhit.ogg', 50, 1)	// OCCULUS EDIT: More feedback for drilling
			owner.visible_message("<span class='danger'>\The [owner] starts to drill \the [target]</span>", "<span class='warning'>You hear a large drill.</span>")

			var/T = target.loc

			//Better materials = faster drill!
			var/delay = 20//max(5, 20 - drill_head.material.brute_armor)
			owner.setClickCooldown(delay) //Don't spamclick!
			if(do_after(owner, delay, target) && drill_head)
				if(src == owner.selected_system)
					if(drill_head.durability <= 0)
						drill_head.shatter()
						drill_head = null
						return
					if(istype(target, /turf/simulated/wall))
						var/turf/simulated/wall/W = target
						if(max(W.material.hardness, W.reinf_material ? W.reinf_material.hardness : 0) > drill_head.material.hardness)
							to_chat(user, "<span class='warning'>\The [target] is too hard to drill through with this drill head.</span>")
						target.ex_act(2)
						pickupore(target)
						drill_head.durability -= 1
						log_and_message_admins("used [src] on the wall [W].", user, owner.loc)
					else if(istype(target, /turf/simulated/mineral))
						for(var/turf/simulated/mineral/M in range(target,1))
							if(get_dir(owner,M)&owner.dir)
								M.GetDrilled()
								pickupore(M)
								drill_head.durability -= 1
					else if(istype(target, /turf/simulated/floor/asteroid))
						for(var/turf/simulated/floor/asteroid/M in range(target,1))
							if(get_dir(owner,M)&owner.dir)
								M.gets_dug()
								pickupore(M)
								drill_head.durability -= 1
					else if(target.loc == T)
						target.ex_act(2)
						drill_head.durability -= 1
						log_and_message_admins("[src] used to drill [target].", user, owner.loc)

					playsound(src, 'sound/weapons/rapidslice.ogg', 50, 1) // OCCULUS EDIT: more impactful noise

			else
				to_chat(user, "You must stay still while the drill is engaged!")


			return 1

/obj/item/mech_equipment/drill/proc/pickupore(var/turf/simulated/target)
	if(owner.hardpoints.len) //if this isn't true the drill should not be working to be fair
		for(var/hardpoint in owner.hardpoints)
			var/obj/item/I = owner.hardpoints[hardpoint]
			if(!istype(I))
				continue
			var/obj/structure/ore_box/ore_box = locate(/obj/structure/ore_box) in I //clamps work, but anythin that contains an ore crate internally is valid
			if(ore_box)
				for(var/obj/item/ore/ore in target.contents)
					ore.Move(ore_box)
					CHECK_TICK
		///// OCCULUS EDIT END

/obj/item/mech_equipment/mounted_system/extinguisher
	icon_state = "mech_exting"
	holding_type = /obj/item/extinguisher/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_UTILITY)

/obj/item/extinguisher/mech
	max_water = 4000 //Good is gooder
	icon_state = "mech_exting"
	overlaylist = list()
	spawn_frequency = 0

/obj/item/extinguisher/mech/get_hardpoint_maptext()
	return "[reagents.total_volume]/[max_water]"

/obj/item/extinguisher/mech/get_hardpoint_status_value()
	return reagents.total_volume/max_water
