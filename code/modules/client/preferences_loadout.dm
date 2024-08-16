/datum/loadout
	var/job = ""

	var/scale = 1
	var/list/listed_items = list()
	var/list/categories = list()

	var/instanced_points = 45
	var/show_points = TRUE

/*
TGUI Procs
*/

/datum/loadout/ui_data(mob/user)
	. = list()
	var/list/ui_listed_items = get_listed_items(user)
	// list format
	// (
	// name: str
	// cost
	// item reference
	// allowed to buy flag
	// item priority (mandatory/recommended/regular)
	// )

	var/list/stock_values = list()
	var/points = LOADOUT_TOTAL_BUY_POINTS

	for (var/i in 1 to length(ui_listed_items))
		var/list/myprod = ui_listed_items[i] //we take one list from listed_items
		var/prod_available = FALSE
		var/p_cost = myprod[2]
		if(points >= p_cost)
			prod_available = TRUE
		stock_values += list(prod_available)

	.["stock_listing"] = stock_values
	.["current_m_points"] = points

/datum/loadout/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = usr
	switch (action)
		if ("vend")
			var/index=params["prod_index"]
			var/list/topic_listed_items = get_listed_items(user)
			var/list/itemspec = topic_listed_items[index]

			if(!handle_category(itemspec))
				to_chat(user, SPAN_WARNING("You can't select things from this category anymore."))
				return FALSE

			if(!handle_points(itemspec))
				to_chat(user, SPAN_WARNING("Not enough points."))
				return FALSE

			return TRUE

/datum/loadout/ui_static_data(mob/user)
	. = list()
	.["vendor_name"] = "Equipment"
	.["vendor_type"] = "sorted"
	.["theme"] = VENDOR_THEME_USCM
	.["show_points"] = TRUE
	.["displayed_categories"] = vendor_user_inventory_list(user, null, 4)

/datum/loadout/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/spritesheet/vending_products))

/datum/loadout/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "VendingSorted", job)
		ui.open()

/*
Helper procs
*/

/datum/loadout/proc/get_listed_items(mob/user)
	return listed_items

/datum/loadout/proc/vendor_user_inventory_list(mob/user, cost_index=2, priority_index=5)
	. = list()
	// default list format
	// (
	// name: str
	// cost
	// item reference
	// allowed to buy flag
	// item priority (mandatory/recommended/regular)
	// )
	var/list/ui_listed_items = get_listed_items(user)

	for (var/i in 1 to length(ui_listed_items))
		var/list/myprod = ui_listed_items[i] //we take one list from listed_items
		var/p_name = myprod[1] //taking it's name
		var/p_cost = cost_index == null ? 0 : myprod[cost_index]
		var/obj/item/item_ref = myprod[3]
		var/priority = myprod[priority_index]
		if(islist(item_ref)) // multi-vending
			item_ref = item_ref[1]

		var/is_category = item_ref == null

		var/imgid = replacetext(replacetext("[item_ref]", "/obj/item/", ""), "/", "-")
		//forming new list with index, name, amount, available or not, color and add it to display_list

		var/display_item = list(
			"prod_index" = i,
			"prod_name" = p_name,
			"prod_color" = priority,
			"prod_desc" = initial(item_ref.desc),
			"prod_cost" = p_cost,
			"image" = imgid
		)

		if (is_category == 1)
			. += list(list(
				"name" = p_name,
				"items" = list()
			))
			continue

		if (!LAZYLEN(.))
			. += list(list(
				"name" = "",
				"items" = list()
			))
		var/last_index = LAZYLEN(.)
		var/last_category = .[last_index]
		last_category["items"] += list(display_item)

/datum/loadout/proc/vendor_inventory_ui_data(mob/user)
	. = list()
	var/list/ui_listed_items = get_listed_items(user)
	var/list/ui_categories = list()

	for (var/i in 1 to length(ui_listed_items))
		var/list/myprod = ui_listed_items[i] //we take one list from listed_items
		var/p_amount = myprod[2] //amount left
		ui_categories += list(p_amount)
	.["stock_listing"] = ui_categories

/datum/loadout/proc/handle_points(list/itemspec)
	. = TRUE
	var/cost = itemspec[2]
	if(instanced_points)
		if(instanced_points < cost)
			return FALSE
		else
			instanced_points -= cost

/datum/loadout/proc/handle_category(list/listed_items)
	var/selected_category = listed_items[4]
	if(selected_category)
		if(!(selected_category in categories))
			return FALSE
		if(!categories[selected_category])
			return FALSE
		categories[selected_category] -= 1
	return TRUE

/*
========
Subtypes
========
*/

/*
/datum/loadout//New()
	. = ..()

	job =

	listed_items = list(

	)

	categories = list()
*/

/*
Squad
*/

/datum/loadout/rifleman/New()
	. = ..()

	job = JOB_SQUAD_MARINE

	listed_items = list(
		list("STANDARD EQUIPMENT", -1, null, null, null),
		list("Marine Combat Boots", round(scale * 15), /obj/item/clothing/shoes/marine/knife, VENDOR_ITEM_REGULAR),
		list("USCM Uniform", round(scale * 15), /obj/item/clothing/under/marine, VENDOR_ITEM_REGULAR),
		list("Marine Combat Gloves", round(scale * 15), /obj/item/clothing/gloves/marine, VENDOR_ITEM_REGULAR),
		list("M10 Pattern Marine Helmet", round(scale * 15), /obj/item/clothing/head/helmet/marine, VENDOR_ITEM_REGULAR),
		list("Marine Radio Headset", round(scale * 15), /obj/item/device/radio/headset/almayer/marine, VENDOR_ITEM_REGULAR),

		list("WEBBINGS", -1, null, null),
		list("Brown Webbing Vest", round(scale * 1.25), /obj/item/clothing/accessory/storage/black_vest/brown_vest, VENDOR_ITEM_REGULAR),
		list("Black Webbing Vest", round(max(1,(scale * 0.5))), /obj/item/clothing/accessory/storage/black_vest, VENDOR_ITEM_REGULAR),
		list("Webbing", round(scale * 2), /obj/item/clothing/accessory/storage/webbing, VENDOR_ITEM_REGULAR),
		list("Drop Pouch", round(max(1,(scale * 0.5))), /obj/item/clothing/accessory/storage/droppouch, VENDOR_ITEM_REGULAR),
		list("Shoulder Holster", round(max(1,(scale * 0.5))), /obj/item/clothing/accessory/storage/holster, VENDOR_ITEM_REGULAR),

		list("ARMOR", -1, null, null),
		list("M3 Pattern Carrier Marine Armor", round(scale * 15), /obj/item/clothing/suit/storage/marine/carrier, VENDOR_ITEM_REGULAR),
		list("M3 Pattern Padded Marine Armor", round(scale * 15), /obj/item/clothing/suit/storage/marine/padded, VENDOR_ITEM_REGULAR),
		list("M3 Pattern Padless Marine Armor", round(scale * 15), /obj/item/clothing/suit/storage/marine/padless, VENDOR_ITEM_REGULAR),
		list("M3 Pattern Ridged Marine Armor", round(scale * 15), /obj/item/clothing/suit/storage/marine/padless_lines, VENDOR_ITEM_REGULAR),
		list("M3 Pattern Skull Marine Armor", round(scale * 15), /obj/item/clothing/suit/storage/marine/skull, VENDOR_ITEM_REGULAR),
		list("M3 Pattern Smooth Marine Armor", round(scale * 15), /obj/item/clothing/suit/storage/marine/smooth, VENDOR_ITEM_REGULAR),
		list("M3-EOD Pattern Heavy Armor", round(scale * 10), /obj/item/clothing/suit/storage/marine/heavy, VENDOR_ITEM_REGULAR),
		list("M3-L Pattern Light Armor", round(scale * 10), /obj/item/clothing/suit/storage/marine/light, VENDOR_ITEM_REGULAR),

		list("BACKPACK", -1, null, null, null),
		list("Lightweight IMP Backpack", round(scale * 15), /obj/item/storage/backpack/marine, VENDOR_ITEM_REGULAR),
		list("USCM Technician Backpack", round(scale * 15), /obj/item/storage/backpack/marine/tech, VENDOR_ITEM_REGULAR),
		list("USCM Satchel", round(scale * 15), /obj/item/storage/backpack/marine/satchel, VENDOR_ITEM_REGULAR),
		list("Technician Chestrig", round(scale * 15), /obj/item/storage/backpack/marine/satchel/tech, VENDOR_ITEM_REGULAR),
		list("Shotgun Scabbard", round(scale * 5), /obj/item/storage/large_holster/m37, VENDOR_ITEM_REGULAR),

		list("RESTRICTED BACKPACKS", -1, null, null),
		list("Radio Telephone Backpack", round(max(1,(scale * 0.5))), /obj/item/storage/backpack/marine/satchel/rto, VENDOR_ITEM_REGULAR),

		list("BELTS", -1, null, null),
		list("M276 Pattern Ammo Load Rig", round(scale * 15), /obj/item/storage/belt/marine, VENDOR_ITEM_REGULAR),
		list("M276 Pattern M40 Grenade Rig", round(scale * 10), /obj/item/storage/belt/grenade, VENDOR_ITEM_REGULAR),
		list("M276 Pattern General Pistol Holster Rig", round(scale * 15), /obj/item/storage/belt/gun/m4a3, VENDOR_ITEM_REGULAR),
		list("M276 Pattern M44 Holster Rig", round(scale * 15), /obj/item/storage/belt/gun/m44, VENDOR_ITEM_REGULAR),
		list("M276 Pattern M82F Holster Rig", round(scale * 5), /obj/item/storage/belt/gun/flaregun, VENDOR_ITEM_REGULAR),
		list("M276 G8-A General Utility Pouch", round(scale * 15), /obj/item/storage/backpack/general_belt, VENDOR_ITEM_REGULAR),

		list("POUCHES", -1, null, null, null),
		list("First-Aid Pouch (Splints, Gauze, Ointment)", round(scale * 15), /obj/item/storage/pouch/firstaid/full/alternate, VENDOR_ITEM_REGULAR),
		list("First-Aid Pouch (Pill Packets)", round(scale * 15), /obj/item/storage/pouch/firstaid/full/pills, VENDOR_ITEM_REGULAR),
		list("First-Aid Pouch (Injectors)", round(scale * 15), /obj/item/storage/pouch/firstaid/full, VENDOR_ITEM_REGULAR),
		list("Flare Pouch (Full)", round(scale * 15), /obj/item/storage/pouch/flare/full, VENDOR_ITEM_REGULAR),
		list("Magazine Pouch", round(scale * 15), /obj/item/storage/pouch/magazine, VENDOR_ITEM_REGULAR),
		list("Shotgun Shell Pouch", round(scale * 15), /obj/item/storage/pouch/shotgun, VENDOR_ITEM_REGULAR),
		list("Medium General Pouch", round(scale * 15), /obj/item/storage/pouch/general/medium, VENDOR_ITEM_REGULAR),
		list("Pistol Magazine Pouch", round(scale * 15), /obj/item/storage/pouch/magazine/pistol, VENDOR_ITEM_REGULAR),
		list("Pistol Pouch", round(scale * 15), /obj/item/storage/pouch/pistol, VENDOR_ITEM_REGULAR),

		list("RESTRICTED POUCHES", -1, null, null, null),
		list("Construction Pouch", round(scale * 1.25), /obj/item/storage/pouch/construction, VENDOR_ITEM_REGULAR),
		list("Explosive Pouch", round(scale * 1.25), /obj/item/storage/pouch/explosive, VENDOR_ITEM_REGULAR),
		list("First Responder Pouch (Empty)", round(scale * 2.5), /obj/item/storage/pouch/first_responder, VENDOR_ITEM_REGULAR),
		list("Large Pistol Magazine Pouch", round(scale * 2), /obj/item/storage/pouch/magazine/pistol/large, VENDOR_ITEM_REGULAR),
		list("Tools Pouch", round(scale * 1.25), /obj/item/storage/pouch/tools, VENDOR_ITEM_REGULAR),
		list("Sling Pouch", round(scale * 1.25), /obj/item/storage/pouch/sling, VENDOR_ITEM_REGULAR),

		list("MASK", -1, null, null, null),
		list("Gas Mask", round(scale * 15), /obj/item/clothing/mask/gas, VENDOR_ITEM_REGULAR),
		list("Heat Absorbent Coif", round(scale * 10), /obj/item/clothing/mask/rebreather/scarf, VENDOR_ITEM_REGULAR),
		list("Rebreather", round(scale * 10), /obj/item/clothing/mask/rebreather, MARINE_CAN_BUY_MASK, VENDOR_ITEM_REGULAR),

		list("MISCELLANEOUS", -1, null, null, null),
		list("Ballistic goggles", round(scale * 10), /obj/item/clothing/glasses/mgoggles, VENDOR_ITEM_REGULAR),
		list("M1A1 Ballistic goggles", round(scale * 10), /obj/item/clothing/glasses/mgoggles/v2, VENDOR_ITEM_REGULAR),
		list("Prescription ballistic goggles", round(scale * 10), /obj/item/clothing/glasses/mgoggles/prescription, VENDOR_ITEM_REGULAR),
		list("Marine RPG glasses", round(scale * 10), /obj/item/clothing/glasses/regular, VENDOR_ITEM_REGULAR),
		list("M5 Integrated Gas Mask", round(scale * 10), /obj/item/prop/helmetgarb/helmet_gasmask, VENDOR_ITEM_REGULAR),
		list("M10 Helmet Netting", round(scale * 10), /obj/item/prop/helmetgarb/netting, VENDOR_ITEM_REGULAR),
		list("M10 Helmet Rain Cover", round(scale * 10), /obj/item/prop/helmetgarb/raincover, VENDOR_ITEM_REGULAR),
		list("Firearm Lubricant", round(scale * 15), /obj/item/prop/helmetgarb/gunoil, VENDOR_ITEM_REGULAR),
		list("USCM Flair", round(scale * 15), /obj/item/prop/helmetgarb/flair_uscm, VENDOR_ITEM_REGULAR),
		list("Solar Devils Shoulder Patch", round(scale * 15), /obj/item/clothing/accessory/patch/devils, VENDOR_ITEM_REGULAR),
		list("USCM Shoulder Patch", round(scale * 15), /obj/item/clothing/accessory/patch, VENDOR_ITEM_REGULAR),
		list("Bedroll", round(scale * 20), /obj/item/roller/bedroll, VENDOR_ITEM_REGULAR),
	)

	categories = list("STANDARD EQUIPMENT" = 1, "WEBBINGS" = 1, "ARMOR" = 1, "BACKPACK" = 1, "RESTRICTED BACKPACK" = 1, "BELTS" = 1, "POUCHES" = 1, "RESTRICTED POUCHES" = 1, "MASK" = 1, "MISCELLANEOUS" = 1)
