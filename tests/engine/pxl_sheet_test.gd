extends "res://addons/gut/test.gd"

const SAMPLE_SHEET := """
{
  "frames": {
    "slime": {
      "frame": { "x": 0, "y": 0, "w": 16, "h": 10 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 16, "h": 10 },
      "sourceSize": { "w": 16, "h": 10 }
    },
    "slime_red": {
      "frame": { "x": 17, "y": 0, "w": 16, "h": 10 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 16, "h": 10 },
      "sourceSize": { "w": 16, "h": 10 }
    },
    "heart": {
      "frame": { "x": 0, "y": 11, "w": 9, "h": 9 },
      "duration": 200
    }
  },
  "meta": {
    "app": "pxl",
    "image": "demo_sprites.png",
    "size": { "w": 40, "h": 20 },
    "frameTags": [
      { "name": "slimes", "from": 0, "to": 1, "direction": "forward" }
    ]
  }
}
"""

const SAMPLE_ANIM := """
{
  "frames": {
    "coin_spin_0": { "frame": { "x": 0, "y": 0, "w": 10, "h": 10 }, "duration": 125 },
    "coin_spin_1": { "frame": { "x": 10, "y": 0, "w": 10, "h": 10 }, "duration": 125 },
    "coin_spin_2": { "frame": { "x": 20, "y": 0, "w": 10, "h": 10 }, "duration": 125 },
    "coin_spin_3": { "frame": { "x": 30, "y": 0, "w": 10, "h": 10 }, "duration": 125 }
  },
  "meta": {
    "app": "pxl",
    "image": "coin_spin.png",
    "frameTags": [
      { "name": "coin_spin", "from": 0, "to": 3, "direction": "forward" }
    ]
  }
}
"""


func test_parse_should_read_rects_and_default_duration() -> void:
	var sheet := PxlSheet.parse(SAMPLE_SHEET)
	assert_true(sheet.is_valid(), "sheet should be valid")
	var names := sheet.frame_names()
	assert_eq(names.size(), 3)
	assert_eq(String(names[0]), "slime")
	assert_eq(sheet.frame_rect(&"slime"), Rect2i(0, 0, 16, 10))
	assert_eq(sheet.frame_rect(&"slime_red"), Rect2i(17, 0, 16, 10))
	assert_eq(sheet.frame_duration_ms(&"slime"), PxlSheet.DEFAULT_DURATION_MS)
	assert_eq(sheet.frame_duration_ms(&"heart"), 200)


func test_tag_frames_should_expand_in_order() -> void:
	var sheet := PxlSheet.parse(SAMPLE_SHEET)
	var tagged := sheet.tag_frames(&"slimes")
	assert_eq(tagged.size(), 2)
	assert_eq(String(tagged[0]), "slime")
	assert_eq(String(tagged[1]), "slime_red")
	assert_eq(sheet.tag_frames(&"missing").size(), 0)


func test_anim_tag_should_cover_all_frames() -> void:
	var sheet := PxlSheet.parse(SAMPLE_ANIM)
	assert_true(sheet.is_valid())
	var frames := sheet.tag_frames(&"coin_spin")
	assert_eq(frames.size(), 4)
	assert_eq(sheet.frame_duration_ms(&"coin_spin_0"), 125)
	assert_eq(sheet.frame_rect(&"coin_spin_3"), Rect2i(30, 0, 10, 10))


func test_invalid_json_should_not_be_valid() -> void:
	assert_false(PxlSheet.parse("").is_valid())
	assert_false(PxlSheet.parse("{not json").is_valid())
	assert_false(PxlSheet.parse("{\"frames\":[]}").is_valid())
	assert_false(PxlSheet.parse("{\"frames\":{}}").is_valid())
