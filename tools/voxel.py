"""Tiny voxel modeller for Steal-a-Brainrot style characters.

Shapes are filled into a grid of `res`-stud cubes, later shapes paint over earlier ones, and
greedy meshing merges same-coloured neighbours into as few Roblox parts as possible.
Coordinates are studs: y up, feet on y = 0, the character faces -Z.
"""
import numpy as np


class Vox:
    def __init__(self, res=0.35, lo=(-6, 0, -9), hi=(6, 13, 9)):
        self.res = res
        self.lo = np.array(lo, float)
        n = np.ceil((np.array(hi, float) - self.lo) / res).astype(int)
        self.grid = np.zeros(n, np.int16)
        self.palette = [None]
        ax = [self.lo[i] + (np.arange(n[i]) + 0.5) * res for i in range(3)]
        self.X, self.Y, self.Z = np.meshgrid(ax[0], ax[1], ax[2], indexing="ij")

    # ------------------------------------------------------------ colours
    def pal(self, rgb):
        rgb = tuple(int(c) for c in rgb)
        if rgb not in self.palette:
            self.palette.append(rgb)
        return self.palette.index(rgb)

    def _paint(self, mask, col):
        if col is None:
            self.grid[mask] = 0
        elif callable(col):
            idx = col(self, mask)
            self.grid[mask] = idx[mask]
        else:
            self.grid[mask] = self.pal(col)

    # ------------------------------------------------------------ shapes
    def ell(self, c, r, col):
        m = ((self.X - c[0]) / r[0]) ** 2 + ((self.Y - c[1]) / r[1]) ** 2 + ((self.Z - c[2]) / r[2]) ** 2 <= 1
        self._paint(m, col)
        return m

    def ball(self, c, r, col):
        return self.ell(c, (r, r, r), col)

    def box(self, a, b, col):
        a, b = np.minimum(a, b), np.maximum(a, b)
        m = (self.X >= a[0]) & (self.X <= b[0]) & (self.Y >= a[1]) & (self.Y <= b[1]) & (self.Z >= a[2]) & (self.Z <= b[2])
        self._paint(m, col)
        return m

    def rbox(self, a, b, r, col):
        """Box with rounded edges (radius r)."""
        a, b = np.array(np.minimum(a, b), float), np.array(np.maximum(a, b), float)
        q = np.stack([np.maximum(np.maximum(a[i] + r - P, P - (b[i] - r)), 0) for i, P in enumerate((self.X, self.Y, self.Z))])
        m = (np.sqrt((q ** 2).sum(0)) <= r) & (self.X >= a[0]) & (self.X <= b[0]) & (self.Y >= a[1]) & (self.Y <= b[1]) & (self.Z >= a[2]) & (self.Z <= b[2])
        self._paint(m, col)
        return m

    def cyl(self, p0, p1, r, col, r1=None, caps=False):
        """Cylinder / cone (r -> r1) from p0 to p1; caps=True makes a capsule."""
        p0, p1 = np.array(p0, float), np.array(p1, float)
        d = p1 - p0
        L2 = d @ d
        t = ((self.X - p0[0]) * d[0] + (self.Y - p0[1]) * d[1] + (self.Z - p0[2]) * d[2]) / L2
        tc = np.clip(t, 0, 1)
        px, py, pz = p0[0] + d[0] * tc, p0[1] + d[1] * tc, p0[2] + d[2] * tc
        dist = np.sqrt((self.X - px) ** 2 + (self.Y - py) ** 2 + (self.Z - pz) ** 2)
        rr = r + ((r1 if r1 is not None else r) - r) * tc
        m = dist <= rr
        if not caps:
            m &= (t >= 0) & (t <= 1)
        self._paint(m, col)
        return m

    def carve(self, mask):
        self.grid[mask] = 0

    # ------------------------------------------------------------ colour patterns
    def stripes(self, axis, period, c1, c2, offset=0.0):
        a, b = self.pal(c1), self.pal(c2)
        coord = (self.X, self.Y, self.Z)[axis]

        def f(v, mask):
            return np.where(((coord - offset) // period) % 2 == 0, a, b).astype(np.int16)
        return f

    def gradient(self, axis, lo, hi, c1, c2, steps=4):
        cols = [self.pal(tuple(c1[i] + (c2[i] - c1[i]) * s / (steps - 1) for i in range(3))) for s in range(steps)]
        coord = (self.X, self.Y, self.Z)[axis]

        def f(v, mask):
            t = np.clip((coord - lo) / (hi - lo), 0, 0.999)
            return np.array(cols, np.int16)[(t * steps).astype(int)]
        return f

    def speckle(self, c1, c2, chance=0.25, seed=1, block=2):
        """Patchy two-tone texture in block x block voxel tiles (keeps part counts down)."""
        a, b = self.pal(c1), self.pal(c2)
        rng = np.random.default_rng(seed)
        n = self.grid.shape
        tiles = rng.random(tuple(s // block + 1 for s in n)) < chance
        ii, jj, kk = np.indices(n)
        pick = tiles[ii // block, jj // block, kk // block]

        def f(v, mask):
            return np.where(pick, b, a).astype(np.int16)
        return f

    # ------------------------------------------------------------ face helpers (front = -Z)
    def front_z(self, x, y):
        """Z of the front-most filled voxel at (x, y), or None."""
        i = int((x - self.lo[0]) / self.res)
        j = int((y - self.lo[1]) / self.res)
        col = np.nonzero(self.grid[i, j, :])[0]
        if len(col) == 0:
            return None
        return self.lo[2] + col[0] * self.res

    def decal(self, x0, y0, rows, colors, depth=1, z=None, pixel=None):
        """Pixel art stamped onto the front surface. rows: list of strings (top row first), '.' = skip."""
        px = pixel or self.res
        h = len(rows)
        for r, line in enumerate(rows):
            for c, ch in enumerate(line):
                if ch == "." or ch == " ":
                    continue
                x = x0 + (c + 0.5) * px
                y = y0 + (h - r - 0.5) * px
                fz = z if z is not None else self.front_z(x, y)
                if fz is None:
                    continue
                self.box((x - px / 2 + 0.01, y - px / 2 + 0.01, fz - self.res * (depth - 1) - 0.01 - (0 if z is None else 0)),
                         (x + px / 2 - 0.01, y + px / 2 - 0.01, fz + self.res * 0.99), colors[ch])

    # ------------------------------------------------------------ export
    def boxes(self):
        """Greedy-merge the grid into boxes: list of (i, j, k, si, sj, sk, palette_index)."""
        g = self.grid.copy()
        nx, ny, nz = g.shape
        out = []
        # Hide fully enclosed voxels by letting them merge with anything: mark interior as wildcard (-1).
        filled = g > 0
        interior = filled.copy()
        interior[1:-1, 1:-1, 1:-1] &= (filled[:-2, 1:-1, 1:-1] & filled[2:, 1:-1, 1:-1] & filled[1:-1, :-2, 1:-1]
                                      & filled[1:-1, 2:, 1:-1] & filled[1:-1, 1:-1, :-2] & filled[1:-1, 1:-1, 2:])
        interior[0, :, :] = interior[-1, :, :] = False
        interior[:, 0, :] = interior[:, -1, :] = False
        interior[:, :, 0] = interior[:, :, -1] = False
        g[interior] = -1
        done = np.zeros_like(filled)
        for j in range(ny):
            for k in range(nz):
                for i in range(nx):
                    c = g[i, j, k]
                    if c <= 0 or done[i, j, k]:
                        continue

                    def ok(sl):
                        sub = g[sl]
                        return ((sub == c) | (sub == -1)).all() and not done[sl].any()
                    si = 1
                    while i + si < nx and ok((slice(i + si, i + si + 1), slice(j, j + 1), slice(k, k + 1))):
                        si += 1
                    sk = 1
                    while k + sk < nz and ok((slice(i, i + si), slice(j, j + 1), slice(k + sk, k + sk + 1))):
                        sk += 1
                    sj = 1
                    while j + sj < ny and ok((slice(i, i + si), slice(j + sj, j + sj + 1), slice(k, k + sk))):
                        sj += 1
                    done[i:i + si, j:j + sj, k:k + sk] = True
                    out.append((i, j, k, si, sj, sk, int(c)))
        return out

    def bounds_of_fill(self):
        idx = np.argwhere(self.grid > 0)
        return idx.min(0), idx.max(0) + 1
