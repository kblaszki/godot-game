extends "res://addons/gut/test.gd"


func test_null_audio_play_should_not_error() -> void:
	var audio := NullAudio.new()
	audio.play(&"eat")
	audio.play(&"die", 0.25)
	pass_test("NullAudio.play is a no-op")


func test_audio_spy_should_record_calls() -> void:
	var spy := AudioSpy.new()
	spy.play(&"eat", 0.5)
	spy.play(&"die")
	assert_eq(spy.calls.size(), 2)
	assert_eq(spy.calls[0]["id"], &"eat")
	assert_eq(spy.calls[0]["volume"], 0.5)
	assert_eq(spy.calls[1]["id"], &"die")
	assert_eq(spy.calls[1]["volume"], 1.0)
