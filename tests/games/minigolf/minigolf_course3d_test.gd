extends "res://addons/gut/test.gd"


func test_wall_yaw_should_align_box_x_with_segment() -> void:
	## Local +X → world +X when delta is along +X.
	assert_almost_eq(Course3D.yaw_for_xz_delta(Vector2(2, 0)), 0.0, 0.001)
	## Local +X → world +Z when delta is along +Z (Vector2.y).
	assert_almost_eq(Course3D.yaw_for_xz_delta(Vector2(0, 2)), -PI * 0.5, 0.001)
	assert_almost_eq(Course3D.yaw_for_xz_delta(Vector2(0, -2)), PI * 0.5, 0.001)
