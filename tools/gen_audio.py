#!/usr/bin/env python3
"""Sinh toàn bộ âm thanh cho EMBERHOLD.

Chạy:  python3 tools/gen_audio.py
Ghi thẳng vào godot/audio/. Chỉ dùng stdlib, xuất WAV 16-bit mono 44.1kHz.

Mọi hàm random đều có seed cố định nên chạy lại cho ra đúng file đã commit.
"""
import math
import os
import random
import struct
import wave

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "godot", "audio")


def save(name, samples):
    peak = max((abs(s) for s in samples), default=1.0) or 1.0
    if peak > 1.0:
        samples = [s / peak for s in samples]
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32000)) for s in samples))
    print("%-12s %5.2fs" % (name, len(samples) / SR))


def env(i, n, attack=0.01, release=0.4):
    """Bao biên độ: lên nhanh, tắt dần theo hàm mũ."""
    t = i / n
    a = min(1.0, t / attack) if attack > 0 else 1.0
    return a * math.exp(-t / release)


class LowPass:
    """Bộ lọc thông thấp một cực, dùng để nặn tiếng ồn trắng thành tiếng gió."""

    def __init__(self, cutoff):
        self.a = 1.0 - math.exp(-2.0 * math.pi * cutoff / SR)
        self.y = 0.0

    def __call__(self, x, cutoff=None):
        if cutoff is not None:
            self.a = 1.0 - math.exp(-2.0 * math.pi * cutoff / SR)
        self.y += self.a * (x - self.y)
        return self.y


class HighPass:
    """Thông cao = tín hiệu gốc trừ phần thông thấp. Dùng cho tiếng điện lách tách."""

    def __init__(self, cutoff):
        self.lp = LowPass(cutoff)

    def __call__(self, x):
        return x - self.lp(x)


def swing():
    """Vút gió của nhát chém: ồn trắng quét tần số lên rồi xuống."""
    n = int(SR * 0.26)
    rnd = random.Random(7)
    lp = LowPass(800)
    out = []
    for i in range(n):
        t = i / n
        cutoff = 500 + 3500 * math.sin(math.pi * t) ** 1.5
        x = lp(rnd.uniform(-1, 1), cutoff)
        out.append(x * env(i, n, 0.05, 0.28) * 0.55)
    return out


def hit():
    """Chém trúng thịt: cú đập trầm cộng tiếng ồn ngắn."""
    n = int(SR * 0.18)
    rnd = random.Random(11)
    lp = LowPass(2200)
    out = []
    for i in range(n):
        t = i / n
        thud = math.sin(2 * math.pi * (150 - 90 * t) * i / SR)
        noise = lp(rnd.uniform(-1, 1))
        out.append((thud * 0.6 + noise * 0.5) * env(i, n, 0.004, 0.12))
    return out


def kill():
    """Hạ được quái: tiếng đập kèm một quãng nhảy lên cho sướng tay."""
    n = int(SR * 0.3)
    rnd = random.Random(23)
    lp = LowPass(3000)
    out = []
    for i in range(n):
        t = i / n
        f = 220 * (1 + t * 1.5)
        tone = math.sin(2 * math.pi * f * i / SR) * 0.45
        crunch = lp(rnd.uniform(-1, 1)) * 0.4 * math.exp(-t * 14)
        out.append((tone + crunch) * env(i, n, 0.005, 0.2))
    return out


def hurt():
    """Nhân vật ăn đòn: tiếng trầm tụt xuống, hơi rè."""
    n = int(SR * 0.34)
    rnd = random.Random(31)
    lp = LowPass(900)
    out = []
    for i in range(n):
        t = i / n
        f = 320 * math.exp(-t * 2.2) + 55
        tone = math.sin(2 * math.pi * f * i / SR)
        tone = math.tanh(tone * 2.2) * 0.5          # rè nhẹ cho đau
        noise = lp(rnd.uniform(-1, 1)) * 0.35 * math.exp(-t * 9)
        out.append((tone + noise) * env(i, n, 0.003, 0.22))
    return out


def dash():
    """Cú lăn né: vút gió ngắn, gọn hơn tiếng chém."""
    n = int(SR * 0.22)
    rnd = random.Random(41)
    lp = LowPass(600)
    out = []
    for i in range(n):
        t = i / n
        x = lp(rnd.uniform(-1, 1), 400 + 2600 * (1 - t) ** 2)
        out.append(x * env(i, n, 0.01, 0.14) * 0.5)
    return out


def broke():
    """Vũ khí mẻ hẳn: kim loại nứt, vài tần số lệch nhau cho chối tai."""
    n = int(SR * 0.5)
    rnd = random.Random(53)
    lp = LowPass(6000)
    out = []
    partials = [1730.0, 2470.0, 3310.0, 4790.0]
    for i in range(n):
        t = i / n
        s = 0.0
        for k, f in enumerate(partials):
            s += math.sin(2 * math.pi * f * i / SR) * math.exp(-t * (5 + k * 4))
        crack = lp(rnd.uniform(-1, 1)) * 0.6 * math.exp(-t * 30)
        out.append((s * 0.22 + crack) * env(i, n, 0.002, 0.3))
    return out


def zap():
    """Sét lan giữa quái ướt: ồn thông cao bị chặt vụn thành tiếng lách tách,
    cộng một bè cao lệch tần cho ra chất điện."""
    n = int(SR * 0.28)
    rnd = random.Random(97)
    hp = HighPass(1200)
    out = []
    for i in range(n):
        t = i / n
        # cổng ngắt mở rất nhanh và không đều -> nghe như tia điện nhảy
        gate = 1.0 if rnd.random() < 0.55 else 0.25
        crackle = hp(rnd.uniform(-1, 1)) * gate
        buzz = math.sin(2 * math.pi * 2600 * i / SR) * 0.3
        buzz += math.sin(2 * math.pi * 3700 * i / SR) * 0.2
        out.append((crackle * 0.75 + buzz * math.exp(-t * 6)) * env(i, n, 0.002, 0.16) * 0.8)
    return out


def boom():
    """Quái nổ khi bị hạ: cú đập trầm sâu cộng luồng ồn xì ra rồi tắt nhanh."""
    n = int(SR * 0.42)
    rnd = random.Random(101)
    lp = LowPass(1400)
    out = []
    for i in range(n):
        t = i / n
        # tần số tụt sâu = cảm giác nổ chứ không phải va đập
        f = 190 * math.exp(-t * 4.5) + 38
        body = math.sin(2 * math.pi * f * i / SR)
        body = math.tanh(body * 1.8) * 0.7
        blast = lp(rnd.uniform(-1, 1), 3000 * math.exp(-t * 3) + 200) * 0.7
        out.append((body + blast) * env(i, n, 0.002, 0.17))
    return out


def fanfare(freqs, step, dur, decay, wobble=0.0):
    """Chuỗi nốt nối tiếp, dùng cho tiếng thắng và tiếng thua."""
    n = int(SR * dur)
    out = [0.0] * n
    for idx, f in enumerate(freqs):
        start = int(idx * step * SR)
        for i in range(start, n):
            j = i - start
            m = n - start
            f2 = f * (1.0 + wobble * math.sin(2 * math.pi * 5.0 * j / SR))
            s = math.sin(2 * math.pi * f2 * j / SR)
            s += 0.3 * math.sin(4 * math.pi * f2 * j / SR)   # bội âm cho dày
            out[i] += s * env(j, m, 0.01, decay) * 0.3
    return out


def win():
    return fanfare([392.0, 523.25, 659.25, 783.99], 0.14, 1.5, 0.5)


def lose():
    return fanfare([233.08, 196.0, 155.56, 116.54], 0.2, 1.9, 0.55, wobble=0.02)


def drone():
    """Nền hầm mộ: hai bè trầm lệch nhau tạo nhịp đập chậm, ghép liền vòng."""
    dur = 8.0
    n = int(SR * dur)
    rnd = random.Random(67)
    lp = LowPass(220)
    out = []
    for i in range(n):
        t = i / SR
        # tần số là bội số nguyên của 1/dur nên đầu và cuối khớp nhau, lặp không cộp
        a = math.sin(2 * math.pi * (55.0 * dur // 1 / dur) * t)
        b = math.sin(2 * math.pi * (82.5 * dur // 1 / dur) * t) * 0.5
        c = math.sin(2 * math.pi * (2.0 / dur) * t) * 0.5 + 0.5     # thở chậm
        rumble = lp(rnd.uniform(-1, 1)) * 0.5
        out.append((a * 0.5 + b + rumble) * (0.45 + 0.35 * c) * 0.5)
    # vuốt mép rất ngắn để chắc chắn không có tiếng cộp khi vòng lại
    fade = int(SR * 0.01)
    for i in range(fade):
        k = i / fade
        out[i] *= k
        out[n - 1 - i] *= k
    return out


if __name__ == "__main__":
    for fname, fn in [
        ("swing.wav", swing), ("hit.wav", hit), ("kill.wav", kill),
        ("hurt.wav", hurt), ("dash.wav", dash), ("broke.wav", broke),
        ("zap.wav", zap), ("boom.wav", boom),
        ("win.wav", win), ("lose.wav", lose), ("drone.wav", drone),
    ]:
        save(fname, fn())
