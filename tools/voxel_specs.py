"""Voxel (Steal-a-Brainrot style) designs for each brainrot. Each function draws into a Vox grid."""
import math
from voxel import Vox

WHITE = (250, 250, 250); BLACK = (25, 25, 30); DARK = (40, 35, 45)

def pixel_eye(v, x, y, z=None, size=3, iris=(30, 40, 70), shine=(255, 255, 255), white=None):
    """Steal-a-Brainrot style square eye: optional white rim, dark iris, 1-pixel shine top-right."""
    rows = []
    n = size + (2 if white else 0)
    for r in range(n):
        line = ""
        for c in range(n):
            if white and (r in (0, n - 1) or c in (0, n - 1)):
                line += "w"
            elif (r == (1 if white else 0)) and c == n - (2 if white else 1):
                line += "s"
            else:
                line += "i"
        rows.append(line)
    cols = {"i": iris, "s": shine, "w": white or WHITE}
    v.decal(x - n * v.res / 2, y - n * v.res / 2, rows, cols, z=z)


C = {}

def char(name):
    def wrap(fn):
        C[name] = fn
        return fn
    return wrap


@char("tralalero")
def tralalero(v):
    top, belly, shoe = (95, 140, 195), (238, 242, 246), (35, 110, 235)
    v.ell((0, 4.7, 0.6), (1.6, 1.6, 3.3), v.gradient(1, 3.2, 6.2, (80, 125, 180), (125, 165, 210)))
    v.ell((0, 4.75, -2.6), (1.1, 1.0, 1.5), top)                                   # snout
    v.ell((0, 4.05, 0.2), (1.35, 1.05, 3.1), belly)                                # white belly
    v.ell((0, 4.25, -2.7), (0.85, 0.6, 1.2), belly)
    v.cyl((0, 5.9, 0.4), (0, 7.8, 1.5), 1.0, top, r1=0.15)                         # dorsal fin
    v.cyl((0, 5.0, 3.4), (0, 7.2, 5.3), 0.75, top, r1=0.15)                        # tail up
    v.cyl((0, 4.5, 3.4), (0, 3.2, 4.7), 0.55, top, r1=0.12)                        # tail down
    for sx in (-1, 1):
        v.cyl((sx * 1.2, 4.1, -0.6), (sx * 2.6, 3.3, 0.3), 0.55, top, r1=0.12)     # pectoral fins
        v.box((sx * 0.75 - 0.18, 5.05, -3.05), (sx * 0.75 + 0.18, 5.45, -2.7), BLACK)  # eyes
        v.box((sx * 0.75 - 0.05, 5.3, -3.1), (sx * 0.75 + 0.1, 5.45, -3.0), WHITE)
    v.box((-0.75, 4.05, -4.0), (0.75, 4.3, -3.4), (130, 30, 45))                   # mouth
    for x in (-0.55, -0.2, 0.15, 0.5):
        v.box((x - 0.12, 4.15, -4.05), (x + 0.12, 4.4, -3.9), WHITE)               # teeth
    for (x, z) in ((-0.8, -1.2), (0.8, -1.2), (0, 2.1)):
        v.cyl((x, 4.0, z), (x, 0.8, z), 0.42, top)                                 # legs
        v.rbox((x - 0.6, 0.0, z - 1.25), (x + 0.6, 0.85, z + 0.55), 0.25, shoe)    # Nike sneaker
        v.box((x - 0.62, 0.0, z - 1.27), (x + 0.62, 0.22, z + 0.57), WHITE)        # sole
        v.box((x - 0.64, 0.38, z - 0.9), (x + 0.64, 0.55, z + 0.1), WHITE)         # swoosh
        v.box((x - 0.64, 0.55, z - 0.2), (x + 0.64, 0.7, z + 0.3), WHITE)


@char("tung")
def tung(v):
    wood = v.stripes(1, 0.7, (214, 160, 95), (196, 140, 78))
    v.rbox((-1.25, 2.0, -0.9), (1.25, 9.2, 0.9), 0.6, wood)
    for x in (-0.6, 0.6):
        v.decal(x - 0.525, 7.1, ["www", "wii", "wii", "www"], {"w": WHITE, "i": BLACK})
        v.decal(x - 0.525, 8.65, ["bbb"], {"b": (95, 60, 30)})                     # raised brows
    v.box((-0.2, 6.2, -1.3), (0.2, 6.9, -0.8), (200, 145, 80))                     # nose
    v.decal(-0.7, 5.25, ["m...m", ".mmm."], {"m": (90, 35, 30)})                   # smile
    for sx in (-1, 1):
        v.cyl((sx * 1.2, 6.3, 0), (sx * 1.75, 4.0, -0.3), 0.3, (200, 145, 80))     # arms
        v.cyl((sx * 0.55, 2.1, 0), (sx * 0.6, 0.4, 0), 0.32, (200, 145, 80))       # legs
        v.rbox((sx * 0.6 - 0.4, 0.0, -0.9), (sx * 0.6 + 0.4, 0.45, 0.3), 0.15, (200, 145, 80))
    v.cyl((1.9, 4.1, -0.4), (3.3, 0.7, -0.6), 0.28, (135, 85, 40), r1=0.55, caps=True)  # bat


@char("bombardiro")
def bombardiro(v):
    metal = v.stripes(2, 1.2, (175, 180, 188), (160, 165, 172))
    croc = v.speckle((80, 150, 70), (60, 125, 55), 0.3, seed=3)
    v.cyl((0, 3.6, -0.5), (0, 3.6, 5.2), 1.45, metal, r1=0.8, caps=True)           # fuselage
    v.box((-5.8, 3.3, 0.6), (5.8, 3.75, 2.6), metal)                               # wings
    v.box((-2.4, 3.9, 4.6), (2.4, 4.25, 5.8), metal)                               # tail wing
    v.cyl((0, 4.2, 5.0), (0, 6.3, 5.7), 0.7, metal, r1=0.2)                        # tail fin
    v.rbox((-0.8, 4.6, -0.6), (0.8, 5.4, 1.2), 0.3, (140, 200, 235))               # cockpit
    for sx in (-1, 1):
        v.cyl((sx * 3.2, 3.2, 0.2), (sx * 3.2, 3.2, 2.6), 0.75, (120, 125, 132), caps=True)  # engines
        v.box((sx * 3.2 - 0.12, 1.8, -0.55), (sx * 3.2 + 0.12, 4.6, -0.35), DARK)  # props
        v.box((sx * 3.2 - 1.4, 3.08, -0.55), (sx * 3.2 + 1.4, 3.32, -0.35), DARK)
    v.rbox((-1.3, 2.7, -3.6), (1.3, 4.9, -0.8), 0.5, croc)                         # croc head (plane nose)
    v.rbox((-1.0, 3.75, -7.3), (1.0, 4.65, -3.2), 0.35, croc)                      # upper snout
    v.rbox((-0.95, 2.6, -6.9), (0.95, 3.25, -3.2), 0.3, (55, 115, 50))             # open lower jaw
    v.box((-0.85, 3.25, -6.8), (0.85, 3.75, -3.4), (150, 40, 45))                  # mouth inside
    for z in (-6.5, -5.8, -5.1, -4.4, -3.7):
        for sx in (-1, 1):
            v.box((sx * 0.75 - 0.15, 3.4, z - 0.15), (sx * 0.75 + 0.15, 3.75, z + 0.15), WHITE)   # teeth
    for sx in (-1, 1):
        v.box((sx * 0.4 - 0.12, 4.5, -7.35), (sx * 0.4 + 0.12, 4.7, -7.2), BLACK)  # nostrils
        v.rbox((sx * 0.75 - 0.4, 4.7, -3.5), (sx * 0.75 + 0.4, 5.5, -2.7), 0.2, (255, 220, 60))  # eyes
        v.box((sx * 0.75 - 0.12, 4.85, -3.6), (sx * 0.75 + 0.12, 5.35, -3.45), BLACK)
    v.cyl((0, 1.4, 1.2), (0, 1.4, 2.8), 0.5, (75, 85, 65), caps=True)              # falling bomb
    v.box((-0.5, 1.3, 2.9), (0.5, 1.5, 3.3), (75, 85, 65))


@char("ballerina")
def ballerina(v):
    skin, pink, cup = (240, 205, 180), (245, 160, 185), (250, 250, 248)
    v.cyl((0, 6.5, 0), (0, 9.5, 0), 1.75, cup, r1=2.0)                             # cup head
    v.cyl((0, 9.35, 0), (0, 9.55, 0), 1.75, (180, 120, 70))                         # coffee
    v.cyl((0, 9.45, 0), (0, 9.62, 0), 0.8, (240, 225, 200))                         # latte art
    v.cyl((-1.75, 9.6, 0), (-1.75, 9.65, 0), 0.25, (240, 225, 200))
    v.cyl((2.0, 8.6, 0), (2.7, 7.9, 0), 0.25, cup); v.cyl((2.7, 7.9, 0), (2.0, 7.1, 0), 0.25, cup)   # handle
    fz = -1.95
    for sx in (-1, 1):
        x = sx * 0.7
        v.box((x - 0.4, 7.35, fz - 0.15), (x + 0.4, 8.1, fz + 0.3), WHITE)          # eye white
        v.box((x - 0.2, 7.4, fz - 0.25), (x + 0.25, 7.95, fz + 0.3), (120, 75, 40)) # brown iris
        v.box((x - 0.45, 8.1, fz - 0.25), (x + 0.45, 8.3, fz + 0.3), BLACK)         # lashes
        v.box((sx * 1.3 - 0.25, 6.9, fz - 0.05), (sx * 1.3 + 0.25, 7.15, fz + 0.4), (250, 170, 180))  # cheeks
    v.box((-0.55, 6.75, fz - 0.15), (0.55, 6.95, fz + 0.3), (210, 60, 80))          # smile
    v.box((-0.7, 6.95, fz - 0.15), (-0.5, 7.15, fz + 0.3), (210, 60, 80)); v.box((0.5, 6.95, fz - 0.15), (0.7, 7.15, fz + 0.3), (210, 60, 80))
    v.cyl((0, 6.6, 0), (0, 6.0, 0), 0.35, skin)                                    # neck
    v.rbox((-0.65, 4.1, -0.45), (0.65, 6.1, 0.45), 0.3, pink)                      # leotard
    v.ell((0, 4.1, 0), (2.4, 0.55, 2.4), v.stripes(1, 0.18, (250, 185, 205), (240, 150, 178)))  # tutu
    v.cyl((-0.6, 5.8, 0), (-1.9, 7.4, -0.2), 0.22, skin); v.cyl((0.6, 5.8, 0), (1.6, 7.9, -0.2), 0.22, skin)  # arms up
    for sx in (-1, 1):
        v.cyl((sx * 0.3, 3.8, 0), (sx * 0.3, 0.4, 0), 0.24, skin)                  # legs
        v.rbox((sx * 0.3 - 0.25, 0, -0.55), (sx * 0.3 + 0.25, 0.4, 0.2), 0.12, pink)  # ballet shoes


@char("chimpanzini")
def chimpanzini(v):
    yel, cream, red = (255, 215, 60), (250, 238, 180), (220, 100, 95)
    fur = v.speckle((140, 175, 60), (115, 150, 45), 0.35, seed=5)
    v.cyl((0, 0.9, 0), (0, 3.9, 0), 1.45, yel, r1=1.55, caps=True)                 # banana base
    v.cyl((0.6, 0.6, 0.3), (2.1, 0.5, 0.5), 0.35, (120, 95, 40), caps=True)        # banana tip
    for a in (0.4, 2.0, 3.6, 5.2):
        c, s = math.cos(a), math.sin(a)
        v.cyl((c * 1.0, 4.1, s * 1.0), (c * 2.2, 2.6, s * 2.2), 0.55, yel, caps=True)       # peel strip
        v.cyl((c * 2.2, 2.6, s * 2.2), (c * 2.5, 1.2, s * 2.5), 0.5, yel, caps=True)
        v.cyl((c * 0.95, 4.0, s * 0.95), (c * 2.05, 2.6, s * 2.05), 0.35, cream, caps=True)  # pale inside
    v.cyl((0, 3.8, 0), (0, 5.8, 0), 1.2, fur, caps=True)                            # chimp body
    v.ball((0, 6.6, 0), 1.35, fur)                                                  # head
    v.ell((0, 6.4, -0.85), (0.95, 0.9, 0.6), red)                                   # face
    for sx in (-1, 1):
        v.ell((sx * 1.35, 6.6, -0.1), (0.35, 0.5, 0.3), red)                        # ears
        v.cyl((sx * 1.0, 5.4, -0.2), (sx * 1.9, 4.2, -0.8), 0.32, fur, caps=True)   # arms resting on peel
    for x in (-0.45, 0.45):
        v.decal(x - 0.35, 6.55, ["bb.", "bsb"][::1], {"b": DARK, "s": WHITE})
    v.box((-0.3, 6.0, -1.55), (0.3, 6.35, -1.3), (190, 80, 75))                     # nose
    v.decal(-0.35, 5.7, ["mm"], {"m": (110, 40, 40)})


@char("patapim")
def patapim(v):
    skin, root = (238, 196, 160), v.stripes(1, 0.5, (125, 88, 52), (105, 72, 42))
    moss = v.speckle((90, 150, 55), (70, 120, 40), 0.35, seed=8)
    for sx in (-1, 1):
        v.rbox((sx * 1.3 - 1.0, 0, -2.2), (sx * 1.3 + 1.0, 1.1, 1.2), 0.45, skin)   # giant feet
        for i, dx in enumerate((-0.65, -0.2, 0.2, 0.55)):
            v.ball((sx * 1.3 + dx * sx, 0.55, -2.35), 0.38 - i * 0.04, skin)       # toes
        for dx in (-0.35, 0.35):
            v.cyl((sx * 1.3 + dx, 0.9, -0.3), (sx * 0.6 + dx * 0.5, 4.6, 0.2), 0.3, root)   # root legs
        v.cyl((sx * 1.9, 1.0, 0.6), (sx * 0.9, 4.4, 0.4), 0.22, root)
    v.ell((0, 6.0, 0.3), (2.0, 1.9, 1.8), moss)                                     # mossy head
    v.ell((0, 5.9, -0.9), (1.2, 1.15, 0.8), skin)                                   # face
    v.cyl((0, 5.6, -1.6), (0, 3.9, -2.3), 0.5, skin, r1=0.7, caps=True)             # proboscis nose
    for x in (-0.5, 0.5):
        v.decal(x - 0.35, 6.25, ["bb", "bs"], {"b": DARK, "s": WHITE})
    v.decal(-0.35, 5.0, ["mm"], {"m": (120, 60, 50)})


def two_eyes(v, y, sep=0.55, rows=("bb", "bs"), cols=None):
    cols = cols or {"b": DARK, "s": WHITE}
    w = len(rows[0]) * v.res
    for x in (-sep, sep):
        v.decal(x - w / 2, y, list(rows), cols)


@char("lirili")
def lirili(v):
    cactus = v.stripes(0, 0.5, (95, 175, 80), (80, 155, 65))
    grey = (165, 165, 178)
    v.cyl((0, 1.0, 0), (0, 5.0, 0), 1.35, cactus, caps=True)                        # cactus body
    for a in range(8):
        c, s = math.cos(a * math.pi / 4), math.sin(a * math.pi / 4)
        for y in (2.0, 3.3, 4.4):
            v.box((c * 1.45 - 0.08, y, s * 1.45 - 0.08), (c * 1.45 + 0.25 * c + 0.08, y + 0.12, s * 1.45 + 0.25 * s + 0.08), (245, 240, 200))  # spines
    v.ball((0, 6.0, -0.2), 1.45, grey)                                              # elephant head
    for sx in (-1, 1):
        v.ell((sx * 1.6, 6.1, 0.1), (0.35, 1.0, 0.9), (150, 150, 165))              # ears
        v.ell((sx * 1.6, 6.1, -0.2), (0.2, 0.7, 0.6), (235, 170, 180))
        v.cyl((sx * 0.6, 1.4, 0), (sx * 0.6, 0.3, 0), 0.45, cactus)                 # legs
        v.box((sx * 0.6 - 0.45, 0, -0.8), (sx * 0.6 + 0.45, 0.2, 0.4), (150, 100, 60))   # sandals
        v.box((sx * 0.6 - 0.45, 0.2, -0.5), (sx * 0.6 + 0.45, 0.4, -0.3), (150, 100, 60))
    v.cyl((0, 5.6, -1.4), (0, 3.6, -2.0), 0.5, grey, r1=0.35, caps=True)            # trunk
    two_eyes(v, 6.45, 0.6)
    v.cyl((2.0, 3.6, -0.6), (2.0, 3.6, -0.9), 0.9, (240, 240, 250))                 # pocket clock
    v.box((1.95, 3.5, -1.0), (2.05, 4.1, -0.9), BLACK); v.box((1.95, 3.5, -1.0), (2.35, 3.6, -0.9), BLACK)


@char("cappuccino")
def cappuccino(v):
    cup = (250, 250, 246)
    v.cyl((0, 1.6, 0), (0, 5.6, 0), 1.55, cup, r1=1.75)                             # cup body
    v.cyl((0, 5.45, 0), (0, 5.65, 0), 1.55, (165, 105, 60))                         # coffee
    v.cyl((0, 3.9, 0), (0, 4.7, 0), 1.7, (30, 30, 36))                              # ninja mask band
    v.box((1.5, 4.2, 1.2), (2.4, 4.5, 1.5), (30, 30, 36))                           # mask tails
    two_eyes(v, 4.1, 0.55, rows=("ww.", "wbb"), cols={"w": WHITE, "b": DARK})
    v.cyl((1.8, 4.6, 0), (2.4, 3.9, 0), 0.22, cup); v.cyl((2.4, 3.9, 0), (1.8, 3.1, 0), 0.22, cup)   # handle
    for sx in (-1, 1):
        v.box((sx * 0.8 - 0.07, 3.0, 1.5), (sx * 0.8 + 0.07, 7.5, 1.7), (215, 220, 230))  # katanas on back
        v.box((sx * 0.8 - 0.15, 2.0, 1.45), (sx * 0.8 + 0.15, 3.0, 1.75), (60, 40, 35))
        v.cyl((sx * 1.6, 3.8, 0), (sx * 2.3, 2.6, -0.6), 0.25, (30, 30, 36))        # arms
        v.cyl((sx * 0.6, 1.8, 0), (sx * 0.6, 0.2, 0), 0.35, (30, 30, 36))           # legs
        v.box((sx * 0.6 - 0.35, 0, -0.7), (sx * 0.6 + 0.35, 0.3, 0.3), (30, 30, 36))


@char("tim_cheese")
def tim_cheese(v):
    cheese = (255, 210, 70)
    v.box((-1.6, 1.0, -1.4), (1.6, 3.6, 1.4), cheese)
    v.box((-1.6, 3.6, -0.5), (1.6, 4.4, 1.4), cheese)                               # stepped wedge top
    v.box((-1.6, 4.4, 0.4), (1.6, 5.0, 1.4), cheese)
    for x, y in ((-1.0, 1.6), (0.9, 3.0), (1.0, 1.4), (-0.4, 3.2)):
        v.box((x - 0.25, y - 0.25, -1.5), (x + 0.25, y + 0.25, -1.3), (225, 170, 40))   # holes
    for sx in (-1, 1):
        v.ball((sx * 1.1, 5.4, 0.9), 0.6, (200, 200, 208))                          # mouse ears
        v.ball((sx * 1.1, 5.4, 0.7), 0.35, (240, 160, 175))
        v.cyl((sx * 0.8, 1.1, 0), (sx * 0.8, 0.2, 0), 0.3, (200, 200, 208))
        v.box((sx * 0.8 - 0.3, 0, -0.6), (sx * 0.8 + 0.3, 0.25, 0.3), (200, 200, 208))
    two_eyes(v, 2.6, 0.5)
    v.box((-0.2, 2.1, -1.55), (0.2, 2.35, -1.35), (240, 150, 170))                  # nose
    v.cyl((0.8, 1.6, 1.4), (1.6, 2.6, 2.8), 0.15, (240, 160, 175))                  # tail


@char("noobini")
def noobini(v):
    dough, cheese, crust = (255, 210, 90), (255, 225, 110), (220, 160, 80)
    for i, w in enumerate((1.8, 1.55, 1.3, 1.05, 0.8, 0.55)):                       # slice narrowing down
        v.box((-w, 7.2 - (i + 1) * 0.85, -0.55), (w, 7.2 - i * 0.85, 0.55), v.stripes(0, 0.7, cheese, dough))
    v.rbox((-2.0, 7.0, -0.45), (2.0, 7.8, 0.45), 0.3, crust)                        # crust
    for x, y in ((-0.9, 6.2), (0.8, 5.6), (-0.1, 3.8), (0.35, 2.6), (-0.7, 4.9)):
        v.box((x - 0.32, y - 0.32, -0.95), (x + 0.32, y + 0.32, -0.4), (210, 55, 40))  # pepperoni
    two_eyes(v, 5.0, 0.5)
    v.decal(-0.35, 4.4, ["mm"], {"m": (110, 30, 30)})
    for sx in (-1, 1):
        v.cyl((sx * 0.35, 2.0, 0), (sx * 0.4, 0.3, 0), 0.32, (35, 85, 200))         # noob legs
        v.box((sx * 0.4 - 0.32, 0, -0.5), (sx * 0.4 + 0.32, 0.3, 0.3), (40, 160, 60))
        v.cyl((sx * 1.6, 6.2, 0), (sx * 2.2, 4.8, -0.3), 0.3, (255, 210, 60))       # yellow noob arms


@char("frigo")
def frigo(v):
    fridge, camel = (232, 238, 244), (205, 165, 105)
    v.rbox((-1.4, 2.2, -2.0), (1.4, 5.6, 2.4), 0.25, fridge)
    v.box((-1.45, 3.9, -2.05), (1.45, 4.0, 2.45), (180, 186, 194))                  # door split
    v.box((-1.5, 4.3, -1.9), (-1.42, 5.1, -1.6), (150, 150, 160))                   # handles
    v.box((-1.5, 2.6, -1.9), (-1.42, 3.5, -1.6), (150, 150, 160))
    v.ell((0, 6.2, 0.9), (1.0, 0.9, 1.2), camel)                                    # hump
    v.cyl((0, 5.2, -1.7), (0, 7.6, -2.6), 0.5, camel)                               # neck
    v.rbox((-0.6, 7.2, -4.0), (0.6, 8.2, -2.2), 0.3, camel)                         # head
    v.ell((0, 8.3, -2.6), (0.5, 0.25, 0.35), camel)
    for sx in (-1, 1):
        v.box((sx * 0.35 - 0.1, 7.75, -4.05), (sx * 0.35 + 0.1, 7.95, -3.95), DARK)
        for z in (-1.4, 1.8):
            v.cyl((sx * 1.0, 2.3, z), (sx * 1.0, 0.2, z), 0.3, camel)
            v.box((sx * 1.0 - 0.3, 0, z - 0.45), (sx * 1.0 + 0.3, 0.25, z + 0.3), (150, 115, 70))
    for y in (2.9, 4.6):
        v.box((-1.0, y, -2.05), (-0.8, y + 0.2, -2.0), (150, 200, 255))             # frost sparkle


@char("cocofanto")
def cocofanto(v):
    coco = v.speckle((115, 78, 45), (95, 62, 35), 0.4, seed=11)
    grey = (160, 160, 172)
    v.ball((0, 3.9, 0.5), 2.3, coco)                                                # coconut body
    for x in (-0.5, 0.5):
        v.ball((x, 6.0, -0.3), 0.3, (60, 38, 20))
    v.ball((0, 4.4, -1.8), 1.35, grey)                                              # elephant head
    for sx in (-1, 1):
        v.ell((sx * 1.6, 4.6, -1.4), (0.3, 1.2, 1.0), (145, 145, 158))
        v.cyl((sx * 0.55, 3.6, -2.7), (sx * 0.8, 3.2, -3.5), 0.15, WHITE, r1=0.08)  # tusks
        for z in (-0.6, 1.6):
            v.cyl((sx * 1.1, 2.0, z), (sx * 1.1, 0.2, z), 0.5, grey)
    v.cyl((0, 4.2, -2.9), (0, 1.8, -3.5), 0.45, grey, r1=0.3, caps=True)            # trunk
    two_eyes(v, 4.9, 0.55)


@char("la_vacca")
def la_vacca(v):
    planet = v.stripes(1, 0.55, (230, 200, 140), (210, 175, 115))
    v.ball((0, 3.2, 0), 2.3, planet)                                                # Saturn
    for a in range(120):
        t = a / 120 * 2 * math.pi
        for rad in (3.1, 3.5, 3.9):
            x, z = math.cos(t) * rad, math.sin(t) * rad
            y = 3.2 + z * 0.25
            v.box((x - 0.2, y - 0.18, z - 0.2), (x + 0.2, y + 0.18, z + 0.2), (200, 170, 235) if rad != 3.5 else (175, 145, 220))   # ring
    v.rbox((-1.1, 5.2, -1.5), (1.1, 6.9, 0.3), 0.35, WHITE)                         # cow head
    v.box((-1.15, 6.0, -1.55), (-0.4, 6.7, -1.0), BLACK); v.box((0.45, 5.4, -1.55), (1.0, 5.9, -1.0), BLACK)  # spots
    v.rbox((-0.8, 5.1, -1.9), (0.8, 5.7, -1.2), 0.2, (245, 170, 180))               # snout
    for sx in (-1, 1):
        v.box((sx * 0.35 - 0.08, 5.3, -1.95), (sx * 0.35 + 0.08, 5.5, -1.85), (150, 70, 80))
        v.cyl((sx * 0.9, 6.8, -0.6), (sx * 1.5, 7.6, -0.6), 0.15, (240, 230, 200))  # horns
        v.cyl((sx * 0.9, 1.2, -0.6), (sx * 0.9, 0.0, -0.6), 0.3, WHITE)
    two_eyes(v, 6.1, 0.45)


@char("odin_din")
def odin_din(v):
    skin, tunic = (240, 205, 175), v.stripes(1, 0.7, (60, 90, 165), (50, 75, 145))
    v.rbox((-1.6, 2.4, -0.9), (1.6, 6.2, 0.9), 0.3, tunic)
    v.box((-1.65, 2.7, -0.95), (1.65, 3.1, 0.95), (125, 80, 40))                    # belt
    v.box((-0.25, 2.7, -1.0), (0.25, 3.1, -0.95), (230, 190, 60))
    v.ball((0, 7.2, 0), 1.2, skin)
    v.rbox((-0.9, 5.6, -1.2), (0.9, 7.0, -0.3), 0.3, (232, 232, 238))               # beard
    v.cyl((0, 7.6, 0), (0, 8.5, 0), 1.3, (170, 172, 185), r1=1.1)                    # helmet
    for sx in (-1, 1):
        v.cyl((sx * 1.2, 8.0, 0), (sx * 2.0, 9.4, 0), 0.3, (245, 240, 225), r1=0.1)  # horns
        v.cyl((sx * 1.7, 5.8, 0), (sx * 2.4, 3.6, 0), 0.5, skin)                     # big arms
        v.cyl((sx * 0.8, 2.6, 0), (sx * 0.8, 0.3, 0), 0.55, (75, 60, 50))
        v.box((sx * 0.8 - 0.55, 0, -0.8), (sx * 0.8 + 0.55, 0.4, 0.5), (60, 45, 35))
    two_eyes(v, 7.4, 0.45, rows=("b", "b"))
    v.box((-0.8, 7.75, -1.25), (-0.15, 7.9, -1.1), DARK); v.box((0.15, 7.75, -1.25), (0.8, 7.9, -1.1), DARK)  # angry brows
    v.cyl((2.6, 0.2, -0.4), (2.6, 8.8, -0.4), 0.15, (150, 110, 60))                 # spear
    v.cyl((2.6, 8.8, -0.4), (2.6, 9.8, -0.4), 0.35, (210, 210, 220), r1=0.05)


@char("trippi")
def trippi(v):
    shrimp = v.stripes(2, 0.5, (255, 145, 115), (240, 120, 95))
    pts = [(0, 2.4, -0.2), (0, 2.6, 1.0), (0, 3.0, 2.1), (0, 3.6, 3.0), (0, 4.3, 3.5)]
    for i in range(len(pts) - 1):
        v.cyl(pts[i], pts[i + 1], 1.2 - i * 0.22, shrimp, caps=True)                 # curled shrimp body
    v.ell((0, 4.8, 3.9), (1.0, 0.25, 0.7), (240, 120, 95))                          # tail fan
    v.ball((0, 4.0, -1.2), 1.4, (240, 180, 120))                                    # cat head
    for sx in (-1, 1):
        v.cyl((sx * 0.8, 5.0, -1.2), (sx * 1.0, 5.9, -1.2), 0.4, (240, 180, 120), r1=0.05)  # ears
        for y in (3.7, 3.9):
            v.box((sx * 0.6, y, -2.55), (sx * 1.6, y + 0.06, -2.5), DARK)            # whiskers
        for z in (0.0, 1.0, 2.0):
            v.cyl((sx * 0.6, 2.0, z), (sx * 0.9, 0.0, z - 0.2), 0.12, (240, 120, 95))   # shrimp legs
    two_eyes(v, 4.2, 0.5, rows=("gb", "gg"), cols={"g": (110, 200, 90), "b": DARK})
    v.box((-0.15, 3.65, -2.65), (0.15, 3.85, -2.5), (240, 150, 170))


@char("fluri")
def fluri(v):
    v.cyl((0, 0, 0), (0, 3.2, 0), 0.3, (70, 160, 60))
    v.ell((-0.7, 1.4, 0), (0.7, 0.18, 0.4), (80, 175, 65)); v.ell((0.7, 2.1, 0), (0.7, 0.18, 0.4), (80, 175, 65))
    for a in range(6):
        t = a * math.pi / 3
        v.ell((math.cos(t) * 1.35, 4.6 + math.sin(t) * 1.35, 0.15), (0.75, 0.75, 0.3), v.stripes(1, 0.35, (255, 140, 200), (245, 120, 185)))
    v.ell((0, 4.6, -0.1), (1.0, 1.0, 0.45), (255, 215, 70))
    two_eyes(v, 4.7, 0.4)
    v.decal(-0.35, 4.1, ["mm"], {"m": (130, 40, 40)})


@char("talpa")
def talpa(v):
    iron = v.speckle((125, 130, 140), (105, 110, 120), 0.35, seed=14)
    v.ell((0, 2.2, 0.3), (1.8, 1.8, 2.0), iron)
    v.ball((0, 3.0, -1.3), 1.3, iron)
    v.cyl((0, 3.1, -2.4), (0, 3.1, -4.2), 0.6, v.stripes(2, 0.35, (230, 200, 90), (200, 170, 70)), r1=0.08)  # drill nose
    v.box((-1.1, 3.8, -2.6), (1.1, 4.2, -2.2), DARK)                                # goggles strap
    for sx in (-1, 1):
        v.rbox((sx * 0.5 - 0.35, 3.65, -2.75), (sx * 0.5 + 0.35, 4.35, -2.4), 0.15, (120, 200, 255))
        v.rbox((sx * 1.1 - 0.5, 0, -1.3), (sx * 1.1 + 0.5, 0.5, 0.3), 0.15, (90, 92, 98))   # claws
        for dx in (-0.3, 0.0, 0.3):
            v.box((sx * 1.1 + dx - 0.08, 0.05, -1.7), (sx * 1.1 + dx + 0.08, 0.3, -1.3), (235, 235, 235))


@char("svinina")
def svinina(v):
    pig = (255, 170, 182)
    v.ell((0, 3.0, 0.3), (1.8, 1.7, 2.0), pig)
    v.cyl((0, 3.0, -1.6), (0, 3.0, -2.1), 0.55, (240, 135, 155))                    # snout
    for sx in (-1, 1):
        v.box((sx * 0.2 - 0.08, 2.85, -2.15), (sx * 0.2 + 0.08, 3.15, -2.05), (150, 60, 80))
        v.cyl((sx * 1.0, 4.4, -0.4), (sx * 1.3, 5.0, -0.6), 0.35, pig, r1=0.05)     # ears
        v.ell((sx * 2.3, 3.6, 0.3), (1.3, 0.15, 0.6), (205, 210, 220))              # wings
        for z in (-0.6, 1.2):
            v.cyl((sx * 0.8, 1.5, z), (sx * 0.8, 0.0, z), 0.3, pig)
    two_eyes(v, 3.65, 0.6)
    v.ball((0, 5.0, 0.8), 0.8, (45, 45, 50))                                        # bomb on back
    v.cyl((0, 5.7, 0.8), (0, 6.3, 0.8), 0.1, (200, 160, 80)); v.ball((0, 6.35, 0.8), 0.15, (255, 170, 40))


@char("pipi_kiwi")
def pipi_kiwi(v):
    feathers = v.speckle((140, 100, 55), (120, 85, 45), 0.4, seed=17)
    v.ell((0, 2.5, 0.4), (1.6, 1.5, 1.9), feathers)
    v.ball((0, 3.5, -1.1), 1.0, feathers)
    v.cyl((0, 3.3, -1.9), (0, 2.4, -4.0), 0.2, (230, 200, 150), r1=0.1)             # long beak
    two_eyes(v, 3.75, 0.45, rows=("b",))
    for sx in (-1, 1):
        v.cyl((sx * 0.5, 1.1, 0.2), (sx * 0.5, 0.15, 0.2), 0.15, (230, 190, 120))
        v.box((sx * 0.5 - 0.3, 0, -0.5), (sx * 0.5 + 0.3, 0.15, 0.3), (230, 190, 120))
    v.ball((1.8, 2.4, 0.0), 0.7, v.speckle((110, 180, 60), (90, 150, 45), 0.4, seed=18))   # kiwi fruit


@char("gangster")
def gangster(v):
    foot = (240, 200, 172)
    v.rbox((-1.4, 0, -2.6), (1.4, 2.0, 1.6), 0.6, foot)                             # foot
    v.rbox((-1.3, 1.5, 0.0), (1.3, 5.0, 1.8), 0.5, foot)                            # ankle/leg
    for i, (x, r) in enumerate(((-0.95, 0.42), (-0.4, 0.38), (0.1, 0.36), (0.55, 0.33), (0.95, 0.3))):
        v.ball((x, 1.3, -2.6), r, foot)                                             # toes
        v.box((x - 0.15, 1.45, -3.0), (x + 0.15, 1.6, -2.85), (250, 225, 210))      # nails
    v.box((-1.0, 3.6, -0.05), (1.0, 4.0, 0.05), BLACK)                              # shades
    v.box((-1.0, 3.5, -0.1), (-0.15, 4.0, 0.0), BLACK); v.box((0.15, 3.5, -0.1), (1.0, 4.0, 0.0), BLACK)
    v.cyl((0, 5.0, 0.9), (0, 5.2, 0.9), 1.6, (30, 30, 30))                          # fedora brim
    v.cyl((0, 5.2, 0.9), (0, 6.2, 0.9), 1.1, (30, 30, 30))
    v.cyl((0, 5.25, 0.9), (0, 5.5, 0.9), 1.12, (200, 30, 30))
    for a in range(14):
        t = a / 14 * math.pi
        v.ball((math.cos(t) * 1.3, 2.4 - math.sin(t) * 0.6, 0.0 - math.sin(t) * 0.1), 0.17, (255, 210, 40))   # gold chain


@char("orangutini")
def orangutini(v):
    pine = v.stripes(1, 0.45, (245, 195, 60), (215, 160, 45))
    fur = (210, 110, 40)
    v.cyl((0, 0.8, 0), (0, 4.8, 0), 1.7, pine, caps=True)                            # pineapple body
    for a in range(7):
        t = a / 7 * 2 * math.pi
        v.cyl((0, 5.4, 0), (math.cos(t) * 0.9, 7.2, math.sin(t) * 0.9), 0.22, (60, 150, 60), r1=0.05)  # leaves
    v.ball((0, 3.6, -1.3), 1.15, fur)                                               # orangutan face
    v.ell((0, 3.3, -2.05), (0.75, 0.55, 0.4), (240, 190, 150))
    for sx in (-1, 1):
        v.cyl((sx * 1.6, 3.8, -0.3), (sx * 2.4, 1.8, -0.9), 0.38, fur)
        v.cyl((sx * 0.7, 1.0, 0), (sx * 0.7, 0.0, 0), 0.4, fur)
    two_eyes(v, 3.85, 0.45)
    v.decal(-0.35, 3.0, ["mm"], {"m": (110, 50, 30)})


@char("skibidi")
def skibidi(v):
    porcelain = (246, 249, 252)
    v.cyl((0, 0, 0.3), (0, 1.6, 0.3), 0.9, porcelain, r1=1.1)                       # base
    v.cyl((0, 1.6, 0), (0, 3.2, 0), 1.7, porcelain)                                 # bowl
    v.cyl((0, 3.0, 0), (0, 3.3, 0), 1.75, (210, 215, 222))                          # seat
    v.rbox((-1.5, 2.8, 1.2), (1.5, 6.2, 2.3), 0.25, porcelain)                      # tank
    v.box((0.6, 5.6, 1.15), (1.1, 5.8, 1.2), (180, 185, 192))                       # flush handle
    v.ball((0, 4.3, -0.2), 1.25, (235, 195, 165))                                   # head
    v.ell((0, 5.2, 0.0), (1.1, 0.5, 1.1), (90, 60, 35))                             # hair
    two_eyes(v, 4.55, 0.5, rows=("wb", "ww"), cols={"w": WHITE, "b": DARK})
    v.decal(-0.525, 3.65, ["rrr", "rtr"], {"r": (140, 30, 40), "t": WHITE})


@char("garama")
def garama(v):
    suit = v.stripes(1, 0.6, (140, 60, 25), (120, 50, 20))
    v.rbox((-2.0, 1.6, -1.0), (2.0, 4.4, 1.0), 0.4, suit)
    for sx, skin, hat in ((-1, (225, 175, 125), (60, 30, 20)), (1, (200, 140, 100), (200, 30, 30))):
        v.ball((sx * 1.05, 5.4, 0), 1.0, skin)
        v.cyl((sx * 1.05, 6.1, 0), (sx * 1.05, 6.7, 0), 0.85, hat)
        v.cyl((sx * 1.05, 6.05, 0), (sx * 1.05, 6.2, 0), 1.15, hat)
        for ex in (-0.35, 0.35):
            v.decal(sx * 1.05 + ex - 0.175, 5.5, ["b"], {"b": DARK})
        v.decal(sx * 1.05 - 0.35, 4.95, ["mm"], {"m": (110, 40, 40)})
        v.cyl((sx * 1.0, 1.7, 0), (sx * 1.0, 0.2, 0), 0.45, (60, 60, 70))
        v.box((sx * 1.0 - 0.45, 0, -0.7), (sx * 1.0 + 0.45, 0.3, 0.4), (30, 30, 30))
    v.ball((2.5, 2.3, -0.8), 1.0, (220, 190, 120))                                  # money bag
    v.box((2.2, 2.0, -1.85), (2.8, 2.6, -1.7), (40, 150, 60))
    v.cyl((2.5, 3.2, -0.8), (2.5, 3.5, -0.8), 0.3, (180, 150, 90))
