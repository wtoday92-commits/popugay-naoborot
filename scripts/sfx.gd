class_name Sfx
extends Node
## Звуки и музыка без ассетов: всё синтезируется кодом при старте.

const RATE := 22050
const VOICES := 14

var bank := {}
var players: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var next := 0
var muted := false
var _last := {}


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music = AudioStreamPlayer.new()
	add_child(music)
	_build()
	music.stream = _music_loop()
	music.volume_db = -14.0
	music.play()


func play(name: String, vol_db: float = 0.0, pitch: float = 1.0, min_gap: float = 0.03) -> void:
	if muted or not bank.has(name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(name, -1.0)) < min_gap:
		return
	_last[name] = now
	var p := players[next]
	next = (next + 1) % VOICES
	p.stream = bank[name]
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.play()


func set_muted(m: bool) -> void:
	muted = m
	music.stream_paused = m


func set_tension(k: float) -> void:
	music.pitch_scale = 1.0 + 0.12 * clampf(k, 0.0, 1.0)


# ---------- синтез ----------

static func _wav(buf: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w


static func _buf(dur: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(dur * RATE))
	b.fill(0.0)
	return b


## Тон со скольжением частоты: wave 0 синус, 1 треугольник, 2 пила, 3 квадрат.
static func _tone(b: PackedFloat32Array, t0: float, dur: float, f0: float, f1: float, amp: float, wave: int = 0, attack: float = 0.005, vib: float = 0.0) -> void:
	var s0 := int(t0 * RATE)
	var n := int(dur * RATE)
	var ph := 0.0
	for i in n:
		var idx := s0 + i
		if idx >= b.size():
			break
		var k := float(i) / float(n)
		var f := lerpf(f0, f1, k) * (1.0 + vib * sin(float(i) / RATE * TAU * 7.0))
		ph += f / RATE
		var x := ph - floorf(ph)
		var v := 0.0
		match wave:
			0:
				v = sin(x * TAU)
			1:
				v = 4.0 * absf(x - 0.5) - 1.0
			2:
				v = 2.0 * x - 1.0
			_:
				v = 1.0 if x < 0.5 else -1.0
		var env := minf(1.0, float(i) / maxf(1.0, attack * RATE)) * pow(1.0 - k, 2.0)
		b[idx] += v * amp * env


static func _noise(b: PackedFloat32Array, t0: float, dur: float, amp: float, lp0: float, lp1: float) -> void:
	var s0 := int(t0 * RATE)
	var n := int(dur * RATE)
	var y := 0.0
	for i in n:
		var idx := s0 + i
		if idx >= b.size():
			break
		var k := float(i) / float(n)
		var a := clampf(lerpf(lp0, lp1, k), 0.001, 1.0)
		y += a * (randf_range(-1.0, 1.0) - y)
		b[idx] += y * amp * pow(1.0 - k, 1.5) * minf(1.0, float(i) / 40.0)


## Колокольчик: несколько негармоничных обертонов с долгим затуханием.
static func _bell(b: PackedFloat32Array, t0: float, dur: float, f: float, amp: float) -> void:
	_tone(b, t0, dur, f, f, amp, 0, 0.002)
	_tone(b, t0, dur * 0.7, f * 2.76, f * 2.76, amp * 0.4, 0, 0.002)
	_tone(b, t0, dur * 0.5, f * 5.4, f * 5.4, amp * 0.2, 0, 0.002)


func _build() -> void:
	var b := _buf(0.07)
	_noise(b, 0.0, 0.03, 0.6, 0.9, 0.3)
	_tone(b, 0.0, 0.06, 1900.0, 800.0, 0.35, 1)
	bank["peck"] = _wav(b)

	b = _buf(0.12)
	_tone(b, 0.0, 0.1, 260.0, 120.0, 0.5, 0)
	_noise(b, 0.0, 0.05, 0.3, 0.5, 0.1)
	bank["hit"] = _wav(b)

	b = _buf(0.16)
	_tone(b, 0.0, 0.12, 500.0, 1100.0, 0.35, 1)
	_noise(b, 0.0, 0.1, 0.25, 0.4, 0.05)
	bank["pop"] = _wav(b)

	b = _buf(0.08)
	_tone(b, 0.0, 0.07, 1250.0, 1700.0, 0.3, 1)
	bank["pickup"] = _wav(b)

	b = _buf(0.5)
	for i in 4:
		_tone(b, i * 0.08, 0.2, [523.0, 659.0, 784.0, 1046.0][i], [523.0, 659.0, 784.0, 1046.0][i], 0.3, 1)
	bank["level"] = _wav(b)

	b = _buf(0.8)
	_bell(b, 0.0, 0.8, 880.0, 0.35)
	bank["chime"] = _wav(b)

	b = _buf(1.8)
	_tone(b, 0.0, 1.8, 98.0, 96.0, 0.45, 0, 0.002)
	_tone(b, 0.0, 1.4, 98.0 * 2.4, 98.0 * 2.4, 0.2, 0, 0.002)
	_tone(b, 0.0, 1.0, 98.0 * 3.1, 98.0 * 3.1, 0.15, 0, 0.002)
	_noise(b, 0.0, 0.08, 0.3, 0.3, 0.05)
	bank["gong"] = _wav(b)

	b = _buf(0.5)
	for i in 4:
		_bell(b, i * 0.06, 0.25, 2100.0 + i * 90.0, 0.18)
	bank["jingle"] = _wav(b)

	b = _buf(0.6)
	_noise(b, 0.0, 0.6, 0.35, 0.6, 0.03)
	bank["whoosh"] = _wav(b)

	b = _buf(0.4)
	_tone(b, 0.0, 0.3, 120.0, 45.0, 0.7, 0, 0.001)
	_noise(b, 0.0, 0.25, 0.5, 0.25, 0.02)
	bank["thud"] = _wav(b)

	b = _buf(0.2)
	_tone(b, 0.0, 0.07, 1500.0, 2300.0, 0.3, 2, 0.002, 0.03)
	_tone(b, 0.06, 0.12, 2300.0, 1300.0, 0.3, 2, 0.002, 0.05)
	bank["squawk"] = _wav(b)

	b = _buf(0.22)
	_noise(b, 0.0, 0.22, 0.3, 0.2, 0.7)
	bank["throw"] = _wav(b)

	b = _buf(0.12)
	_tone(b, 0.0, 0.1, 700.0, 1400.0, 0.25, 1)
	_noise(b, 0.0, 0.03, 0.3, 0.8, 0.5)
	bank["grab"] = _wav(b)

	b = _buf(0.35)
	_tone(b, 0.0, 0.3, 620.0, 600.0, 0.3, 3)
	_tone(b, 0.0, 0.25, 870.0, 860.0, 0.2, 0)
	_noise(b, 0.0, 0.05, 0.4, 0.9, 0.5)
	bank["trap"] = _wav(b)

	b = _buf(0.4)
	_tone(b, 0.0, 0.4, 160.0, 110.0, 0.3, 2, 0.01, 0.08)
	bank["rotten"] = _wav(b)

	b = _buf(0.45)
	for i in 3:
		_noise(b, i * 0.12, 0.05, 0.5, 0.9, 0.4)
	_tone(b, 0.36, 0.08, 1800.0, 2400.0, 0.2, 1)
	bank["egg"] = _wav(b)

	b = _buf(0.25)
	_tone(b, 0.0, 0.22, 280.0, 520.0, 0.35, 0)
	bank["bounce"] = _wav(b)

	b = _buf(0.7)
	for i in 4:
		_tone(b, i * 0.16, 0.14, 660.0 if i % 2 == 0 else 880.0, 660.0 if i % 2 == 0 else 880.0, 0.22, 1)
	bank["event"] = _wav(b)

	b = _buf(1.4)
	_tone(b, 0.0, 1.4, 55.0, 75.0, 0.35, 2, 0.1, 0.04)
	_noise(b, 0.0, 1.4, 0.4, 0.05, 0.25)
	bank["boss"] = _wav(b)

	b = _buf(1.2)
	_noise(b, 0.0, 1.2, 0.35, 0.05, 0.5)
	_tone(b, 0.0, 1.2, 180.0, 420.0, 0.12, 2, 0.2)
	bank["suck"] = _wav(b)

	b = _buf(0.05)
	_tone(b, 0.0, 0.04, 1100.0, 1100.0, 0.25, 1)
	bank["tick"] = _wav(b)

	b = _buf(0.5)
	for i in 3:
		_noise(b, i * 0.07, 0.05, 0.35, 0.7, 0.2)
	_bell(b, 0.2, 0.3, 1320.0, 0.2)
	bank["fruit"] = _wav(b)

	b = _buf(0.6)
	_tone(b, 0.0, 0.25, 520.0, 500.0, 0.3, 1)
	_tone(b, 0.25, 0.35, 390.0, 360.0, 0.3, 1)
	bank["fail"] = _wav(b)

	b = _buf(1.0)
	for i in 5:
		_tone(b, i * 0.1, 0.35, [523.0, 587.0, 659.0, 784.0, 1046.0][i], [523.0, 587.0, 659.0, 784.0, 1046.0][i], 0.3, 1)
	bank["win"] = _wav(b)

	b = _buf(0.3)
	_tone(b, 0.0, 0.2, 180.0, 70.0, 0.6, 0, 0.001)
	_tone(b, 0.05, 0.15, 1600.0, 2400.0, 0.2, 2)
	bank["ram"] = _wav(b)

	b = _buf(0.6)
	_noise(b, 0.0, 0.6, 0.5, 0.3, 0.02)
	_tone(b, 0.0, 0.5, 200.0, 60.0, 0.4, 0)
	bank["fire"] = _wav(b)

	b = _buf(0.35)
	_tone(b, 0.0, 0.3, 900.0, 300.0, 0.25, 0)
	bank["dash"] = _wav(b)


## Лёгкая пиццикато-петля в духе Нэкоацумэ: 4 такта, 112 bpm.
func _music_loop() -> AudioStreamWAV:
	var beat := 60.0 / 112.0
	var bars := 4
	var b := _buf(beat * 4.0 * bars)
	var chords := [[262.0, 330.0, 392.0], [220.0, 262.0, 330.0], [175.0, 220.0, 262.0], [196.0, 247.0, 294.0]]
	var mel := [0, 2, 1, 2, 0, 1, 2, 1]
	for bar in bars:
		var ch: Array = chords[bar]
		var t0 := bar * beat * 4.0
		_tone(b, t0, beat * 1.8, ch[0] * 0.5, ch[0] * 0.5, 0.22, 0, 0.01)
		_tone(b, t0 + beat * 2.0, beat * 1.8, ch[0] * 0.75, ch[0] * 0.75, 0.16, 0, 0.01)
		for i in 8:
			var f: float = ch[mel[(i + bar) % 8]] * (2.0 if i % 4 == 3 else 1.0)
			_tone(b, t0 + i * beat * 0.5, beat * 0.45, f, f, 0.12, 1, 0.003)
		for i in 4:
			_noise(b, t0 + i * beat + beat * 0.5, 0.04, 0.06, 0.9, 0.6)
	return _wav(b, true)
