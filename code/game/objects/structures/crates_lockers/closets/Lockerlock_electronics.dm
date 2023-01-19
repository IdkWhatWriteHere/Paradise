//замок//
/obj/structures/crates_lockers/closets/Lockerlock_electronics
	name = "Замок для шкафчика"
	desc = "стандартный замок для размещения на шкаф, сделает вам немного личного пространства"
	icon = 'icons/obj/'
	icon_state = "спрайта нет"
	w_class = WEIGHT_CLASS_SMALL
	toolspeed = 1

		mount_requirements = MOUNTED_FRAME_SIMFLOOR | MOUNTED_FRAME_NOSPACE

/obj/structures/crates_lockers/closets/Lockerlock_electronics/do_build(obj/structure/closet, mob/user)
	new /obj/structure/closet/secure_closet/personal(obj/structure/closet, TRUE)
	qdel(src)
