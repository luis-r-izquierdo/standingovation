;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GNU GENERAL PUBLIC LICENSE ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; StandingOvation
;; StandingOvation is an agent-based model described by
;; Miller and Page in their paper:
;; Miller, J. H. and S. E. Page (2004). "The standing ovation problem" Complexity 9(5): 8-16.
;;
;; Copyright (C) 2008 Luis R. Izquierdo, Segismundo S. Izquierdo,
;; Jose M. Galan & Jose I. Santos
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
;;
;; Contact information:
;; Luis R. Izquierdo
;;   University of Burgos, Spain.
;;   e-mail: luis@izquierdo.name


;;;;;;;;;;;;;;;;;
;;; VARIABLES ;;;
;;;;;;;;;;;;;;;;;

turtles-own [
  my-neighbours
  n-of-neighbours
  feeling-awkward?
  standing?
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP PROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to startup
  clear-all
  setup-turtles
  reset-ticks
end

to setup-turtles
  set-default-shape turtles "person"
  ask patches [sprout 1 [
    set feeling-awkward? false
    set standing? false
    hide-turtle
    ]
  ]
  ask turtles [setup-neighbourhood]
end

to set-random-initial-conditions
  clear-all-plots
  reset-ticks

  ask turtles [
    set standing? false
    hide-turtle
    if random-float 1.0 < intrinsic-prob-standing [
      set standing? true
    ]
  ]
  ask turtles [revise-feelings]
  do-graphs
end

to set-cyclic-cond-1
  startup

  set cone-length 1
  ask turtles [setup-neighbourhood]
  set updating "sync"
  set noise 0

  let rd-row random-pycor
  let n-of-cycling-rows (max-pycor - rd-row + 1)

  (foreach (n-values n-of-cycling-rows [max-pycor - ?]) (n-values n-of-cycling-rows [random 2])
    [ask turtles with [(pycor = ?1) and (pxcor mod 2 = ?2)] [set standing? true]])

  ifelse random 2 = 0
    [ask turtles with [pycor < rd-row] [set standing? true]]
    [ask turtles with [pycor < rd-row] [set standing? false]]

  ask turtles [revise-feelings]
  do-graphs
end

to set-cyclic-cond-2
  startup

  set cone-length world-height
  ask turtles [setup-neighbourhood]
  set updating "sync"
  set noise 0

  let n-of-pairs-of-rows-available int ((world-height - 1) / 2)
    ;; now select an odd number of pairs randomly
  let n-of-pairs-of-cycling-rows (2 * random int ((n-of-pairs-of-rows-available + 1) / 2)) + 1
  let my-rd-list reduce [sentence ?1 ?2] (map [list ? ? ] (n-values n-of-pairs-of-cycling-rows [? mod 2]))
  let cycling-rows n-values (2 * n-of-pairs-of-cycling-rows) [max-pycor - ?]

  (foreach cycling-rows my-rd-list
    [ask turtles with [(pycor = ?1) and (pxcor mod 2 = ?2)] [set standing? true]])

  let last-cycling-row (last cycling-rows)

  ifelse random 2 = 0
    [ask turtles with [pycor < last-cycling-row] [set standing? true]]
    [ask turtles with [pycor < last-cycling-row] [set standing? false]]

  ask turtles [revise-feelings]
  do-graphs
end

to make-guy-stand
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      ask turtles-here [
          set standing? true
          show-turtle
      ]
    ]
  ]
  ask turtles [revise-feelings]
  display
end

to make-guy-sit
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      ask turtles-here [
          set standing? false
          hide-turtle
      ]
    ]
  ]
  ask turtles [revise-feelings]
  display
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TURTLES' PROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-neighbourhood
  set my-neighbours turtles-on (neighbors with [pycor >= [pycor] of myself])
  if cone-length > 1 [
    set my-neighbours (turtle-set my-neighbours
      other turtles with [
       (ycor - [ycor] of myself  >= xcor - [xcor] of myself)
        and
       (ycor - [ycor] of myself  >= [xcor] of myself - xcor)
       and
       (ycor <= [ycor] of myself + cone-length)
      ]
    )
  ]
  set n-of-neighbours count my-neighbours
end

to revise-feelings
  let standing-nbrs count (my-neighbours with [standing?])

  if (standing-nbrs > (n-of-neighbours / 2)) [
    ifelse standing?
      [set feeling-awkward? false]
      [set feeling-awkward? true]
    stop
  ]
  if (standing-nbrs < (n-of-neighbours / 2)) [
    ifelse standing?
      [set feeling-awkward? true]
      [set feeling-awkward? false]
    stop
  ]
  if standing-nbrs = (n-of-neighbours / 2) [
    set feeling-awkward? "indifferent"
  ]
end

to act
  ifelse feeling-awkward? = true
  [
    set standing? (not standing?)
  ]
  [
    if feeling-awkward? = "indifferent" [
      ifelse (random 2) = 0
        [set standing? true]
        [set standing? false]
    ]
  ]
  if random-float 1.0 < noise [
    set standing? (not standing?)
  ]
end

;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN PROCEDURE ;;;
;;;;;;;;;;;;;;;;;;;;;;

to go

  if-else updating = "async-rd"
    [ask turtles [revise-feelings act]]
      ;; ask is serial, i.e. the agents run the commands inside the ask one agent at a time
      ;; Every time you ask an agentset (e.g. turtles), agents are selected at random.
    [ ;; updating = "sync"
      ask turtles [revise-feelings]
      ask turtles [act]
    ]

  tick

  ask turtles [revise-feelings]
    ;; this does not affect the simulation because every turtle
    ;; revises her feelings before being given the opportunity to
    ;; act
  do-graphs
  if (all? turtles [feeling-awkward? = false]) and (noise = 0) [stop]
end

;;;;;;;;;;;;;;
;;; GRAPHS ;;;
;;;;;;;;;;;;;;

to do-graphs
  ask turtles with [standing?] [show-turtle]
  ask turtles with [not standing?] [hide-turtle]
  do-plots
end

to do-plots
  set-current-plot "People"
  set-current-plot-pen "standing"
  plotxy ticks count turtles with [standing?]
  set-current-plot-pen "awkward"
  plotxy ticks count turtles with [feeling-awkward? = true]
end

to show-vision
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
       ask turtles-here [
         ask my-neighbours [set pcolor [color] of myself]
       ]
    ]
  ]
  display
end
@#$#@#$#@
GRAPHICS-WINDOW
211
10
541
361
-1
-1
16.0
1
10
1
1
1
0
0
0
1
0
19
0
19
1
1
1
ticks
30.0

BUTTON
7
243
190
276
Random initial cond
set-random-initial-conditions
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
7
278
190
311
intrinsic-prob-standing
intrinsic-prob-standing
0
1
0.5
0.01
1
NIL
HORIZONTAL

BUTTON
545
235
728
268
Make guy stand up
with-local-randomness [make-guy-stand]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
9
94
147
139
updating
updating
"async-rd" "sync"
0

BUTTON
652
165
730
198
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
9
11
159
29
Neighbourhood
12
0.0
1

TEXTBOX
9
223
159
241
Initial conditions
12
0.0
1

TEXTBOX
10
75
160
93
Updating
12
0.0
1

PLOT
545
10
787
160
People
time
#people
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"standing" 1.0 0 -16777216 true "" ""
"awkward" 1.0 0 -2674135 true "" ""

BUTTON
545
328
693
361
Show guy's vision
with-local-randomness [show-vision]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
699
328
763
361
clear
with-local-randomness [\n  ask patches [set pcolor black]\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
137
34
195
67
apply
with-local-randomness [\n  ask turtles [setup-neighbourhood]\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
545
165
639
198
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
545
270
728
303
Make guy sit down
with-local-randomness [make-guy-sit]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
8
33
130
66
cone-length
cone-length
1
20
1
1
1
NIL
HORIZONTAL

SLIDER
9
170
162
203
noise
noise
0
1
0
0.01
1
NIL
HORIZONTAL

TEXTBOX
12
149
55
167
Noise
12
0.0
1

BUTTON
8
328
107
361
Cycles 2 st
set-cyclic-cond-1
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
110
328
209
361
Cycles +2 st
set-cyclic-cond-2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
