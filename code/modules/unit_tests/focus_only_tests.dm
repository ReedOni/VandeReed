/// These tests perform no behavior of their own, and have their tests offloaded onto other procs.
/// This is useful in cases like in build_appearance_list where we want to know if any fail,
/// but is not useful to write a test for.
/// This file exists so that you can change any of these to TEST_FOCUS and only check for that test.
/// For example, change /datum/unit_test/focus_only/invalid_overlays to TEST_FOCUS(/datum/unit_test/focus_only/invalid_overlays),
/// and you will only test the check for invalid overlays in appearance building.
/datum/unit_test/focus_only

/// Checks that every created emissive has a valid icon_state
/datum/unit_test/focus_only/invalid_emissives

/// Checks that smoothing_groups and smoothing_list are properly sorted in /atom/Initialize
/datum/unit_test/focus_only/sorted_smoothing_groups
