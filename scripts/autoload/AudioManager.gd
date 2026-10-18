extends Node

## AudioManager: efectos y música **originales generados por código** como
## `AudioStreamWAV`. Los efectos usan ondas cuadradas, ruido y envolventes; la
## música es heavy metal sintetizado (guitarras distorsionadas, palm mute,
## doble bombo y melodía en Mi menor). No se usan samples de terceros.
## Los sonidos son PROVISIONALES: pueden sustituirse por archivos de audio
## reales sin cambiar las llamadas (`AudioManager.play_sfx("shoot")`, etc.).

const RATE := 22050        ## Frecuencia de muestreo (mono, 16 bits).
const POOL_SIZE := 6        # Voces simultáneas por efecto.

## Música pre-renderizada (se genera con `-- render_music` y se empaqueta).
## Preferimos OGG en Android para evitar problemas con WAV en algunos dispositivos.
const MUSIC_THEME_WAV := "res://assets/audio/theme.wav"
const MUSIC_BOSS_WAV := "res://assets/audio/boss.wav"
const MUSIC_THEME_OGG := "res://assets/audio/theme.ogg"
const MUSIC_BOSS_OGG := "res://assets/audio/boss.ogg"

var muted: bool = false

var _streams: Dictionary = {}
var _pools: Dictionary = {}
var _idx: Dictionary = {}
var _music: AudioStream = null
var _boss_music: AudioStream = null
var _music_tracks: Dictionary = {}
var _music_player: AudioStreamPlayer

func _ready() -> void:
	_streams["shoot"] = _to_stream(_sfx_shoot(), false)
	_streams["explosion"] = _to_stream(_sfx_explosion(), false)
	_streams["big_explosion"] = _to_stream(_sfx_big_explosion(), false)
	_streams["hit"] = _to_stream(_sfx_hit(), false)
	_streams["powerup"] = _to_stream(_sfx_powerup(), false)
	_streams["bomb"] = _to_stream(_sfx_bomb(), false)
	_streams["boss_hit"] = _to_stream(_sfx_boss_hit(), false)
	_streams["warning"] = _to_stream(_sfx_warning(), false)
	_streams["angel"] = _to_stream(_sfx_angel(), false)
	for key in _streams:
		var arr: Array = []
		for i in 6:
			var p := AudioStreamPlayer.new()
			p.stream = _streams[key]
			add_child(p)
			arr.append(p)
		_pools[key] = arr
		_idx[key] = 0

	_music = _load_music("theme")
	_boss_music = _load_music("boss")
	_music_tracks["theme"] = _music
	_music_tracks["boss"] = _boss_music
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = _music
	_music_player.volume_db = -14.0
	add_child(_music_player)

# ---------------------------------------------------------------------------
# Música
# ---------------------------------------------------------------------------
## Carga la música desde un archivo pre-renderizado (assets/audio/*.ogg o *.wav).
## Esto evita sintetizarla en el dispositivo (puede provocar ANR). Si no existe,
## la sintetiza como fallback.
func _load_music(track: String) -> AudioStream:
	var ogg_path: String = MUSIC_THEME_OGG if track == "theme" else MUSIC_BOSS_OGG
	if ResourceLoader.exists(ogg_path):
		var res: Resource = load(ogg_path)
		if res is AudioStreamOggVorbis:
			var ogg: AudioStreamOggVorbis = res
			ogg.loop = true
			return ogg
		if res is AudioStreamWAV:
			var wav: AudioStreamWAV = res
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = maxi(_frame_count(wav), 1)
			return wav
	var wav_path: String = MUSIC_THEME_WAV if track == "theme" else MUSIC_BOSS_WAV
	if ResourceLoader.exists(wav_path):
		var res: Resource = load(wav_path)
		if res is AudioStreamWAV:
			var wav: AudioStreamWAV = res
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = maxi(_frame_count(wav), 1)
			return wav
	return _to_stream(_build_music() if track == "theme" else _build_boss_music(), true)

## Cantidad de frames (muestras por canal) de un AudioStreamWAV PCM.
func _frame_count(wav: AudioStreamWAV) -> int:
	var bytes_per_sample := 1 if wav.format == AudioStreamWAV.FORMAT_8_BITS else 2
	if wav.stereo:
		bytes_per_sample *= 2
	if wav.data.size() > 0 and bytes_per_sample > 0:
		return wav.data.size() / bytes_per_sample
	return int(wav.get_length() * float(wav.mix_rate))

## Herramienta de desarrollo: renderiza la música a WAV para empaquetarla.
func render_music_files() -> void:
	if not DirAccess.dir_exists_absolute("res://assets/audio"):
		DirAccess.make_dir_recursive_absolute("res://assets/audio")
	_write_wav(MUSIC_THEME_WAV, _build_music())
	_write_wav(MUSIC_BOSS_WAV, _build_boss_music())

func _write_wav(path: String, samples: PackedFloat32Array) -> void:
	var n := samples.size()
	var out := PackedByteArray()
	out.resize(44 + n * 2)
	out.encode_u32(0, 0x46464952)   # "RIFF"
	out.encode_u32(4, 36 + n * 2)
	out.encode_u32(8, 0x45564157)   # "WAVE"
	out.encode_u32(12, 0x20746D66)  # "fmt "
	out.encode_u32(16, 16)          # tamaño del bloque fmt
	out.encode_u16(20, 1)           # PCM
	out.encode_u16(22, 1)           # mono
	out.encode_u32(24, RATE)
	out.encode_u32(28, RATE * 2)    # bytes por segundo (16 bits mono)
	out.encode_u16(32, 2)           # block align
	out.encode_u16(34, 16)          # bits por muestra
	out.encode_u32(36, 0x61746164)  # "data"
	out.encode_u32(40, n * 2)
	for i in n:
		out.encode_s16(44 + i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("AudioManager: no se pudo escribir " + path)
		return
	f.store_buffer(out)
	f.close()
	print("[AUDIO] renderizado ", path, " (", n, " frames)")

# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------
func play_sfx(name: String) -> void:
	if muted:
		return
	if not _pools.has(name):
		return
	var arr: Array = _pools[name]
	var i: int = _idx[name]
	var p: AudioStreamPlayer = arr[i]
	_idx[name] = (i + 1) % arr.size()
	p.play()

func play_music(name: String = "theme") -> void:
	if _music_player == null or muted:
		return
	var track: AudioStream = _music_tracks.get(name, _music)
	if _music_player.stream != track:
		_music_player.stream = track
		_music_player.play()
	elif not _music_player.playing:
		_music_player.play()

func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()

func set_muted(value: bool) -> void:
	muted = value
	if muted:
		stop_music()
	elif _music_player != null:
		_music_player.stream_paused = false

# ---------------------------------------------------------------------------
# Efectos (sintetizados)
# ---------------------------------------------------------------------------
func _sfx_shoot() -> PackedFloat32Array:
	var dur := 0.09
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		phase += lerpf(900.0, 380.0, t) / RATE
		var sq := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		out[i] = sq * pow(1.0 - t, 2.0) * 0.16  # menos volumen
	return out

func _sfx_explosion() -> PackedFloat32Array:
	var dur := 0.4
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.22)
		out[i] = lp * pow(1.0 - t, 2.2) * 0.5
	return out

func _sfx_hit() -> PackedFloat32Array:
	var dur := 0.3
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		phase += lerpf(300.0, 90.0, t) / RATE
		var sq := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		out[i] = sq * pow(1.0 - t, 1.5) * 0.4
	return out

## Alma liberada del jefe: campanitas celestiales ascendentes (etéreas y
## alegres, con armónicos y un vibrato leve).
func _sfx_angel() -> PackedFloat32Array:
	var notes := [659.25, 783.99, 987.77, 1318.51, 1567.98]  # E5 G5 B5 E6 G6
	var step := 0.09
	var tail := 0.55
	var n := int(RATE * (step * float(notes.size()) + tail))
	var out := PackedFloat32Array()
	out.resize(n)
	for idx in notes.size():
		var freq: float = notes[idx]
		var start := int(RATE * step * float(idx))
		var len_i := n - start
		for j in len_i:
			var t := float(j) / float(len_i)
			var tt := float(j) / RATE
			var env := exp(-2.6 * t)
			var vib := 1.0 + 0.006 * sin(TAU * 5.5 * tt)
			var sample := sin(TAU * freq * vib * tt) \
				+ 0.35 * sin(TAU * freq * 2.0 * tt) \
				+ 0.12 * sin(TAU * freq * 3.0 * tt)
			out[start + j] += sample * env * 0.22
	# Limitador suave: las notas se solapan y podrían saturar.
	for i in n:
		out[i] = clampf(out[i], -0.9, 0.9)
	return out

func _sfx_powerup() -> PackedFloat32Array:
	var notes := [523.25, 659.25, 783.99, 1046.5]
	var seg := 0.07
	var seg_n := int(RATE * seg)
	var out := PackedFloat32Array()
	out.resize(seg_n * notes.size())
	for idx in notes.size():
		var freq: float = notes[idx]
		var start := seg_n * idx
		for j in seg_n:
			var t := float(j) / float(seg_n)
			var phase := freq * float(j) / RATE
			var sq := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			out[start + j] = sq * (1.0 - t * 0.5) * 0.3
	return out

func _sfx_bomb() -> PackedFloat32Array:
	var dur := 0.6
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var noise := rng.randf_range(-1.0, 1.0) * 0.5
		phase += lerpf(160.0, 40.0, t) / RATE
		var tone := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		out[i] = (noise + tone * 0.6) * pow(1.0 - t, 1.8) * 0.5
	return out

func _sfx_boss_hit() -> PackedFloat32Array:
	var dur := 0.08
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		phase += 220.0 / RATE
		var sq := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		out[i] = sq * (1.0 - t) * 0.28
	return out

## Explosión grande (destrucción de jefe): ruido + sub grave, más larga.
func _sfx_big_explosion() -> PackedFloat32Array:
	var dur := 1.1
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var lp := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.18)
		phase += lerpf(120.0, 32.0, t) / RATE
		var sub := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		out[i] = (lp * 0.55 + sub * 0.45) * pow(1.0 - t, 1.6) * 0.6
	return out

## Alerta de jefe: dos tonos descendentes tipo sirena.
func _sfx_warning() -> PackedFloat32Array:
	var dur := 0.5
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var half := n / 2
	var phase := 0.0
	for i in n:
		var local := float(i % half) / float(half)
		var f := lerpf(660.0, 440.0, local) if i < half else lerpf(880.0, 550.0, local)
		phase += f / RATE
		var sq := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		out[i] = sq * 0.22 * (1.0 - local * 0.4)
	return out

# ---------------------------------------------------------------------------
# Música: heavy metal original sintetizado (guitarras distorsionadas, palm
# mute en galope, doble bombo y melodía en Mi menor). Sin samples de terceros.
# ---------------------------------------------------------------------------

## Saturación tipo amplificador de válvulas: pre-ganancia alta + tanh.
func _distort(x: float) -> float:
	return tanh(x * 6.0)

## Diente de sierra (base rica en armónicos de la guitarra eléctrica).
func _saw(phase: float) -> float:
	return 2.0 * (phase - floor(phase)) - 1.0

## Envolvente ataque/decaimiento: llega a 0 justo al final del rango audible.
func _ade(t: float, atk: float, dec: float) -> float:
	if t < 0.0 or t >= atk + dec:
		return 0.0
	if t < atk:
		return t / atk
	var u := (t - atk) / dec
	return (1.0 - u) * exp(-3.0 * u)

## Acorde de quinta distorsionado (raíz + quinta + octava) con envolvente.
func _add_power(buf: PackedFloat32Array, at: float, root: float, atk: float, dec: float, gain: float) -> void:
	var s0 := int(at * RATE)
	var n := int((atk + dec) * RATE)
	var pr := 0.0
	var pf := 0.0
	var po := 0.0
	var lp := 0.0
	for i in n:
		var idx := s0 + i
		if idx < 0 or idx >= buf.size():
			continue
		var t := float(i) / RATE
		var e := _ade(t, atk, dec)
		var sig := _saw(pr) + _saw(pf) * 0.7 + _saw(po) * 0.45
		sig = _distort(sig * 0.62)
		lp += 0.58 * (sig - lp)  # filtro paso-bajo suave (~3 kHz)
		buf[idx] += lp * e * gain
		pr += root / RATE
		pf += root * 1.5 / RATE
		po += root * 2.0 / RATE

## Nota de guitarra solista distorsionada con vibrato leve.
func _add_lead(buf: PackedFloat32Array, at: float, freq: float, atk: float, dec: float, gain: float) -> void:
	var s0 := int(at * RATE)
	var n := int((atk + dec) * RATE)
	var ph := 0.0
	var vib := 0.0
	var lp := 0.0
	for i in n:
		var idx := s0 + i
		if idx < 0 or idx >= buf.size():
			continue
		var t := float(i) / RATE
		var e := _ade(t, atk, dec)
		var s := _distort(_saw(ph) * 0.8)
		lp += 0.62 * (s - lp)
		buf[idx] += lp * e * gain
		ph += freq * (1.0 + 0.012 * sin(vib)) / RATE
		vib += TAU * 5.5 / RATE

## Bombo: seno con barrido de tono descendente y caída rápida.
func _add_kick(buf: PackedFloat32Array, at: float, gain: float) -> void:
	var s0 := int(at * RATE)
	var n := int(0.16 * RATE)
	var ph := 0.0
	for i in n:
		var idx := s0 + i
		if idx < 0 or idx >= buf.size():
			continue
		var t := float(i) / RATE
		ph += lerpf(150.0, 48.0, clampf(t / 0.10, 0.0, 1.0)) / RATE
		buf[idx] += sin(ph * TAU) * exp(-t * 22.0) * gain

## Caja: ruido pasado-alto + tono con envolvente corta.
func _add_snare(buf: PackedFloat32Array, at: float, gain: float, rng: RandomNumberGenerator) -> void:
	var s0 := int(at * RATE)
	var n := int(0.18 * RATE)
	var ph := 0.0
	var prev := 0.0
	for i in n:
		var idx := s0 + i
		if idx < 0 or idx >= buf.size():
			continue
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		var hp := noise - prev
		prev = noise
		ph += 190.0 / RATE
		buf[idx] += (hp * 0.5 + sin(ph * TAU) * 0.5) * exp(-t * 18.0) * gain

## Charles: ruido agudo; `is_open` alarga el sonido.
func _add_hat(buf: PackedFloat32Array, at: float, gain: float, is_open: bool, rng: RandomNumberGenerator) -> void:
	var s0 := int(at * RATE)
	var n := int((0.18 if is_open else 0.055) * RATE)
	var prev := 0.0
	for i in n:
		var idx := s0 + i
		if idx < 0 or idx >= buf.size():
			continue
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		var hp := noise - prev
		prev = noise
		buf[idx] += hp * exp(-t * (16.0 if is_open else 58.0)) * gain

## Tema principal: heavy metal en Mi menor (i - VI - III - VII sobre E5/C5/G5/D5).
func _build_music() -> PackedFloat32Array:
	return _render_metal(false)

## Música de jefe: más rápida, con doble bombo a 16avos y melodía aguda.
func _build_boss_music() -> PackedFloat32Array:
	return _render_metal(true)

func _render_metal(boss: bool) -> PackedFloat32Array:
	var bpm := 174.0 if boss else 160.0
	var beat := 60.0 / bpm
	var sixteenth := beat * 0.25
	var bar := beat * 4.0
	var roots := [82.41, 65.41, 98.00, 73.42]  # E5, C5, G5, D5
	var bars := 8
	var buf := PackedFloat32Array()
	buf.resize(int(bars * bar * RATE))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20251016

	# Riff de palm mute en galope (rejilla de 16avos): [paso, duración, acorde].
	var riff := [
		[0, 2, false], [2, 1, false], [3, 1, false],
		[4, 2, false], [6, 1, false], [7, 1, false],
		[8, 2, false], [10, 1, false], [11, 1, false],
		[12, 4, true],
	]
	# Melodía (una nota por tiempo) en Mi menor: semitonos sobre E4.
	var lead := [
		[0, 7, 5, 3], [0, 3, 5, 7], [7, 5, 3, 2], [0, 7, 10, 12],
		[0, 7, 5, 3], [0, 3, 5, 7], [7, 5, 3, 2], [12, 10, 7, 0],
	]
	var e4 := 329.63

	for b in bars:
		var bar_start := b * bar
		var root: float = roots[b % roots.size()]
		for hit in riff:
			var at := bar_start + int(hit[0]) * sixteenth
			var dec := int(hit[1]) * sixteenth
			_add_power(buf, at, root, 0.003, dec, 0.12)
		# Bajo grave en cada tiempo (peso de fondo).
		for q in 4:
			_add_power(buf, bar_start + q * beat, root * 0.5, 0.004, beat * 0.5, 0.09)
		# Batería: doble bombo a 16avos en jefe, a 8avos en el tema.
		var kicks := 16 if boss else 8
		var kick_step := sixteenth if boss else sixteenth * 2.0
		for k in kicks:
			_add_kick(buf, bar_start + k * kick_step, 0.5)
		_add_snare(buf, bar_start + beat, 0.30, rng)
		_add_snare(buf, bar_start + beat * 3.0, 0.30, rng)
		for k in 8:
			_add_hat(buf, bar_start + k * beat * 0.5, 0.09, false, rng)
		_add_hat(buf, bar_start, 0.15, true, rng)
		# Melodía.
		var line: Array = lead[b % lead.size()]
		for k in line.size():
			var freq: float = e4 * pow(2.0, float(line[k]) / 12.0)
			_add_lead(buf, bar_start + k * beat, freq, 0.01, beat * 0.85, 0.075)

	# Normalizado para no recortar en la conversión a 16 bits.
	var peak := 0.0
	for i in buf.size():
		peak = maxf(peak, absf(buf[i]))
	if peak > 0.95:
		var k := 0.95 / peak
		for i in buf.size():
			buf[i] *= k
	return buf

# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------
## Convierte muestras float (-1..1) en un AudioStreamWAV de 16 bits mono.
func _to_stream(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s
