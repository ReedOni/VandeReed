/turf/open/transparent
	baseturfs = /turf/open/transparent/openspace
	intact = FALSE //this means wires go on top


/turf/open/transparent/Initialize() // handle plane and layer here so that they don't cover other obs/turfs in Dream Maker
	. = ..()
	plane = OPENSPACE_PLANE
	layer = OPENSPACE_LAYER

	return INITIALIZE_HINT_LATELOAD

/turf/open/transparent/LateInitialize()
	update_multiz(TRUE, TRUE)

/turf/open/transparent/Destroy()
	vis_contents.len = 0
	return ..()

/turf/open/transparent/update_multiz(prune_on_fail = FALSE, init = FALSE)
	. = ..()
	var/turf/T = GET_TURF_BELOW(src)
	if(!T)
		vis_contents.len = 0
		if(!show_bottom_level() && prune_on_fail) //If we cant show whats below, and we prune on fail, change the turf to plating as a fallback
			ChangeTurf(/turf/open/floor/naturalstone, flags = CHANGETURF_INHERIT_AIR)
		return FALSE
	if(init)
		vis_contents += T
	return TRUE

/turf/open/transparent/multiz_turf_del(turf/T, dir)
	if(dir != DOWN)
		return
	update_multiz()

/turf/open/transparent/multiz_turf_new(turf/T, dir)
	if(dir != DOWN)
		return
	update_multiz()

///Called when there is no real turf below this turf
/turf/open/transparent/proc/show_bottom_level()
	var/turf/path = SSmapping.level_trait(z, ZTRAIT_BASETURF) || /turf/open/floor/naturalstone
	if(!ispath(path))
		path = text2path(path)
		if(!ispath(path))
			warning("Z-level [z] has invalid baseturf '[SSmapping.level_trait(z, ZTRAIT_BASETURF)]'")
			path = /turf/open/floor/naturalstone
	var/mutable_appearance/underlay_appearance = mutable_appearance(initial(path.icon), initial(path.icon_state), layer = TURF_LAYER, plane = SPACE_PLANE)
	underlays += underlay_appearance
	return TRUE
