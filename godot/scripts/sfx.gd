extends Node
## Procedural sound (CRITIQUE B3). The game ships NO audio assets — so, exactly like
## the art (see art*.gd → Assets), every sound effect is SYNTHESISED at launch into an
## AudioStreamWAV and played from a small pool of AudioStreamPlayers. This autoload is
## the single audio surface: call `Sfx.play("hit")` from anywhere, `Sfx.ambient(true)`
## for the looping hearth bed. No .ogg/.wav files, no bus layout required.
##
## Synthesis is deliberately tiny: short percussive noise, glides, and additive sine
## chimes shaped by linear/exponential envelopes. All buffers are mono 16-bit.

const RATE := 22050        # plenty for stubby SFX; keeps the baked buffers small
const POOL := 12           # concurrent one-shot voices (round-robin)

var _lib: Dictionary = {}                        # name -> AudioStreamWAV
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _amb: AudioStreamPlayer = null               # looping warmth ambience
var _muted: bool = false

func _ready() -> void:
	# GDScript's noise here would vary per launch; that's fine (imperceptible) and
	# actually stops repeated shots sounding mechanically identical.
	_bake_all()
	for _i in range(POOL):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_amb = AudioStreamPlayer.new()
	_amb.volume_db = -20.0
	add_child(_amb)

# --- Public API -------------------------------------------------------------

# Fire a one-shot. `vol_db` trims level; `pitch` is scaled with a hair of random
# detune so a burst of identical events (a crowd dying) doesn't machine-gun.
func play(sound: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	if _muted:
		return
	var s: AudioStreamWAV = _lib.get(sound, null)
	if s == null:
		return
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = s
	p.volume_db = vol_db
	p.pitch_scale = clampf(pitch * randf_range(0.96, 1.04), 0.2, 3.0)
	p.play()

# Start/stop the looping hearth crackle (village = on, ruins = off).
func ambient(on: bool) -> void:
	if _amb == null:
		return
	if on and not _muted:
		if not _amb.playing:
			_amb.stream = _lib.get("ambient", null)
			if _amb.stream != null:
				_amb.play()
	else:
		_amb.stop()

func set_muted(m: bool) -> void:
	_muted = m
	if m:
		ambient(false)

# ---------------------------------------------------------------------------
# Bake — build the whole library once.
func _bake_all() -> void:
	_lib["hit"]       = _wav(_perc(0.10, 1500.0, 0.55))                       # sharp thwack
	_lib["hit_heavy"] = _wav(_mix([_perc(0.16, 650.0, 0.7), _tone(90.0, 0.16, "sine", 0.004, 0.14, 0.22)]))
	_lib["crit"]      = _wav(_mix([_perc(0.12, 2200.0, 0.5), _sweep(900.0, 1700.0, 0.16, "square", 0.28)]))
	_lib["hurt"]      = _wav(_sweep(520.0, 180.0, 0.22, "saw", 0.4))          # ow, sinking
	_lib["dash"]      = _wav(_whoosh(0.20))                                    # airy swell
	_lib["parry"]     = _wav(_mix([_tone(1245.0, 0.26, "sine", 0.001, 0.24, 0.3), _tone(1860.0, 0.26, "sine", 0.001, 0.24, 0.18)]))  # metallic ring
	_lib["pickup"]    = _wav(_blip(880.0, 1320.0, 0.12))                       # two-note up
	_lib["build"]     = _wav(_mix([_perc(0.09, 420.0, 0.5), _tone(180.0, 0.09, "sine", 0.002, 0.08, 0.2)]))  # woody knock
	_lib["harvest"]   = _wav(_blip(660.0, 990.0, 0.14))
	_lib["bloom"]     = _wav(_arp([523.25, 659.25, 783.99, 1046.5], 0.075))   # C E G C chime
	_lib["ui"]        = _wav(_blip(520.0, 720.0, 0.05))
	_lib["descend"]   = _wav(_sweep(420.0, 120.0, 0.5, "sine", 0.4))          # low portal down
	_lib["death"]     = _wav(_sweep(300.0, 65.0, 0.7, "saw", 0.45))           # collapse
	_lib["win"]       = _wav(_arp([392.0, 523.25, 659.25, 783.99, 1046.5], 0.14))  # warm ascent
	_lib["warm"]      = _wav(_arp([523.25, 783.99], 0.06))                     # a small warmth ping
	_lib["ambient"]   = _wav(_crackle(2.4), true)                             # looping hearth bed

# ---------------------------------------------------------------------------
# Sample generators — each returns a mono float buffer in [-1, 1].

# One oscillator with an attack/release linear envelope.
func _tone(freq: float, dur: float, wave: String, atk: float, rel: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		var ph := fmod(freq * t, 1.0)
		var s := 0.0
		match wave:
			"square": s = 1.0 if ph < 0.5 else -1.0
			"saw":    s = 2.0 * ph - 1.0
			"tri":    s = 4.0 * absf(ph - 0.5) - 1.0
			_:        s = sin(TAU * freq * t)
		out[i] = s * _env(t, dur, atk, rel) * amp
	return out

func _env(t: float, dur: float, atk: float, rel: float) -> float:
	if t < atk:
		return t / maxf(atk, 0.0001)
	if t > dur - rel:
		return maxf(0.0, (dur - t) / maxf(rel, 0.0001))
	return 1.0

# Filtered noise with an exponential decay — the basis of hits/knocks.
func _perc(dur: float, cutoff: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var prev := 0.0
	var a := clampf(cutoff / float(RATE), 0.02, 0.9)   # 1-pole lowpass coefficient
	for i in range(n):
		var t := float(i) / RATE
		prev += a * ((randf() * 2.0 - 1.0) - prev)
		out[i] = prev * exp(-t / (dur * 0.28)) * amp
	return out

# A pitch glide from f0 to f1.
func _sweep(f0: float, f1: float, dur: float, wave: String, amp: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / RATE
		var f := lerpf(f0, f1, t / dur)
		phase += TAU * f / RATE
		var s := sin(phase)
		if wave == "square":
			s = 1.0 if s >= 0.0 else -1.0
		elif wave == "saw":
			s = fmod(phase / TAU, 1.0) * 2.0 - 1.0
		out[i] = s * _env(t, dur, 0.005, dur * 0.5) * amp
	return out

# Band-brightening noise that swells in and out — a dash/whoosh.
func _whoosh(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var prev := 0.0
	for i in range(n):
		var k := float(i) / float(n)
		prev += lerpf(0.05, 0.5, k) * ((randf() * 2.0 - 1.0) - prev)
		out[i] = prev * sin(PI * k) * 0.5
	return out

# Two short sine notes in sequence — a little "blip".
func _blip(f0: float, f1: float, dur: float) -> PackedFloat32Array:
	var half := dur * 0.5
	var out := PackedFloat32Array()
	out.append_array(_tone(f0, half, "sine", 0.003, half * 0.6, 0.5))
	out.append_array(_tone(f1, half, "sine", 0.003, half * 0.6, 0.5))
	return out

# Overlapping ascending sine notes — a chime.
func _arp(freqs: Array, step: float) -> PackedFloat32Array:
	var note := step * 3.0
	var total := int((float(freqs.size() - 1) * step + note) * RATE) + 1
	var out := PackedFloat32Array()
	out.resize(total)
	for idx in range(freqs.size()):
		var tone := _tone(float(freqs[idx]), note, "sine", 0.004, note * 0.7, 0.32)
		var off := int(float(idx) * step * RATE)
		for j in range(tone.size()):
			if off + j < total:
				out[off + j] += tone[j]
	return out

# A soft looping hearth bed: low hum + sprinkled crackle pops.
func _crackle(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		out[i] = sin(TAU * 55.0 * t) * 0.05 + sin(TAU * 110.0 * t) * 0.025
	var pops := int(dur * 20.0)
	for _p in range(pops):
		var start := randi() % n
		var plen := maxi(1, int(randf_range(0.003, 0.02) * RATE))
		var pamp := randf_range(0.05, 0.16)
		for j in range(plen):
			if start + j < n:
				out[start + j] += (randf() * 2.0 - 1.0) * pamp * exp(-float(j) / float(plen) * 4.0)
	return out

# Sum several buffers (padded to the longest).
func _mix(parts: Array) -> PackedFloat32Array:
	var maxlen := 0
	for p in parts:
		maxlen = maxi(maxlen, (p as PackedFloat32Array).size())
	var out := PackedFloat32Array()
	out.resize(maxlen)
	for p in parts:
		var pa: PackedFloat32Array = p
		for i in range(pa.size()):
			out[i] += pa[i]
	return out

# Float buffer -> 16-bit mono AudioStreamWAV (with soft clipping).
func _wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v := clampf(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(round(v * 32767.0)))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w
