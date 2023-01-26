#define CONSTRUCTION_COMPLETE 0 //No construction done - functioning as normal
#define CONSTRUCTION_PANEL_OPEN 1 //Maintenance panel is open, still functioning
#define CONSTRUCTION_WIRES_EXPOSED 2 //Cover plate is removed, wires are available
#define CONSTRUCTION_GUTTED 3 //Wires are removed, circuit ready to remove
#define CONSTRUCTION_NOCIRCUIT 4 //Circuit board removed, can safely weld apart

var/constructionStep = null
var/registered_name = null
/obj/structures/crates_lockers/closet/secure/personal
	desc = "It's a secure locker for personnel. The first card swiped gains control."
	name = "personal closet"
	req_access = list(ACCESS_ALL_PERSONAL_LOCKERS)
	var/registered_name = null
	var/constructionStep = CONSTRUCTION_COMPLETE

//установка замка
/obj/structures/crates_lockers/closet/secure/personal/examine(mob/user)
	. = ..()
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			. += "<span class='notice'>крышка плотно прикручена.</span>"
		if(CONSTRUCTION_WIRES_EXPOSED)
			. += "<span class='notice'>крышка откручена, видны провода.</span>"
		if(CONSTRUCTION_GUTTED)
			. += "<span class='notice'>крышка откручена, видна плата.</span>"
		if(CONSTRUCTION_NOCIRCUIT)
			. += "<span class='notice'>крышка откручена, нет проводов и платы, можно убрать замок.</span>"

/obj/structures/crates_lockers/closet/secure/personal/update_icon()
	..()
	icon_state = "closet[constructionStep]"

/obj/structures/crates_lockers/closet/secure/personal/attackby(obj/item/C, mob/user)
	switch(constructionStep)
		if(CONSTRUCTION_NOCIRCUIT)
			if(istype(C, /obj/item/Lockerlock_electronics))
				user.visible_message("<span class='notice'>[user] начал устанавливать [C] в [src]...</span>", \
									 "<span class='notice'>ты начал установку платы в [src]...</span>")
				playsound(get_turf(src), C.usesound, 50, 1)
				if(!do_after(user, 40 * C.toolspeed, target = src))
					return
				if(constructionStep != CONSTRUCTION_NOCIRCUIT)
					return
				user.drop_item()
				qdel(C)
				user.visible_message("<span class='notice'>[user] уставновил плату в [src].</span>", \
									 "<span class='notice'>ты установил и закрепил [C].</span>")
				playsound(get_turf(src), C.usesound, 50, 1)
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
		if(CONSTRUCTION_GUTTED)
			if(iscoil(C))
				var/obj/item/stack/cable_coil/B = C
				if(B.get_amount() < 5)
					to_chat(user, "<span class='warning'>тебе нужно больше кабелей [src].</span>")
					return
				user.visible_message("<span class='notice'>[user] начал подключать [src]...</span>", \
									 "<span class='notice'>ты начал подключать провода к [src]...</span>")
				playsound(get_turf(src), B.usesound, 50, 1)
				if(do_after(user, 60 * B.toolspeed, target = src))
					if(constructionStep != CONSTRUCTION_GUTTED || B.get_amount() < 5 || !B)
						return
					user.visible_message("<span class='notice'>[user] подключил [src].</span>", \
										 "<span class='notice'>Ты подключил провода к [src].</span>")
					playsound(get_turf(src), B.usesound, 50, 1)
					B.use(5)
					constructionStep = CONSTRUCTION_WIRES_EXPOSED
					update_icon()
				return
	return ..()

/obj/structure/closet/secure_closet/personal/crowbar_act(mob/user, obj/item/I)
	if(constructionStep == CONSTRUCTION_GUTTED)
		return
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	if(constructionStep == CONSTRUCTION_GUTTED)
		user.visible_message("<span class='notice'>[user] начал доставать плату из [src]...</span>", \
							 "<span class='notice'>ты начал доставать плату из [src]...</span>")
		if(!I.use_tool(src, user, 50, volume = I.tool_volume))
			return
		if(constructionStep != CONSTRUCTION_GUTTED)
			return
		user.visible_message("<span class='notice'>[user] достал плату из [src].</span>", \
							 "<span class='notice'>ты достал плату из [src], теперь можно снять замок.</span>")
		constructionStep = CONSTRUCTION_NOCIRCUIT
	update_icon()

/obj/structure/closet/secure_closet/personal/wirecutter_act(mob/user, obj/item/I)
	if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
		return
	. = TRUE
	if(!I.tool_start_check(src, user, 0))
		return

	user.visible_message("<span class='notice'>[user] starts cutting the wires from [src]...</span>", \
						 "<span class='notice'>You begin removing [src]'s wires...</span>")
	if(!I.use_tool(src, user, 50, volume = I.tool_volume))
		return
	if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
		return
	user.visible_message("<span class='notice'>[user] removes the wires from [src].</span>", \
						 "<span class='notice'>You remove the wiring from [src], exposing the circuit board.</span>")
	var/obj/item/stack/cable_coil/B = new(get_turf(src))
	B.amount = 5
	constructionStep = CONSTRUCTION_GUTTED
	update_icon()

/obj/structure/closet/secure_closet/personal/screwdriver_act(mob/user, obj/item/I)
	if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
		return
	. = TRUE
	if(!I.tool_start_check(src, user, 0))
		return

	user.visible_message("<span class='notice'>[user] начал закручивать панель [src]...</span>", \
						 "<span class='notice'>ты начал закручивать панель [src]...</span>")
	if(!I.use_tool(src, user, 50, volume = I.tool_volume))
		return
	if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
		return
	user.visible_message("<span class='notice'>[user] закрутил панель [src].</span>", \
						 "<span class='notice'>ты закрутил панель [src], завершая сборку.</span>")
	constructionStep = CONSTRUCTION_PANEL_OPEN
	update_icon()
	if(constructionStep != CONSTRUCTION_PANEL_OPEN)
		return
	. = TRUE
	if(!I.tool_start_check(src, user, 0))
		return

	user.visible_message("<span class='notice'>[user] начал откручивать панель [src]...</span>", \
						 "<span class='notice'>ты начал откручивать панель панель [src]...</span>")
	if(!I.use_tool(src, user, 50, volume = I.tool_volume))
		return
	if(constructionStep != CONSTRUCTION_PANEL_OPEN)
		return
	user.visible_message("<span class='notice'>[user] открутил панель [src].</span>", \
						 "<span class='notice'>ты открутил панель [src], внутри видны провода.</span>")
	constructionStep = CONSTRUCTION_PANEL_OPEN
	update_icon()
/obj/structure/closet/secure_closet/personal/welder_act(mob/user, obj/item/I)
	if(constructionStep != CONSTRUCTION_NOCIRCUIT)
		return
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	WELDER_ATTEMPT_SLICING_MESSAGE
	if(!I.use_tool(src, user, 40, amount = 1, volume = I.tool_volume))
		return
	if(constructionStep != CONSTRUCTION_NOCIRCUIT)
		return
	WELDER_SLICING_SUCCESS_MESSAGE
	new /obj/structure/closet
	new /obj/item/Lockerlock_electronics
	qdel(src)

/obj/structure/closet/secure_closet/personal/populate_contents()
	if(prob(50))
		new /obj/item/storage/backpack/duffel(src)
	if(prob(50))
		new /obj/item/storage/backpack(src)
	else
		new /obj/item/storage/backpack/satchel_norm(src)
	new /obj/item/radio/headset(src)

/obj/structure/closet/secure_closet/personal/patient
	name = "patient's closet"

/obj/structure/closet/secure_closet/personal/patient/populate_contents()
	new /obj/item/clothing/under/color/white(src)
	new /obj/item/clothing/shoes/white(src)

/obj/structure/closet/secure_closet/personal/mining
	name = "personal miner's locker"

/obj/structure/closet/secure_closet/personal/mining/populate_contents()
	new /obj/item/stack/sheet/cardboard(src)

/obj/structure/closet/secure_closet/personal/cabinet
	icon_state = "cabinetdetective_locked"
	icon_closed = "cabinetdetective"
	icon_locked = "cabinetdetective_locked"
	icon_opened = "cabinetdetective_open"
	icon_broken = "cabinetdetective_broken"
	icon_off = "cabinetdetective_broken"
	resistance_flags = FLAMMABLE
	max_integrity = 70

/obj/structure/closet/secure_closet/personal/cabinet/update_icon()
	if(broken)
		icon_state = icon_broken
	else
		if(!opened)
			if(locked)
				icon_state = icon_locked
			else
				icon_state = icon_closed
		else
			icon_state = icon_opened

/obj/structure/closet/secure_closet/personal/cabinet/populate_contents()
	new /obj/item/storage/backpack/satchel/withwallet(src)
	new /obj/item/radio/headset(src)

/obj/structure/closet/secure_closet/personal/attackby(obj/item/W, mob/user, params)
	if(opened || !W.GetID())
		return ..()

	if(broken)
		to_chat(user, "<span class='warning'>It appears to be broken.</span>")
		return

	var/obj/item/card/id/I = W.GetID()
	if(!I || !I.registered_name)
		return

	if(src == user.loc)
		to_chat(user, "<span class='notice'>You can't reach the lock from inside.</span>")

	else if(allowed(user) || !registered_name || (istype(I) && (registered_name == I.registered_name)))
		//they can open all lockers, or nobody owns this, or they own this locker
		locked = !locked
		if(locked)
			icon_state = icon_locked
		else
			icon_state = icon_closed
			registered_name = null
			desc = initial(desc)

		if(!registered_name && locked)
			registered_name = I.registered_name
			desc = "Owned by [I.registered_name]."
	else
		to_chat(user, "<span class='warning'>Access Denied</span>")

#undef CONSTRUCTION_COMPLETE
#undef CONSTRUCTION_PANEL_OPEN
#undef CONSTRUCTION_WIRES_EXPOSED
#undef CONSTRUCTION_GUTTED
#undef CONSTRUCTION_NOCIRCUIT
