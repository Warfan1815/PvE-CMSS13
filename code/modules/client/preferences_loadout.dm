/datum/loadout
	var/job = ""

	var/list/listed_items = list()
	var/list/categories = list()

	var/instanced_points = 0
	var/available_points_to_display = 0
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
	.["vendor_name"] = job
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
Squad
*/
