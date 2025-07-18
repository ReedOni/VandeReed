#define BP_MAX_ROOM_SIZE 300

// Gets an atmos isolated contained space
// Returns an associative list of turf|dirs pairs
// The dirs are connected turfs in the same space
// break_if_found is a typecache of turf/area types to return false if found
// Please keep this proc type agnostic. If you need to restrict it do it elsewhere or add an arg.
/proc/detect_room(turf/origin, list/break_if_found, max_size=INFINITY)
	if(origin.blocks_air)
		return list(origin)

	. = list()
	var/list/checked_turfs = list()
	var/list/found_turfs = list(origin)
	while(length(found_turfs))
		var/turf/sourceT = found_turfs[1]
		found_turfs.Cut(1, 2)
		var/dir_flags = checked_turfs[sourceT]
		for(var/dir in GLOB.alldirs)
			if(length(.) > max_size)
				return
			if(dir_flags & dir) // This means we've checked this dir before, probably from the other turf
				continue
			var/turf/checkT = get_step(sourceT, dir)
			if(!checkT)
				continue
			checked_turfs[sourceT] |= dir
			checked_turfs[checkT] |= turn(dir, 180)
			.[sourceT] |= dir
			.[checkT] |= turn(dir, 180)
			if(break_if_found[checkT.type] || break_if_found[checkT.loc.type])
				return FALSE
			var/static/list/cardinal_cache = list("[NORTH]"=TRUE, "[EAST]"=TRUE, "[SOUTH]"=TRUE, "[WEST]"=TRUE)
			if(!cardinal_cache["[dir]"] || checkT.blocks_air || !CANATMOSPASS(sourceT, checkT))
				continue
			found_turfs += checkT // Since checkT is connected, add it to the list to be processed

/proc/create_area(mob/creator)
	// Passed into the above proc as list/break_if_found
	var/static/area_or_turf_fail_types = typecacheof(list(
		))
	// Ignore these areas and dont let people expand them. They can expand into them though
	var/static/blacklisted_areas = typecacheof(list(
		/area/space,
		))
	var/list/turfs = detect_room(get_turf(creator), area_or_turf_fail_types, BP_MAX_ROOM_SIZE*2)
	if(!turfs)
		to_chat(creator, "<span class='warning'>The new area must be completely airtight.</span>")
		return
	if(length(turfs) > BP_MAX_ROOM_SIZE)
		to_chat(creator, "<span class='warning'>The room you're in is too big. It is [length(turfs) >= BP_MAX_ROOM_SIZE *2 ? "more than 100" : ((length(turfs) / BP_MAX_ROOM_SIZE)-1)*100]% larger than allowed.</span>")
		return
	var/list/areas = list("New Area" = /area)
	for(var/i in 1 to length(turfs))
		var/area/place = get_area(turfs[i])
		if(blacklisted_areas[place.type])
			continue
		if(place.area_flags & (NO_TELEPORT|HIDDEN_AREA))
			continue // No expanding powerless rooms etc
		areas[place.name] = place
	var/area_choice = browser_input_list(creator, "Choose an area to expand or make a new area.", "Area Expansion", areas)
	area_choice = areas[area_choice]

	if(!area_choice)
		to_chat(creator, "<span class='warning'>No choice selected. The area remains undefined.</span>")
		return
	var/area/newA
	var/area/oldA = get_area(get_turf(creator))
	if(!isarea(area_choice))
		var/str = stripped_input(creator,"New area name:", "Blueprint Editing", "", MAX_NAME_LEN)
		if(!str || !length(str)) //cancel
			return
		if(length(str) > 50)
			to_chat(creator, "<span class='warning'>The given name is too long. The area remains undefined.</span>")
			return
		newA = new area_choice
		newA.setup(str)
		newA.set_dynamic_lighting()
		newA.has_gravity = oldA.has_gravity
	else
		newA = area_choice

	/**
	 * A list of all machinery tied to an area along with the area itself. key=area name,value=list(area,list of machinery)
	 * we use this to keep track of what areas are affected by the blueprints & what machinery of these areas needs to be reconfigured accordingly
	 */
	var/list/area/affected_areas = list()
	for(var/turf/the_turf as anything in turfs)
		var/area/old_area = the_turf.loc

		//keep rack of all areas affected by turf changes
		affected_areas[old_area.name] = old_area

		//move the turf to its new area and unregister it from the old one
		the_turf.change_area(old_area, newA)

		//inform atoms on the turf that their area has changed
		for(var/atom/stuff as anything in the_turf)
			//unregister the stuff from its old area
			SEND_SIGNAL(stuff, COMSIG_EXIT_AREA, old_area)

			SEND_SIGNAL(stuff, COMSIG_ENTER_AREA, newA)
		the_turf.change_area(old_area, newA)

	newA.reg_in_areas_in_z()

	to_chat(creator, "<span class='notice'>I have created a new area, named [newA.name]. It is now weather proof, and constructing an APC will allow it to be powered.</span>")
	return TRUE

#undef BP_MAX_ROOM_SIZE
