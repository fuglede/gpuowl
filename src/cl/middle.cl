// Copyright (C) Mihai Preda

// Normal values: 64, 256
#if !IN_WG
#define IN_WG 256
#endif

// Normal values: 64, 256
#if !OUT_WG
#define OUT_WG 256
#endif

// Normal values: 4, 8, 16, 32
#if !IN_SIZEX
#if AMDGPU
#define IN_SIZEX 32
#else // !AMDGPU
#if G_W >= 64
#define IN_SIZEX 4
#else
#define IN_SIZEX 32
#endif
#endif
#endif

// Normal values: 4, 8, 16, 32
#if !OUT_SIZEX
#if AMDGPU
#define OUT_SIZEX 32
#else // AMDGPU
#if G_W >= 64
#define OUT_SIZEX 4
#else
#define OUT_SIZEX 32
#endif
#endif
#endif

// Normal values: 1, 2, 4, 8
#if !OUT_SPACING
#if AMDGPU
#define OUT_SPACING 8
#else
#define OUT_SPACING 1
#endif
#endif

// Read a line for tailFused or fftHin
// This reads partially transposed datat as written by fftMiddleIn
void readTailFusedLine(CP(T2) in, T2 *u, u32 line) {
  // We go to some length here to avoid dividing by MIDDLE in address calculations.
  // The transPos converted logical line number into physical memory line numbers
  // using this formula:  memline = line / WIDTH + line % WIDTH * MIDDLE.
  // We can compute the 0..9 component of address calculations as line / WIDTH,
  // and the 0,10,20,30,..310 component as (line % WIDTH) % 32 = (line % 32),
  // and the multiple of 320 component as (line % WIDTH) / 32

  u32 me = get_local_id(0);
  u32 SIZEY = IN_WG / IN_SIZEX;

  in += line / WIDTH * IN_WG;
  in += line % IN_SIZEX * SIZEY;
  in += line % WIDTH / IN_SIZEX * (SMALL_HEIGHT / SIZEY) * MIDDLE * IN_WG;

  in += me / SIZEY * MIDDLE * IN_WG + me % SIZEY;
  for (i32 i = 0; i < NH; ++i) { u[i] = in[i * G_H / SIZEY * MIDDLE * IN_WG]; }
}


// Read a line for carryFused or FFTW
void readCarryFusedLine(CP(T2) in, T2 *u, u32 line) {
  u32 me = get_local_id(0);
  u32 WG = OUT_WG * OUT_SPACING;
  u32 SIZEY = WG / OUT_SIZEX;

  in += line % OUT_SIZEX * SIZEY
        + line % SMALL_HEIGHT / OUT_SIZEX * WIDTH / SIZEY * MIDDLE * WG
        + line / SMALL_HEIGHT * WG;

  in += me / SIZEY * MIDDLE * WG + me % SIZEY;

  for (i32 i = 0; i < NW; ++i) { u[i] = in[i * G_W / SIZEY * MIDDLE * WG]; }
}
