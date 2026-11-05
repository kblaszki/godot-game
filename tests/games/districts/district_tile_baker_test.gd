extends GutTest


func test_bake_property_should_have_size_and_band_color() -> void:
	var space := BoardSpace.make_property("Cedar Lane", 0, 60, 6)
	var image := DistrictTileBaker.bake_image(space)
	assert_eq(image.get_width(), DistrictTileBaker.WIDTH)
	assert_eq(image.get_height(), DistrictTileBaker.HEIGHT)
	var center := image.get_pixel(DistrictTileBaker.WIDTH / 2, DistrictTileBaker.HEIGHT / 2)
	assert_gt(center.a, 0.5)
	# Band sits in the upper third of the diamond.
	var band := image.get_pixel(DistrictTileBaker.WIDTH / 2, 28)
	var expected := DistrictTileBaker.group_color(0)
	assert_gt(band.a, 0.5)
	assert_lt(absf(band.r - expected.r), 0.2)
	assert_lt(absf(band.g - expected.g), 0.2)
	assert_lt(absf(band.b - expected.b), 0.2)


func test_bake_go_should_fill_interior() -> void:
	var space := BoardSpace.make_go("Plaza Gate")
	var tex := DistrictTileBaker.bake(space)
	assert_eq(tex.get_width(), DistrictTileBaker.WIDTH)
	assert_eq(tex.get_height(), DistrictTileBaker.HEIGHT)
	var image := tex.get_image()
	assert_gt(image.get_pixel(DistrictTileBaker.WIDTH / 2, DistrictTileBaker.HEIGHT / 2).a, 0.5)
	assert_lt(image.get_pixel(2, 2).a, 0.1)


func test_bake_tax_should_include_opaque_face() -> void:
	var space := BoardSpace.make_tax("City Levy", 100)
	var image := DistrictTileBaker.bake_image(space)
	assert_gt(image.get_pixel(DistrictTileBaker.WIDTH / 2, DistrictTileBaker.HEIGHT / 2).a, 0.5)


func test_bake_property_should_draw_ink_near_label() -> void:
	var space := BoardSpace.make_property("Cedar Lane", 1, 100, 10)
	var image := DistrictTileBaker.bake_image(space)
	var face := Color(0.93, 0.91, 0.84, 1)
	var found_ink := false
	for y in range(48, 72):
		for x in range(60, 132):
			var px := image.get_pixel(x, y)
			if px.a < 0.5:
				continue
			if absf(px.r - face.r) > 0.12 or absf(px.g - face.g) > 0.12 or absf(px.b - face.b) > 0.12:
				found_ink = true
				break
		if found_ink:
			break
	assert_true(found_ink)
