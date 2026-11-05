extends GutTest


func test_bake_property_should_have_size_and_band_color() -> void:
	var space := BoardSpace.make_property("Cedar Lane", 0, 60, 6)
	var image := DistrictTileBaker.bake_image(space)
	assert_eq(image.get_width(), DistrictTileBaker.WIDTH)
	assert_eq(image.get_height(), DistrictTileBaker.HEIGHT)
	var center := image.get_pixel(DistrictTileBaker.WIDTH / 2, DistrictTileBaker.HEIGHT / 2)
	assert_gt(center.a, 0.5)
	# Color band sits along the outer (top) edge.
	var band := image.get_pixel(DistrictTileBaker.WIDTH / 2, 12)
	var expected := DistrictTileBaker.group_color(0)
	assert_gt(band.a, 0.5)
	assert_lt(absf(band.r - expected.r), 0.2)
	assert_lt(absf(band.g - expected.g), 0.2)
	assert_lt(absf(band.b - expected.b), 0.2)


func test_bake_go_should_be_corner_square() -> void:
	var space := BoardSpace.make_go("Plaza Gate")
	var image := DistrictTileBaker.bake_image(space)
	assert_eq(image.get_width(), DistrictTileBaker.CORNER_SIZE)
	assert_eq(image.get_height(), DistrictTileBaker.CORNER_SIZE)
	assert_gt(image.get_pixel(DistrictTileBaker.CORNER_SIZE / 2, DistrictTileBaker.CORNER_SIZE / 2).a, 0.5)
	assert_true(DistrictTileBaker.is_corner_kind(BoardSpace.KIND_GO))


func test_bake_tax_should_include_opaque_face() -> void:
	var space := BoardSpace.make_tax("City Levy", 100)
	var image := DistrictTileBaker.bake_image(space)
	assert_gt(image.get_pixel(DistrictTileBaker.WIDTH / 2, DistrictTileBaker.HEIGHT / 2).a, 0.5)


func test_bake_property_should_draw_ink_near_label() -> void:
	var space := BoardSpace.make_property("Cedar Lane", 1, 100, 10)
	var image := DistrictTileBaker.bake_image(space)
	var face := Color(0.96, 0.95, 0.9, 1)
	var found_ink := false
	for y in range(40, 90):
		for x in range(8, DistrictTileBaker.WIDTH - 8):
			var px := image.get_pixel(x, y)
			if px.a < 0.5:
				continue
			if absf(px.r - face.r) > 0.12 or absf(px.g - face.g) > 0.12 or absf(px.b - face.b) > 0.12:
				found_ink = true
				break
		if found_ink:
			break
	assert_true(found_ink)
