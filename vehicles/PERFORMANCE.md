# R34-inspired arcade performance

The S64 visual remains a fictional compact. This tune approximates R34 GT-R performance; it does not simulate ATTESA, a gearbox or individual tires.

[Nissan's BNR34 V-spec II specifications](https://www.nissan-global.com/EN/HERITAGE_COLLECTION/280_skyline_gt-r_v-spec_ii.html) list 1,560kg, 206kW/280PS and 392Nm. [Evo's stock R34 review](https://www.evo.co.uk/nissan/skyline/gt-r-r34) provides additional context. The game omits the Japanese-market 180km/h limiter. Its 155 MPH ceiling is an authored derestricted gameplay target, not a claim about every stock-market variant.

Stock tune: 69.3m/s top speed, 7m/s² launch acceleration, power taper a(v)=7/(1+(v/27)²), and 10.5m/s² braking. Steering uses a fixed speed reference and a cornering-acceleration cap, so raising the engine speed ceiling does not sharpen steering at the same speed. Handbrake sliding remains arcade-based.

Measured on a flat surface at 60 physics steps per second:

| Engine tier | Balanced 0–60 / top | Launch brand 0–60 / top | Speed brand 0–60 / top |
|---|---|---|---|
| Stock | 5.10s / 155 MPH | Same | Same |
| 1 | 4.25s / 167 MPH | 4.10s / 165 MPH | 4.42s / 170 MPH |
| 2 | 3.45s / 183 MPH | 3.25s / 178 MPH | 3.65s / 188 MPH |
| 3 | 2.80s / 202 MPH | 2.63s / 195 MPH | 3.00s / 209 MPH |

Stock 0–100 MPH: 12.22s. Reaches within 0.1m/s of its speed ceiling in 31.52s. Stock 60–0: 34.04m, approximately 112ft.

Upgrade measurements use matching tire/brake tiers and brands. These are game balance figures, not real tuning-package guarantees. Balanced brake gains are 10/20/30%; tire grip gains 8/16/24%, with small same-tier brand tradeoffs. Saved selections remain compatible and do not stack multipliers.

`tests/verify_r34_performance.gd` checks stock timing/speed/stopping distance, all nine upgrade combinations, tier progression, high-speed steering and stock restoration.
