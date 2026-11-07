"""Author the 64×64 color-by-number scenes using deterministic pixel shapes.

Run with Python 3; no third-party libraries required. Generated rows are checked
into Puzzle.swift, so the app does no image processing at runtime.
"""
from pathlib import Path
import math
import random
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
SYMBOLS = '.123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'


class Picture:
    def __init__(self, palette):
        self.palette = palette
        self.pixels = [[1] * 64 for _ in range(64)]

    def dot(self, x, y, color):
        if 0 <= x < 64 and 0 <= y < 64:
            self.pixels[y][x] = color

    def rect(self, x0, y0, x1, y1, color):
        for y in range(max(0, y0), min(64, y1 + 1)):
            for x in range(max(0, x0), min(64, x1 + 1)):
                self.dot(x, y, color)

    def ellipse(self, cx, cy, rx, ry, color):
        for y in range(max(0, math.floor(cy - ry)), min(64, math.ceil(cy + ry) + 1)):
            for x in range(max(0, math.floor(cx - rx)), min(64, math.ceil(cx + rx) + 1)):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                    self.dot(x, y, color)

    def poly(self, points, color):
        for y in range(64):
            for x in range(64):
                inside = False
                j = len(points) - 1
                for i, (xi, yi) in enumerate(points):
                    xj, yj = points[j]
                    if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
                        inside = not inside
                    j = i
                if inside:
                    self.dot(x, y, color)

    def line(self, x0, y0, x1, y1, color):
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for step in range(steps + 1):
            self.dot(round(x0 + (x1 - x0) * step / steps), round(y0 + (y1 - y0) * step / steps), color)

    def flower(self, x, y, radius, petal, shadow, center):
        for angle in range(0, 360, 60):
            a = math.radians(angle)
            cx, cy = x + math.cos(a) * radius, y + math.sin(a) * radius
            self.ellipse(cx, cy, radius * .78, radius * .85, shadow)
            self.ellipse(cx - .5, cy - .7, radius * .55, radius * .55, petal)
        self.ellipse(x, y, radius * .65, radius * .65, center)
        self.dot(x - 1, y - 1, 6)

    def pine(self, x, y, size, dark, light, trunk):
        self.rect(x - 1, y - size // 2, x, y + 1, trunk)
        for level in range(3):
            top = y - size + level * size // 4
            spread = size * (level + 2) // 7
            bottom = top + size // 2
            self.poly([(x, top), (x - spread, bottom), (x + spread + 1, bottom)], dark)
            self.poly([(x, top + 1), (x - spread + 1, bottom - 1), (x, bottom - 1)], light)


def garden():
    palette = [
        ('Morning sky', 'BBDDD5'), ('Sky light', 'D7EAE0'), ('Cloud', 'F5F0D9'),
        ('Distant sage', 'A7BE9C'), ('Meadow', '799B75'), ('Sunlight', 'FFE4A1'),
        ('Deep leaf', '345B51'), ('Leaf', '527F62'), ('Leaf light', '9FBD78'),
        ('Petal shadow', 'A94865'), ('Rose', 'DB7288'), ('Petal light', 'F4ACAF'),
        ('Peach shadow', 'D88C68'), ('Apricot', 'F3BD87'), ('Pollen', 'B17B3F'),
        ('Lavender', 'A899C5'), ('Lavender shadow', '776B9A'), ('Clay shadow', '9B6555'),
        ('Terracotta', 'CA8C6C'), ('Clay light', 'E4AE88'), ('Soil', '674D43'),
        ('Garden path', 'D7C6A0'), ('Path shade', 'B7AA8D'), ('Butterfly', 'E4B75B')]
    p = Picture(palette)
    p.rect(0, 13, 63, 28, 2)
    p.ellipse(49, 9, 6, 6, 6)
    for x, y, rx in [(11, 9, 7), (17, 7, 5), (37, 16, 8)]:
        p.ellipse(x, y, rx, 2, 3)
    p.poly([(0, 27), (12, 21), (26, 25), (39, 20), (63, 25), (63, 42), (0, 42)], 4)
    p.poly([(0, 33), (16, 28), (31, 34), (49, 27), (63, 31), (63, 63), (0, 63)], 5)
    p.poly([(39, 34), (44, 34), (61, 63), (35, 63)], 22)
    for x, y in [(43, 41), (47, 49), (44, 57), (54, 60)]:
        p.line(x, y, x + 4, y, 23)
    rng = random.Random(31)
    for _ in range(90):
        x, y = rng.randrange(64), rng.randrange(34, 64)
        if p.pixels[y][x] == 5:
            p.line(x, y, x + rng.choice([-1, 1]), y - 2, 8)
    # An overflowing clay planter, with individually shaped stems and veined leaves.
    p.ellipse(23, 60, 18, 3, 7)
    p.poly([(10, 44), (36, 44), (32, 59), (15, 59)], 18)
    p.poly([(12, 46), (33, 46), (30, 57), (16, 57)], 19)
    p.poly([(15, 46), (20, 46), (22, 57), (17, 57)], 20)
    p.rect(9, 43, 37, 46, 19)
    p.line(10, 43, 36, 43, 20)
    p.ellipse(23, 42, 12, 2, 21)
    stems = [(13, 26), (23, 17), (34, 26), (25, 33), (8, 36)]
    for x, y in stems:
        p.line(23, 42, x, y, 7)
    for points in [[(19, 38), (10, 33), (12, 39), (23, 42)], [(25, 36), (37, 32), (33, 38), (23, 40)],
                   [(21, 28), (14, 24), (16, 31), (22, 34)], [(27, 28), (33, 19), (33, 26), (25, 33)]]:
        p.poly(points, 8)
        p.line(*points[0], *points[2], 9)
    p.flower(23, 17, 5, 12, 11, 15)
    p.flower(13, 27, 4, 14, 13, 15)
    p.flower(35, 26, 4, 12, 10, 6)
    p.flower(25, 33, 3, 14, 13, 15)
    p.flower(7, 36, 2, 12, 10, 6)
    # Lavender and small flowers at the edge of the path.
    for x, y in [(52, 43), (57, 47), (61, 39), (48, 39)]:
        p.line(x, y + 9, x, y, 7)
        for dy in range(0, 6, 2):
            p.ellipse(x - 1, y + dy, 1, 1, 17)
            p.dot(x + 1, y + dy, 16)
    for x, y in [(4, 51), (7, 58), (34, 56), (59, 58)]:
        p.flower(x, y, 1, 3, 14, 15)
    p.ellipse(46, 24, 2, 3, 24)
    p.ellipse(50, 24, 2, 3, 14)
    p.line(48, 23, 48, 27, 21)
    return p


def cabin():
    palette = [
        ('Evening sky', '7788AE'), ('Sky glow', 'AFACC2'), ('Peach dusk', 'E9BCA9'),
        ('Moonlight', 'FFF0C3'), ('Far mountains', '6C789A'), ('Mountain light', '98A2B9'),
        ('Distant pines', '496B79'), ('Pine shadow', '254B52'), ('Pine', '3D6C61'),
        ('Pine light', '729177'), ('Meadow shadow', '3E6257'), ('Meadow', '68876A'),
        ('Roof shadow', '514654'), ('Slate', '796477'), ('Slate light', 'A6858A'),
        ('Timber shadow', '77554C'), ('Cedar', 'A77B5D'), ('Wood light', 'D1A276'),
        ('Window gold', 'F5C76C'), ('Window light', 'FFE6A1'), ('Stone', 'A6A69B'),
        ('Path', 'C6B69A'), ('Water', '647F98'), ('Reflection', 'A6BBC1')]
    p = Picture(palette)
    p.rect(0, 12, 63, 21, 2)
    p.rect(0, 22, 63, 32, 3)
    p.ellipse(48, 10, 5, 5, 4)
    p.ellipse(50, 8, 4, 4, 1)
    for x, y in [(7, 7), (24, 5), (34, 11), (58, 18)]:
        p.dot(x, y, 4)
    p.poly([(0, 30), (14, 13), (25, 26), (38, 16), (60, 32)], 5)
    p.poly([(6, 24), (14, 13), (19, 21), (14, 19), (12, 23)], 6)
    p.poly([(31, 25), (38, 16), (44, 24), (39, 22), (37, 23)], 6)
    for x, size in [(1, 13), (9, 16), (18, 11), (48, 13), (58, 18), (64, 13)]:
        p.pine(x, 39, size, 7, 10, 16)
    p.rect(0, 39, 63, 63, 11)
    p.poly([(0, 45), (20, 39), (43, 45), (63, 41), (63, 63), (0, 63)], 12)
    p.poly([(46, 44), (53, 45), (44, 52), (46, 57), (63, 59), (63, 63), (40, 63), (35, 56), (39, 49)], 23)
    for x, y, length in [(46, 48, 3), (39, 54, 5), (45, 60, 9), (52, 62, 5)]:
        p.line(x, y, x + length, y, 24)
    p.poly([(29, 47), (33, 47), (38, 63), (21, 63)], 22)
    p.line(26, 55, 33, 55, 21)
    p.line(24, 61, 35, 61, 21)
    # Shingled roof, log walls, golden mullioned windows, chimney smoke.
    p.rect(16, 30, 43, 47, 16)
    p.rect(18, 32, 41, 45, 17)
    for y in [34, 38, 42, 46]:
        p.line(17, y, 42, y, 16)
        p.line(18, y - 1, 40, y - 1, 18)
    p.rect(34, 19, 38, 29, 16)
    p.line(34, 18, 39, 18, 21)
    p.poly([(12, 33), (29, 18), (47, 33)], 13)
    p.poly([(16, 31), (29, 20), (43, 31)], 14)
    for y in [25, 28, 31]:
        p.line(29 - (y - 20), y, 29 + (y - 20), y, 15)
        for x in range(20, 42, 4):
            if p.pixels[y][x] == 15:
                p.dot(x, y, 13)
    p.line(13, 33, 46, 33, 18)
    p.rect(27, 35, 33, 46, 16)
    p.rect(28, 36, 32, 45, 19)
    p.rect(29, 37, 31, 40, 20)
    p.dot(31, 43, 16)
    for x in [19, 36]:
        p.rect(x, 35, x + 5, 41, 13)
        p.rect(x + 1, 36, x + 4, 40, 19)
        p.rect(x + 1, 36, x + 2, 38, 20)
        p.line(x + 2, 36, x + 2, 40, 16)
        p.line(x + 1, 38, x + 4, 38, 16)
        p.line(x - 1, 42, x + 6, 42, 18)
    p.rect(15, 47, 44, 48, 21)
    for x, y in [(36, 15), (34, 12), (36, 9)]:
        p.ellipse(x, y, 2, 1, 2)
    for x, y, size in [(4, 54, 24), (58, 53, 27), (63, 62, 21)]:
        p.pine(x, y, size, 8, 9, 16)
    rng = random.Random(19)
    for _ in range(65):
        x, y = rng.randrange(64), rng.randrange(49, 64)
        if p.pixels[y][x] in (11, 12):
            p.dot(x, y, rng.choice([10, 11, 4]))
    return p


def wings():
    palette = [
        ('Pale sky', 'CDDCD6'), ('Sky light', 'E3E8D8'), ('Sun haze', 'F8EDD1'),
        ('Distant meadow', 'A9B69A'), ('Grass', '779978'), ('Leaf shadow', '3E6558'),
        ('Leaf', '5D8765'), ('Leaf light', 'A1B97B'), ('Wing outline', '3D3D59'),
        ('Indigo', '5D5282'), ('Violet', '8774AD'), ('Lavender', 'B59FD0'),
        ('Lilac', 'DECEE6'), ('Wing pearl', 'FFF1D3'), ('Rose shadow', 'A2537C'),
        ('Rose', 'CE7CA0'), ('Blush', 'EAAEBF'), ('Body light', '8B7690'),
        ('Pollen', 'D5A456'), ('Daisy', 'F5E4B6'), ('Wildflower', 'D99572'),
        ('Earth', '9C9572')]
    p = Picture(palette)
    p.rect(0, 13, 63, 30, 2)
    p.ellipse(12, 10, 8, 7, 3)
    p.poly([(0, 35), (15, 27), (34, 33), (47, 25), (63, 31), (63, 63), (0, 63)], 4)
    p.poly([(0, 45), (19, 38), (40, 45), (63, 36), (63, 63), (0, 63)], 5)
    # Symmetrical scalloped wings with inset bands, veins, and pearl markings.
    for mirror in [False, True]:
        def poly(points, c):
            p.poly([(63 - x if mirror else x, y) for x, y in points], c)
        def line(x0, y0, x1, y1, c):
            p.line(63 - x0 if mirror else x0, y0, 63 - x1 if mirror else x1, y1, c)
        def ellipse(x, y, rx, ry, c):
            p.ellipse(63 - x if mirror else x, y, rx, ry, c)
        poly([(31, 28), (24, 17), (12, 10), (7, 11), (5, 18), (7, 28), (15, 36), (29, 39)], 9)
        poly([(29, 29), (22, 19), (12, 13), (8, 14), (8, 22), (13, 30), (24, 35), (29, 36)], 10)
        poly([(27, 29), (21, 21), (12, 16), (10, 17), (12, 25), (18, 30), (27, 34)], 11)
        poly([(25, 28), (20, 22), (13, 18), (14, 24), (20, 28), (27, 32)], 12)
        poly([(24, 28), (18, 22), (16, 21), (18, 25)], 13)
        poly([(30, 36), (18, 34), (9, 38), (9, 44), (14, 51), (21, 53), (29, 47), (32, 39)], 9)
        poly([(29, 38), (18, 37), (12, 40), (14, 46), (21, 50), (27, 45), (30, 40)], 15)
        poly([(27, 39), (18, 39), (15, 41), (18, 46), (22, 47), (27, 43)], 16)
        poly([(25, 40), (19, 41), (20, 44), (23, 44)], 17)
        for end in [(10, 16), (10, 23), (15, 30), (20, 49), (13, 41)]:
            line(30, 36, *end, 9)
        for x, y in [(8, 15), (8, 19), (10, 27), (15, 32), (21, 35), (11, 41), (15, 47), (21, 51), (26, 47)]:
            ellipse(x, y, .8, 1.1, 14)
        ellipse(17, 24, 2.3, 3, 10)
        ellipse(17, 24, 1.2, 1.6, 13)
        ellipse(20, 43, 2, 2, 15)
        ellipse(20, 43, .9, .9, 14)
    p.ellipse(31.5, 35, 2, 12, 9)
    p.line(31, 27, 31, 42, 18)
    p.ellipse(31.5, 24, 2, 2, 9)
    p.line(30, 23, 27, 18, 9)
    p.line(33, 23, 36, 18, 9)
    p.dot(27, 18, 14)
    p.dot(36, 18, 14)
    # Foreground daisies and fine stems frame the central butterfly.
    for x, y, radius in [(5, 50, 2), (13, 58, 3), (45, 57, 3), (58, 47, 2), (31, 60, 2)]:
        p.line(x, 63, x, y, 6)
        p.poly([(x, y + 8), (x - 5, y + 5), (x - 3, y + 10), (x, y + 11)], 7)
        p.flower(x, y, radius, 20, 21, 19)
    for x, y in [(3, 60), (24, 59), (53, 61), (61, 58)]:
        p.line(x, 63, x - 1, y - 4, 8)
    return p


SCENES = [
    ('garden-64-v1', 'Sunlit garden', 'Petals, terracotta, and a winding garden path.', 'camera.macro', garden),
    ('cabin-64-v1', 'Cabin at dusk', 'Warm windows beneath a mountain evening.', 'house', cabin),
    ('wings-64-v1', 'Wildflower wings', 'Discover every pattern in a meadow butterfly.', 'sparkles', wings),
]


def png(path, pictures, scale=6):
    width, height = 64 * len(pictures), 64
    scan = bytearray()
    for y in range(height):
        row = bytearray()
        for p in pictures:
            for n in p.pixels[y]:
                rgb = bytes.fromhex(p.palette[n - 1][1])
                row.extend(rgb * scale)
        for _ in range(scale):
            scan.append(0)
            scan.extend(row)
    def chunk(kind, content):
        return struct.pack('>I', len(content)) + kind + content + struct.pack('>I', zlib.crc32(kind + content))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width * scale, height * scale, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(scan)) + chunk(b'IEND', b''))


def main():
    rendered = []
    result = ['// BEGIN GENERATED SCENES — tools/generate_scenes.py', 'extension Puzzle {', '    static let detailed: [Puzzle] = [']
    for id_, title, subtitle, symbol, draw in SCENES:
        p = draw()
        rendered.append(p)
        used = {c for row in p.pixels for c in row}
        assert all(1 <= c <= len(p.palette) for c in used)
        # Remove unused palette entries and keep numbers contiguous.
        lookup = {c: i + 1 for i, c in enumerate(sorted(used))}
        result.append(f'        Puzzle(id: "{id_}", title: "{title}", subtitle: "{subtitle}", symbol: "{symbol}", rows: [')
        result.extend('            "' + ''.join(SYMBOLS[lookup[c]] for c in row) + '",' for row in p.pixels)
        result.append('        ], palette: [')
        result.extend(f'            PaintColor(id: {lookup[i]}, name: "{name}", hex: 0x{hex_}),' for i, (name, hex_) in enumerate(p.palette, 1) if i in used)
        result.append('        ]),')
    result.extend(['    ]', '}', '// END GENERATED SCENES'])
    source = ROOT / 'PixelBloom/Puzzle.swift'
    text = source.read_text().split('// BEGIN GENERATED SCENES')[0].rstrip()
    source.write_text(text + '\n\n' + '\n'.join(result) + '\n')
    png(Path('/private/tmp/PixelBloom-detailed-scenes.png'), rendered)
    print('Generated three 64×64 scenes and a local art QA contact sheet.')


if __name__ == '__main__':
    main()
