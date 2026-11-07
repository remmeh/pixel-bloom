"""Generate original 64×64 character scenes from the U.S. Sanrio shop roster."""
from pathlib import Path
from math import cos, pi, sin

from generate_scenes import Picture, ROOT, SYMBOLS, png


COLORS = {
    'Ink': '423344', 'Shadow': '64536C', 'White': 'FFF9ED', 'Cream': 'F7E2BD',
    'Gray': 'B5A8A6', 'Gray shade': '938384', 'Cocoa': '9D664E',
    'Caramel': 'D2986C', 'Sand': 'EABA86', 'Red': 'D95068',
    'Rose': 'EF89A4', 'Blush': 'F9B8C9', 'Lavender': 'B8A3DC',
    'Purple': '7862A7', 'Blue': '5E91C1', 'Sky': 'A3D4EF',
    'Teal': '489E9C', 'Mint': 'A6D8BC', 'Green': '8ABA68',
    'Leaf': '52845E', 'Lemon': 'FFE38B', 'Gold': 'EAA64E',
    'Peach': 'F4AA84', 'Coral': 'E68175',
}

SETTINGS = {
    'garden': ('D5E6D8', 'EDF2D9', 'ABC99A', '7FAD86'),
    'picnic': ('F8DCCD', 'FCECD6', 'B8CD9F', '8DAC86'),
    'cloud': ('C6DDF0', 'E4EEF8', 'E6DFF0', 'B9B0D4'),
    'night': ('857EAD', 'A59BC2', 'C1ACCE', '87729B'),
    'sea': ('ACDAD8', 'D8EDE3', '87C7C9', '62A9B7'),
    'cafe': ('F4D4BA', 'FFF0D5', 'DDAB91', 'BF8777'),
    'party': ('EAD2EA', 'F7E5F3', 'C5B8E0', 'A093C5'),
}


class Scene(Picture):
    def __init__(self, setting):
        self.colors = dict(COLORS)
        self.colors.update(zip(('Backdrop', 'Soft light', 'Ground', 'Ground shade'), SETTINGS[setting]))
        self.indices = {}
        super().__init__([])
        self.rect(0, 0, 63, 63, self.color('Backdrop'))
        self.oval(45, 14, 12, 12, 'Soft light')
        self.polygon([(0, 47), (14, 43), (32, 48), (52, 43), (64, 47), (64, 64), (0, 64)], 'Ground')
        self.oval(32, 54, 23, 5, 'Ground shade')
        if setting in ('night', 'party'):
            for x, y in [(7, 12), (54, 27), (57, 8), (11, 34), (47, 6)]:
                self.star(x, y, 2.8, 'Lemon')
        elif setting == 'sea':
            for x, y in [(7, 16), (57, 30), (55, 9), (10, 38)]:
                self.oval(x, y, 2, 2, 'Soft light')
                self.point(x, y - 1, 'White')
        elif setting == 'cafe':
            for x in [3, 13, 52, 61]:
                self.segment(x, 0, x, 42, 'Soft light')
        else:
            for x, y in [(7, 15), (53, 12), (57, 32)]:
                self.oval(x, y, 5, 2, 'Soft light')
        for x, y in [(5, 55), (12, 60), (54, 57), (60, 51)]:
            self.segment(x, y, x + 2, y, 'Soft light')

    def color(self, name):
        if name not in self.indices:
            self.palette.append((name, self.colors[name]))
            self.indices[name] = len(self.palette)
        return self.indices[name]

    def point(self, x, y, color):
        self.dot(x, y, self.color(color))

    def oval(self, x, y, rx, ry, color, outline=False):
        if outline:
            self.ellipse(x, y, rx + 1, ry + 1, self.color('Ink'))
        self.ellipse(x, y, rx, ry, self.color(color))

    def polygon(self, points, color, outline=False):
        self.poly(points, self.color(color))
        if outline:
            for a, b in zip(points, points[1:] + points[:1]):
                self.segment(*a, *b, 'Ink')

    def segment(self, x, y, end_x, end_y, color):
        self.line(x, y, end_x, end_y, self.color(color))

    def block(self, x, y, end_x, end_y, color):
        self.rect(x, y, end_x, end_y, self.color(color))

    def star(self, x, y, radius, color):
        points = [(round(x + cos(i * pi / 5 - pi / 2) * radius * (1 if i % 2 == 0 else .44)),
                   round(y + sin(i * pi / 5 - pi / 2) * radius * (1 if i % 2 == 0 else .44)))
                  for i in range(10)]
        self.polygon(points, color)

    def bow(self, x, y, color='Red'):
        self.oval(x - 4, y, 4, 3, color, True)
        self.oval(x + 4, y, 4, 3, color, True)
        self.oval(x, y, 2, 2, color, True)
        self.point(x - 5, y - 1, 'Blush')
        self.point(x + 4, y - 1, 'Blush')

    def face(self, x, y, gap=7, cheeks=True):
        for sign in [-1, 1]:
            self.oval(x + sign * gap, y, 1.3, 1.8, 'Ink')
            if cheeks:
                self.oval(x + sign * (gap + 3), y + 4, 2, 1, 'Blush')
        self.segment(x - 2, y + 4, x, y + 5, 'Ink')
        self.segment(x, y + 5, x + 2, y + 4, 'Ink')

    def flower_at(self, x, y, color='Rose', radius=2):
        for dx, dy in [(-radius, 0), (radius, 0), (0, -radius), (0, radius)]:
            self.oval(x + dx, y + dy, radius, radius, color)
        self.oval(x, y, radius, radius, 'Gold')

    def cookie(self, x, y, radius=5):
        self.oval(x, y, radius, radius, 'Sand', True)
        for dx, dy in [(-2, -1), (2, -2), (1, 2), (-2, 2)]:
            self.point(x + dx, y + dy, 'Cocoa')

    def body(self, color, x=32, y=44):
        self.oval(x, y, 12, 10, color, True)
        for sign in [-1, 1]:
            self.oval(x + sign * 9, y + 8, 5, 3, color, True)
            self.oval(x + sign * 12, y - 1, 3, 5, color, True)

    def cat(self, fur='White', clothes='Blue', style='kitty'):
        self.body(clothes)
        self.polygon([(15, 29), (16, 13), (29, 21), (37, 21), (47, 13), (48, 30)], fur, True)
        self.oval(32, 31, 18, 13, fur, True)
        self.polygon([(17, 24), (17, 16), (24, 21)], 'Blush')
        self.polygon([(41, 21), (46, 16), (46, 24)], 'Blush')
        for sign in [-1, 1]:
            self.oval(32 + sign * 8, 32, 2 if style == 'choco' else 1.2, 2, 'Ink')
            for i in [-1, 0, 1]:
                self.segment(32 + sign * 14, 34 + i * 2, 32 + sign * 20, 34 + i * 3, 'Ink')
        self.oval(32, 36, 2, 1, 'Gold' if style != 'choco' else 'Cocoa')
        if style in ('kitty', 'charmmy'):
            self.bow(44 if style == 'kitty' else 18, 20, 'Red' if style == 'kitty' else 'Rose')
        if style == 'charmmy':
            self.oval(32, 46, 3, 3, 'Gold', True)
            self.segment(32, 46, 32, 52, 'Gold')
            self.segment(32, 51, 35, 51, 'Gold')
            for x in [17, 21, 43, 47]:
                self.oval(x, 41, 3, 3, 'White')
        if style == 'daniel':
            self.polygon([(25, 22), (25, 15), (31, 18), (34, 12), (36, 19), (41, 16), (39, 23)], 'White', True)
            self.bow(32, 45, 'Blue')
        if style == 'choco':
            self.block(24, 42, 40, 45, 'Blue')
            for x in [24, 40]:
                self.oval(x, 32, 2, 2, 'White')
                self.point(x, 32, 'Ink')

    def floppy(self, fur, style):
        self.body(fur)
        self.oval(15, 32, 10, 5 if style != 'pochacco' else 7, fur if style != 'pochacco' else 'Ink', True)
        self.oval(49, 32, 10, 5 if style != 'pochacco' else 7, fur if style != 'pochacco' else 'Ink', True)
        self.oval(32, 30, 15, 12, fur, True)
        self.face(32, 31)
        if style == 'cinnamoroll':
            self.segment(26, 48, 35, 48, 'Sky')
            self.segment(35, 48, 35, 45, 'Sky')
            self.segment(35, 45, 30, 45, 'Sky')
            self.oval(25, 31, 1, 2, 'Blue')
            self.oval(39, 31, 1, 2, 'Blue')
        elif style == 'mocha':
            for x in [16, 48]:
                self.flower_at(x, 30, 'Rose')
            self.polygon([(24, 44), (40, 44), (43, 52), (21, 52)], 'Rose', True)
            self.bow(32, 45, 'Blush')
        else:
            self.block(23, 44, 41, 50, 'Red')
            self.segment(26, 20, 29, 16, 'Ink')
            self.segment(31, 19, 34, 16, 'Ink')
            self.segment(37, 20, 39, 17, 'Ink')

    def bunny(self, x, y, fur, hood=None, small=False):
        scale = .68 if small else 1
        rx = 10 if small else 14
        ry = 8 if small else 11
        for sign in [-1, 1]:
            ear = hood or fur
            if hood == 'rainbow':
                ear = 'Rose' if sign == -1 else 'Teal'
            self.oval(x + sign * round(7 * scale), y - round(16 * scale), 4 * scale, 9 * scale, ear, True)
            self.oval(x + sign * round(7 * scale), y - round(17 * scale), 2 * scale, 5 * scale, 'Blush')
        head = 'Lemon' if hood == 'rainbow' else (hood or fur)
        self.oval(x, y + ry + 4, rx - 2, 6 * scale, head, True)
        self.oval(x, y, rx, ry, head, True)
        if hood and hood != 'rainbow':
            self.oval(x, y + 2, rx - 3, ry - 3, fur)
        self.face(x, y + 1, 4 if small else 6)

    def penguin(self, color, sam=False):
        if sam:
            for x in [23, 41]:
                self.oval(x, 52, 6, 3, 'Gold', True)
        self.body(color)
        if sam:
            self.oval(32, 42, 13, 12, 'White')
            self.oval(32, 29, 15, 12, color, True)
            self.oval(32, 34, 7, 3, 'Gold', True)
            for x in [26, 38]:
                self.oval(x, 29, 1.3, 2, 'Ink')
            self.bow(32, 42, 'Red')
            self.oval(38, 18, 10, 2, 'White', True)
            self.block(32, 13, 44, 17, 'White')
            self.segment(32, 16, 44, 16, 'Blue')
        else:
            self.oval(32, 44, 8, 7, 'White')
            self.polygon([(15, 29), (15, 15), (22, 20), (25, 12), (32, 19),
                          (39, 12), (42, 20), (49, 15), (49, 33), (43, 39), (22, 39)], color, True)
            for x in [24, 40]:
                self.oval(x, 29, 5, 3, 'White')
                self.oval(x, 29, 1.2, 2, 'Ink')
                self.segment(x - 5, 27, x + 5, 27, 'Ink')
            self.oval(32, 35, 4, 2, 'Gold')


def hello_kitty(p):
    p.cat()
    p.flower_at(8, 47)
    p.flower_at(56, 49, 'White')


def charmmy(p):
    p.cat(clothes='White', style='charmmy')
    p.star(9, 40, 4, 'Gold')
    p.star(54, 39, 3, 'White')


def choco(p):
    p.cat('Shadow', 'Ink', 'choco')
    p.cookie(55, 46)


def daniel(p):
    p.cat(clothes='Blue', style='daniel')
    p.star(53, 44, 4, 'Gold')


def cinnamoroll(p):
    p.floppy('White', 'cinnamoroll')
    for x in [8, 52]:
        p.oval(x, 51, 6, 2, 'White')


def mocha(p):
    p.floppy('Cocoa', 'mocha')
    p.cookie(55, 49)


def pochacco(p):
    p.floppy('White', 'pochacco')
    p.oval(52, 46, 6, 6, 'White', True)
    p.star(52, 46, 4, 'Blue')


def melody(p):
    p.bunny(32, 34, 'White', 'Rose')
    p.bow(43, 25, 'Red')
    p.flower_at(10, 49, 'White')


def kuromi(p):
    p.body('Purple')
    p.polygon([(16, 35), (12, 11), (25, 21), (39, 21), (52, 11), (48, 35), (40, 46), (24, 46)], 'Ink', True)
    p.oval(32, 34, 13, 10, 'White')
    p.oval(12, 11, 3, 3, 'Ink')
    p.oval(52, 11, 3, 3, 'Ink')
    p.oval(32, 24, 4, 3, 'Rose')
    p.block(30, 25, 34, 28, 'Rose')
    p.point(30, 24, 'Ink')
    p.point(34, 24, 'Ink')
    p.face(32, 34)
    p.star(54, 43, 3, 'Lavender')


def purin(p):
    p.body('Lemon')
    p.oval(17, 36, 5, 8, 'Gold', True)
    p.oval(47, 36, 5, 8, 'Gold', True)
    p.oval(32, 32, 15, 13, 'Lemon', True)
    p.oval(32, 20, 11, 4, 'Cocoa', True)
    p.segment(32, 15, 33, 18, 'Ink')
    p.face(32, 32)
    p.oval(52, 50, 7, 3, 'White')
    p.polygon([(47, 48), (48, 41), (55, 41), (57, 48)], 'Lemon', True)
    p.oval(52, 41, 4, 1.5, 'Cocoa')


def keroppi(p):
    p.body('Red')
    for x in [24, 30, 36, 42]:
        p.segment(x, 43, x, 49, 'White')
    p.oval(32, 33, 16, 11, 'Green', True)
    for x in [23, 41]:
        p.oval(x, 25, 7, 7, 'White', True)
        p.oval(x, 26, 2, 3, 'Ink')
    p.segment(28, 34, 32, 38, 'Ink')
    p.segment(32, 38, 36, 34, 'Ink')
    p.oval(20, 34, 3, 2, 'Rose')
    p.oval(44, 34, 3, 2, 'Rose')
    p.oval(52, 50, 7, 3, 'Leaf')
    p.flower_at(53, 46)


def badtz(p):
    p.penguin('Ink')
    p.star(52, 45, 4, 'Gold')


def tuxedo(p):
    p.penguin('Blue', sam=True)
    p.oval(54, 47, 5, 5, 'Sky', True)
    p.segment(54, 44, 54, 50, 'White')


def pusheen(p):
    p.oval(47, 42, 10, 4, 'Gray', True)
    for x in [49, 53]:
        p.segment(x, 39, x, 45, 'Gray shade')
    p.polygon([(12, 34), (13, 20), (23, 25), (35, 25), (42, 20), (45, 35)], 'Gray', True)
    p.oval(29, 39, 18, 13, 'Gray', True)
    for x in [21, 31, 41]:
        p.oval(x, 50, 3, 2, 'Gray', True)
    for x in [22, 28, 34]:
        p.block(x, 26, x + 1, 30, 'Gray shade')
    for x in [20, 36]:
        p.oval(x, 36, 1.3, 1.5, 'Ink')
    p.segment(25, 39, 27, 40, 'Ink')
    p.segment(27, 40, 29, 38, 'Ink')
    p.segment(29, 38, 31, 40, 'Ink')
    p.segment(31, 40, 33, 39, 'Ink')
    for y in [36, 40]:
        p.segment(8, y, 15, y, 'Ink')
        p.segment(43, y, 49, y, 'Ink')
    p.cookie(53, 50)


def cogimyun(p):
    p.oval(32, 39, 18, 14, 'White', True)
    for x, y, rx, ry in [(18, 29, 7, 7), (25, 23, 7, 7), (34, 21, 8, 7),
                         (44, 26, 8, 8), (48, 35, 7, 7), (17, 42, 6, 6)]:
        p.oval(x, y, rx, ry, 'White', True)
    p.oval(32, 35, 17, 14, 'White')
    p.oval(24, 49, 4, 3, 'White', True)
    p.oval(41, 49, 4, 3, 'White', True)
    p.face(32, 35)
    p.bow(43, 22, 'Rose')
    p.oval(54, 46, 5, 3, 'Peach', True)
    p.polygon([(54, 43), (58, 39), (60, 45)], 'Coral', True)


def coro(p):
    p.oval(32, 38, 17, 15, 'Gold', True)
    for x in [19, 45]:
        p.oval(x, 25, 6, 6, 'Caramel', True)
        p.oval(x, 25, 3, 3, 'Blush')
    p.oval(32, 38, 13, 11, 'Cream')
    p.face(32, 35, 6)
    p.oval(32, 40, 2, 1, 'Cocoa')
    p.flower_at(32, 21, 'White', radius=3)
    for x in [20, 43]:
        p.oval(x, 50, 4, 3, 'Caramel', True)
    p.cookie(52, 48)


def gao(p):
    p.polygon([(40, 46), (50, 45), (58, 37), (57, 48), (48, 53), (38, 52)], 'Cream', True)
    p.body('Cream')
    p.oval(32, 46, 8, 7, 'Lemon')
    for y in [42, 46, 50]:
        p.segment(26, y, 38, y, 'Gold')
    p.polygon([(21, 25), (23, 16), (28, 22), (32, 15), (35, 22), (42, 17), (43, 26)], 'Cream', True)
    p.oval(32, 31, 15, 11, 'Cream', True)
    for x in [26, 38]:
        p.oval(x, 30, 1, 2, 'Ink')
        p.oval(x, 35, 3, 1, 'Blush')
    p.oval(32, 35, 4, 3, 'Ink')
    p.point(31, 34, 'White')
    p.point(34, 34, 'White')
    p.star(10, 46, 4, 'Lemon')


def gudetama(p):
    p.oval(31, 47, 21, 8, 'White', True)
    p.oval(29, 46, 12, 5, 'Cream')
    p.oval(32, 40, 13, 10, 'Gold', True)
    p.oval(30, 37, 10, 7, 'Lemon')
    p.oval(25, 38, 1, 2, 'Ink')
    p.oval(33, 37, 1, 2, 'Ink')
    p.oval(30, 42, 3, 1, 'Ink')
    p.oval(43, 47, 5, 2, 'Gold')
    p.polygon([(46, 18), (52, 13), (56, 18), (53, 23), (57, 27), (47, 28)], 'White', True)
    p.segment(45, 54, 57, 45, 'Cocoa')


def hana(p):
    p.polygon([(21, 36), (22, 49), (17, 53), (28, 56), (43, 54), (49, 47), (43, 36)], 'White', True)
    p.oval(32, 33, 16, 14, 'White', True)
    p.oval(32, 43, 13, 7, 'White')
    p.face(32, 34, 6)
    p.oval(33, 18, 4, 4, 'Red', True)
    p.segment(34, 15, 37, 10, 'Leaf')
    p.polygon([(45, 45), (54, 28), (58, 30), (49, 47)], 'Red', True)
    p.polygon([(45, 45), (49, 47), (44, 51)], 'Sand', True)
    p.flower_at(10, 43, 'Rose')


def hangyo(p):
    p.body('Teal')
    p.oval(32, 32, 16, 14, 'Teal', True)
    for sign in [-1, 1]:
        p.polygon([(32 + sign * 15, 30), (32 + sign * 23, 27), (32 + sign * 21, 39),
                   (32 + sign * 14, 38)], 'Teal', True)
        p.oval(32 + sign * 7, 27, 5, 7, 'White', True)
        p.oval(32 + sign * 6, 28, 2, 3, 'Ink')
    p.oval(32, 38, 9, 4, 'Coral', True)
    p.segment(26, 38, 38, 38, 'Ink')
    p.oval(53, 47, 5, 5, 'Rose', True)
    for x in [49, 53, 57]:
        p.oval(x, 51, 2, 3, 'Rose')
    p.point(51, 46, 'Ink')
    p.point(55, 46, 'Ink')


def kiri(p):
    for x in [26, 38]:
        p.segment(x, 43, x - 2, 52, 'Ink')
        p.oval(x - 2, 52, 3, 1, 'Ink')
    p.polygon([(12, 28), (18, 21), (31, 18), (45, 21), (53, 29),
               (49, 39), (35, 47), (19, 42)], 'Coral', True)
    p.polygon([(12, 28), (19, 24), (33, 25), (48, 32), (51, 36),
               (35, 47), (19, 42)], 'Peach')
    p.segment(17, 29, 29, 36, 'Cream')
    p.segment(31, 36, 45, 38, 'Cream')
    p.oval(28, 31, 1, 2, 'Ink')
    p.oval(41, 33, 1, 2, 'Ink')
    p.segment(32, 36, 36, 37, 'Ink')
    p.oval(53, 48, 6, 3, 'White', True)
    p.oval(53, 46, 5, 2, 'Coral')


def twins(p):
    p.star(32, 45, 16, 'Lemon')
    for x, hair in [(21, 'Sky'), (43, 'Rose')]:
        p.oval(x, 43, 7, 10, 'White', True)
        p.oval(x, 29, 11, 12, hair, True)
        p.oval(x, 32, 8, 7, 'Cream')
        p.polygon([(x - 8, 28), (x - 7, 22), (x + 7, 22), (x + 8, 26),
                   (x + 3, 30), (x + 1, 27), (x - 3, 30), (x - 4, 27)], hair)
        p.face(x, 32, 3)
    p.star(11, 18, 4, 'White')
    p.star(52, 14, 3, 'White')


def lloromannic(p):
    p.oval(32, 33, 25, 24, 'Purple', True)
    p.oval(32, 33, 22, 21, 'Soft light')
    for x, fur, horn in [(21, 'Shadow', 'Purple'), (43, 'Rose', 'Red')]:
        p.polygon([(x - 8, 33), (x - 11, 22), (x - 2, 27), (x + 2, 27),
                   (x + 10, 22), (x + 8, 33)], horn, True)
        p.oval(x, 44, 7, 8, fur, True)
        p.oval(x, 34, 10, 8, fur, True)
        p.oval(x, 36, 7, 5, 'Cream')
        p.face(x, 35, 3, False)
        p.point(x - 1, 40, 'White')
        p.point(x + 1, 40, 'White')
    p.star(32, 16, 4, 'Lemon')


def marron(p):
    p.bunny(32, 34, 'Cream')
    p.polygon([(23, 42), (41, 42), (45, 54), (19, 54)], 'Rose', True)
    for x in [24, 30, 36, 42]:
        p.segment(x, 47, x, 52, 'White')
    p.bow(34, 24, 'Red')
    p.oval(50, 50, 6, 4, 'Caramel', True)
    p.oval(50, 46, 4, 4, 'White', True)
    p.block(46, 47, 54, 51, 'Sand')
    p.flower_at(9, 46, 'White')


def piano(p):
    p.body('Rose')
    for x, y in [(18, 33), (20, 25), (27, 21), (35, 20), (43, 23),
                 (49, 30), (47, 38), (38, 41), (27, 41), (19, 39)]:
        p.oval(x, y, 6, 6, 'Rose', True)
    p.oval(32, 32, 16, 13, 'Rose')
    p.oval(32, 34, 12, 9, 'Blush')
    p.face(32, 34, 6)
    p.flower_at(44, 22, 'White', 2)
    p.flower_at(10, 50, 'White')


def pekkle(p):
    p.body('Sky')
    for x in [24, 40]:
        p.oval(x, 52, 5, 3, 'Gold', True)
    p.oval(32, 30, 15, 13, 'White', True)
    for x in [26, 38]:
        p.oval(x, 30, 1.4, 2, 'Ink')
    p.oval(32, 36, 7, 3, 'Gold', True)
    p.polygon([(29, 18), (31, 13), (35, 16), (38, 17)], 'White', True)
    p.block(26, 44, 38, 48, 'Blue')
    p.segment(30, 44, 30, 48, 'White')
    p.segment(30, 44, 34, 44, 'White')
    p.segment(30, 46, 34, 46, 'White')
    p.oval(53, 49, 5, 2, 'White')
    p.segment(47, 53, 57, 53, 'Blue')


def sugar(p):
    p.bunny(20, 33, 'White', small=True)
    p.bunny(44, 33, 'Cocoa', small=True)
    p.bow(20, 44, 'Rose')
    p.bow(44, 44, 'Sky')
    p.oval(32, 52, 9, 3, 'White', True)
    p.block(25, 46, 39, 51, 'Sand')
    p.oval(32, 46, 7, 2, 'White', True)
    p.oval(32, 43, 3, 2, 'Red')
    p.cookie(9, 51, 3)


def usahana(p):
    p.bunny(32, 34, 'White', 'rainbow')
    p.oval(25, 49, 5, 4, 'Mint', True)
    p.oval(39, 49, 5, 4, 'Lavender', True)
    p.flower_at(42, 24, 'White')
    p.flower_at(10, 47, 'Rose')
    p.flower_at(54, 47, 'Lavender')
    p.flower_at(57, 54, 'White')


# Keep the roster in the same order as the Sanrio U.S. shop navigation.
SANRIO = [
    ('badtz-maru', 'Badtz-maru', 'A mischievous penguin under the stars.', 'night', badtz),
    ('charmmy-kitty', 'Charmmy Kitty', 'A fluffy cat with a tiny golden key.', 'party', charmmy),
    ('chococat', 'Chococat', 'A chocolate-nosed cat and a cookie.', 'cafe', choco),
    ('cinnamoroll', 'Cinnamoroll', 'A long-eared puppy among soft clouds.', 'cloud', cinnamoroll),
    ('cogimyun', 'Cogimyun', 'A flour fairy with a pink bow.', 'cafe', cogimyun),
    ('corocorokuririn', 'Corocorokuririn', 'A flower-capped hamster at a picnic.', 'picnic', coro),
    ('dear-daniel', 'Dear Daniel', 'A blue bow tie and a little star.', 'party', daniel),
    ('gaopowerroo', 'Gaopowerroo', 'A little dinosaur with a striped belly.', 'garden', gao),
    ('gudetama', 'Gudetama', 'A lazy egg taking a breakfast break.', 'cafe', gudetama),
    ('hanamaruobake', 'Hanamaruobake', 'A shy ghost with a cherry and a red pencil.', 'party', hana),
    ('hangyodon', 'Hangyodon', 'An underwater visit with an octopus friend.', 'sea', hangyo),
    ('hello-kitty', 'Hello Kitty', 'A red bow and a patch of garden flowers.', 'garden', hello_kitty),
    ('keroppi', 'Keroppi', 'Big bright eyes by a lily pond.', 'sea', keroppi),
    ('kirimichan', 'Kirimichan', 'A salmon slice on a sushi counter.', 'cafe', kiri),
    ('kuromi', 'Kuromi', 'A mischievous hood under lavender stars.', 'night', kuromi),
    ('little-twin-stars', 'Little Twin Stars', 'Kiki and Lala share a golden star.', 'night', twins),
    ('lloromannic', 'Lloromannic', 'Berry and Cherry in a moonlit mirror.', 'night', lloromannic),
    ('lovelymocha', 'Lovelymocha', 'A chocolate puppy dressed for a cafe visit.', 'cafe', mocha),
    ('marroncream', 'Marroncream', 'A dressed-up rabbit with a little basket.', 'garden', marron),
    ('my-melody', 'My Melody', 'A pink-hooded rabbit on a spring afternoon.', 'garden', melody),
    ('my-sweet-piano', 'My Sweet Piano', 'A fluffy pink sheep among daisies.', 'picnic', piano),
    ('pekkle', 'Pekkle', 'A duck with a blue shirt at the water’s edge.', 'sea', pekkle),
    ('pochacco', 'Pochacco', 'A sporty puppy with a star-patterned ball.', 'garden', pochacco),
    ('pompompurin', 'Pompompurin', 'A golden puppy and a little caramel pudding.', 'cafe', purin),
    ('sugarbunnies', 'Sugarbunnies', 'Shirousa and Kurousa share a berry cake.', 'cafe', sugar),
    ('tuxedosam', 'Tuxedosam', 'A blue penguin in a sailor cap and bow tie.', 'sea', tuxedo),
    ('usahana', 'U*SA*HA*NA', 'A rainbow rabbit in a flower patch.', 'garden', usahana),
]
PUSHEEN = ('pusheen', 'Pusheen', 'A gray tabby enjoying a cookie break.', 'picnic', pusheen)


def swift_puzzle(entry):
    slug, name, subtitle, setting, draw = entry
    scene = Scene(setting)
    draw(scene)
    used = sorted({value for row in scene.pixels for value in row})
    assert used[0] > 0 and len(used) < len(SYMBOLS)
    lookup = {value: index for index, value in enumerate(used, 1)}
    lines = [f'        Puzzle(id: "character-{slug}-64-v1", title: "{name}", '
             f'subtitle: "{subtitle}", symbol: "heart", rows: [']
    lines.extend('            "' + ''.join(SYMBOLS[lookup[value]] for value in row) + '",' for row in scene.pixels)
    lines.append('        ], palette: [')
    lines.extend(f'            PaintColor(id: {lookup[value]}, name: "{scene.palette[value - 1][0]}", '
                 f'hex: 0x{scene.palette[value - 1][1]}),' for value in used)
    lines.append('        ])')
    return '\n'.join(lines), scene


def main():
    generated = [swift_puzzle(entry) for entry in SANRIO + [PUSHEEN]]
    output = [
        '// Generated by tools/generate_characters.py.',
        'extension Puzzle {',
        '    static let sanrio: [Puzzle] = [',
        ',\n'.join(source for source, _ in generated[:-1]),
        '    ]',
        '',
        '    static let pusheen: Puzzle =',
        generated[-1][0],
        '}',
        '',
    ]
    (ROOT / 'PixelBloom/CharacterScenes.swift').write_text('\n'.join(output))
    for start in range(0, len(generated), 7):
        png(Path(f'/private/tmp/PixelBloom-characters-{start // 7 + 1}.png'),
            [scene for _, scene in generated[start:start + 7]], scale=3)
    print(f'Generated {len(generated)} character scenes and four QA strips.')


if __name__ == '__main__':
    main()
