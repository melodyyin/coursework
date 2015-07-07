globals [ total-proposals total-rejections ] 
turtles-own [ gender attractiveness self-perceived-attractiveness interests similarity-to personality tolerance change-attempts change-tendency strategy commitment proposals rejections engaged? idle? idle-tick wait?]

;; setup tasks -------
to setup
  ca
  reset-ticks
  set-default-shape turtles "person" 
  crt population-count
  ask turtles 
  [ 
    set-gender
    set-attractiveness
    set-interests
    set-personality
    set-tolerance ; max difference turtle is willing to tolerate
    set-strategy-commitment
    set-change-tendencies
    set change-attempts 0
    set proposals 0 
    set rejections 0
    set engaged? false
    set idle? false
    set wait? false
  ]
  set-wait
  set-positions
end

to set-positions
  if start-pos = "sides"
  [
    ask turtles with [ gender = "male" ]
    [
      set xcor min-pxcor + 2
      set ycor random-ycor
    ]
    ask turtles with [ gender = "female" ] 
    [
      set xcor max-pxcor - 2
      set ycor random-ycor 
    ]
  ]
  if start-pos = "random"
  [
    ask turtles
    [
      set xcor random-xcor 
      set ycor random-ycor
    ]
  ]
  if start-pos = "clusters"
  [
    ask turtles
    [
      set xcor random-xcor 
      set ycor random-ycor 

      if xcor >= 0 and ycor >= 0
      [
        set gender "female" 
        set color pink
      ]
      if xcor < 0 and ycor >= 0
      [
        set gender "male" 
        set color blue
      ]
      if xcor >= 0 and ycor < 0
      [
        set gender "male"
        set color blue
      ]
      if xcor < 0 and ycor < 0 
      [
        set gender "female"
        set color pink
      ]
    ]
  ]
  if start-pos = "similar interests"
  [
    ask turtles 
    [
      set xcor random-xcor
      set ycor random-ycor
      
      if xcor >= 0 and ycor >= 0
      [
        let base [0 0 0 0 0 0 0 0 0 0]
        mutate-interests base
      ]
      if xcor < 0 and ycor >= 0
      [
        let base [1 0 1 0 1 0 1 0 1 0]
        mutate-interests base
      ]
      if xcor >= 0 and ycor < 0
      [
        let base [1 1 1 1 1 1 1 1 1 1]
        mutate-interests base
      ]
      if xcor >= 0 and ycor < 0 
      [
        let base [0 1 0 1 0 1 0 1 0 1]
        mutate-interests base
      ]
    ]
  ]
  if start-pos = "similar appearance"
  [
    ask turtles 
    [
      set xcor random-xcor
      set ycor random-ycor
      
      if xcor >= 0 and ycor >= 0
      [
        let base 1
        mutate-appearance base
      ]
      if xcor < 0 and ycor >= 0 
      [
        let base 4 
        mutate-appearance base
      ]
      if xcor >= 0 and ycor < 0
      [
        let base 7
        mutate-appearance base
      ]
      if xcor >= 0 and ycor < 0
      [
        let base 10
        mutate-appearance base
      ]
    ]
  ]
  if start-pos = "similar tolerance"
  [
    ask turtles
    [
      set xcor random-xcor 
      set ycor random-ycor 
      
      if xcor >= 0 and ycor >= 0
      [
        let base 0.1
        mutate-tolerance base
      ]
      if xcor < 0 and ycor >= 0
      [
        let base 0.4 
        mutate-tolerance base
      ]
      if xcor >= 0 and ycor < 0
      [
        let base 0.7
        mutate-tolerance base
      ]
      if xcor >= 0 and ycor < 0
      [
        let base 1
        mutate-tolerance base
      ]
    ]
  ]           
end

to mutate-interests[base]
  let tmp random 5 ; how many to change
  while [ tmp > 0 ]
  [
    set tmp (tmp - 1)
    set base replace-item random 10 base random 2
  ]
  set interests base
end

to mutate-appearance[base]
  let tmp random 3
  ifelse random 2 = 0 [ set attractiveness base - tmp ]
  [ set attractiveness base + tmp ]
end

to mutate-tolerance[base]
  let tmp random-float 0.3
  ifelse random 2 = 0 [ set tolerance base - tmp ]
  [ set tolerance base + tmp ]
end

to set-gender
  ifelse who <= pct-males * population-count 
  [
    set gender "male"
    set color blue
  ]
  [ 
    set gender "female"
    set color pink
  ]
end

to set-attractiveness
  set attractiveness random 10 + 1 
  ; perceive self as +/- 3 from actual attractiveness
  set self-perceived-attractiveness attractiveness + random 7 - 3
end

to set-interests
  let tmp 10 
  set interests []
  
  while [ tmp > 0 ]
  [
    set interests fput (random 2) interests
    set tmp (tmp - 1)
  ]
end

to set-personality
  set personality random 10 + 1
end

to set-tolerance
  set tolerance random-float 1
end

to set-strategy-commitment
  set strategy one-of ["st" "lt"]
  ifelse strategy = "st"
  [
    set commitment 5
  ]
  [
    set commitment 9
  ]
end

to set-wait
  let total count turtles
  let total-wait (total * pct-wait)
  ask n-of total-wait turtles
  [
    set wait? true
  ]
end

to set-change-tendencies
  if adapt?
  [
    set change-tendency random-float 1
  ]
end
;; setup tasks -------

to move
  ask turtles with [ engaged? = false ] ; only single turtles move
  [  
    set heading random 360
    fd random 5 + 1
    
    check-surroundings ; all get a chance to propose before decisions are made
  ]
  ask turtles with [ engaged? = false ]
  [
    check-my-proposals
    
    if adapt? 
    [
      count-proposals-rejections
    ]
  ]
  
  revive-idle 
  reset-similarities
  
  tick
end

to revive-idle
  ask turtles with [ idle? = true ]
  [
    let wait-time one-of [ 50 100 500 1000 ]
    if (idle-tick + wait-time) = ticks 
    [
      set engaged? false
      reset-shape-size-color
    ]
  ]
end

to reset-similarities
  ask turtles
  [
    set similarity-to 0 
  ]
end 

; look for suitable matches on the way to target
to check-surroundings
  calc-similarity (turtles in-radius 2)
  let my-gender gender
  let my-personality personality
  let my-spa self-perceived-attractiveness
  let my-tolerance tolerance
  let done? false ; each turtle only proposes once per tick
 
  ifelse strategy = "st" 
  [
    ; prioritize looks
    foreach sort-on [ attractiveness ] turtles in-radius 2
    [
      ask ? 
      [ 
        if ? != myself and gender != my-gender and attractiveness >= my-spa and not engaged?
        [
          ifelse [ wait? ] of myself = true 
          [
            if (random 10 + 1) > my-personality and attractiveness >= ideal-phys and not done?
            [
              lets-date
              set done? true
            ]
          ]
          [
            if (random 10 + 1) > my-personality and not done?
            [
              lets-date
              set done? true
            ]
          ]
        ]
      ]
    ]
  ]
  [
    ; prioritize compatibility 
    foreach sort-on [ similarity-to ] turtles in-radius 2 
    [
      ask ? 
      [
        let sim calc-similarity-report ? myself
        
        if ? != myself and gender != my-gender and attractiveness >= my-spa and sim <= my-tolerance and not engaged?
        [
          ifelse [ wait? ] of myself = true 
          [
            if (random 10 + 1) > my-personality and attractiveness >= ideal-phys and sim <= ideal-compatibility and not done? 
            [ 
              lets-date
              set done? true
            ]
          ]
          [
            if (random 10 + 1) > my-personality and not done? 
            [ 
              lets-date
              set done? true
            ]
          ]            
        ]
      ]
    ]
  ]
end

to lets-date
  if old-fashioned? and gender = "female"
  [
    create-link-from myself
    set proposals (proposals + 1) ; proposals received
    set total-proposals (total-proposals + 1) 
  ]
  if not old-fashioned?
  [
    create-link-from myself
    set proposals (proposals + 1)
    set total-proposals (total-proposals + 1)
  ]
end

to check-my-proposals  
  let proposers in-link-neighbors
  calc-similarity (proposers)
  let my-spa self-perceived-attractiveness
  let my-tolerance tolerance
  let done? false ; only accept one 
  
  if proposers != nobody 
  [
    ifelse strategy = "st" 
    [
      foreach sort-on [ attractiveness ] proposers
      [
        ask ? 
        [ 
          ifelse attractiveness >= my-spa and not engaged? and not done?
          [
            ifelse [ wait? ] of myself = true 
            [
              if attractiveness >= ideal-phys
              [
                ok-lets-do-it ? myself
                set done? true
              ]
            ]
            [
              ok-lets-do-it ? myself
              set done? true 
            ]
          ]
          [
            thx-but-no
          ]
        ]
      ]
    ]
    [
      foreach sort-on [ similarity-to ] proposers
      [
        ask ?
        [
          let sim calc-similarity-report ? myself ; smaller sim = more similar
          
          ifelse attractiveness >= my-spa and sim <= my-tolerance and not engaged? and not done?
          [
            ifelse [ wait? ] of myself = true 
            [
              if attractiveness >= ideal-phys and sim <= ideal-compatibility 
              [
                ok-lets-do-it ? myself
                set done? true
              ]
            ]
            [
              ok-lets-do-it ? myself
              set done? true
            ]
          ]
          [
            thx-but-no
          ]
        ]
      ]
    ]
  ]
  
  ; restart proposals
  ask my-in-links 
  [
    die
  ]
end

to ok-lets-do-it[proposer proposee]
  let relationship-score random 10 + 1
  let det min list [ commitment ] of proposer [ commitment ] of proposee 
  
  ifelse relationship-score <= det 
  [
    ask (turtle-set proposer proposee)
    [
      set xcor random-pxcor 
      set ycor one-of [ -14 -13 13 14 ]
      set shape "suit heart"
      set size 2
      set color one-of [ red pink orange ]
      set engaged? true
      
      ask (link-set my-in-links my-out-links)
      [
        die
      ]
    ]
  ]
  [
    ; failed relationship
    ask (turtle-set proposer proposee)
    [
      set idle? true
      set idle-tick ticks
      set shape "face sad" 
      set color yellow
      set engaged? true
      
      ask (link-set my-in-links my-out-links)
      [
        die
      ]
    ]
  ]
end

to thx-but-no
  set rejections (rejections + 1) ; rejections received
  set total-rejections (total-rejections + 1)
end

to count-proposals-rejections
  let chg sentence (random 2) sentence (random 2) sentence (random 2) (random 2)

  ; changes as a result of many proposals
  if proposals > 10 and change-tendency > random-float 1
  [
    if item 0 chg = 1
    [
      set-interests 
    ]
    if item 1 chg = 1
    [
      set personality (personality - 1) 
    ]
    if item 2 chg = 1 
    [
      ifelse (self-perceived-attractiveness + 1) > 10
      [
        set self-perceived-attractiveness 10
      ]
      [
        set self-perceived-attractiveness (self-perceived-attractiveness + 1)
      ]
    ]
    if item 3 chg = 1
    [
      set tolerance (tolerance - 0.1)
    ]
    
    set change-attempts (change-attempts + 1)
    set proposals 0 ; reset proposals
  ]
  ; changes as a result of rejections
  if rejections > 5 and change-tendency > random-float 1
  [
    if item 0 chg = 1
    [
      set-interests
    ]
    if item 1 chg = 1
    [
      set personality (personality + 1)
    ]
    if item 2 chg = 1
    [
      ifelse (self-perceived-attractiveness - 1) < 1
      [
        set self-perceived-attractiveness 1
      ]
      [
        set self-perceived-attractiveness (self-perceived-attractiveness - 1)
      ] 
    ]
    if item 3 chg = 1
    [
      set tolerance (tolerance + 0.1)
    ]
    
    set change-attempts (change-attempts + 1)
    set rejections 0 ; reset rejections 
  ]
end

to reset-shape-size-color
  set shape "person"
  set size 1
  
  ifelse gender = "female"
  [
    set color pink
  ]
  [
    set color blue
  ]
end

to calc-similarity[group]
  let my-gender gender
  ask group
  [
    if gender != my-gender
    [
      let interest1 [ interests ] of myself
      let interest2 interests
      
      let diff (map - interest1 interest2)
      let dist sqrt sum (map * diff diff)
      
      set similarity-to dist ; this always gets reset before it's used
    ]
  ]
end

to-report calc-similarity-report[t1 t2]
  let max-dist sqrt sum [1 1 1 1 1 1 1 1 1 1]
  let interest1 [ interests ] of t1
  let interest2 [ interests ] of t2
  let diff (map - interest1 interest2)
  let dist sqrt sum (map * diff diff)
  
  report dist / max-dist ; want this to be small
end
  
@#$#@#$#@
GRAPHICS-WINDOW
210
10
649
470
16
16
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
16
14
188
47
population-count
population-count
1
500
300
1
1
NIL
HORIZONTAL

SLIDER
15
55
187
88
pct-males
pct-males
0.1
1
0.5
0.1
1
NIL
HORIZONTAL

CHOOSER
31
93
182
138
start-pos
start-pos
"sides" "random" "clusters" "similar interests" "similar appearance" "similar tolerance"
2

BUTTON
4
232
67
265
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
50
141
153
174
adapt?
adapt?
1
1
-1000

BUTTON
73
232
136
265
move
move
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
994
483
1089
528
total proposals
total-proposals
17
1
11

MONITOR
1095
484
1191
529
total rejections
total-rejections
17
1
11

BUTTON
142
232
205
265
move
move
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1196
484
1307
529
avg # of changes
sum [ change-attempts ] of turtles / count turtles
17
1
11

SWITCH
37
185
173
218
old-fashioned?
old-fashioned?
1
1
-1000

SLIDER
19
276
191
309
pct-wait
pct-wait
0
1
0
0.05
1
NIL
HORIZONTAL

INPUTBOX
27
316
88
376
ideal-phys
7
1
0
Number

INPUTBOX
91
316
194
376
ideal-compatibility
0.5
1
0
Number

PLOT
658
12
890
162
happy couples personalities
introvertedness
% of relationships
0.0
5.0
0.0
1.0
true
true
"" "clear-plot"
PENS
"(1-2)" 1.0 1 -16777216 true "" "plotxy 0 (count turtles with [ shape = \"suit heart\" and personality <= 2 ] / (count turtles with [ shape = \"suit heart\" ] + 1))"
"(3-4)" 1.0 1 -7500403 true "" "plotxy 1 (count turtles with [ shape = \"suit heart\" and personality > 2 and personality <= 4 ] / (count turtles with [ shape = \"suit heart\" ] + 1))"
"(5-6)" 1.0 1 -2674135 true "" "plotxy 2 (count turtles with [ shape = \"suit heart\" and personality > 4 and personality <= 6 ] / (count turtles with [ shape = \"suit heart\" ] + 1))"
"(7-8)" 1.0 1 -955883 true "" "plotxy 3 (count turtles with [ shape = \"suit heart\" and personality > 6 and personality <= 8 ] / (count turtles with [ shape = \"suit heart\" ] + 1))"
"(9-10)" 1.0 1 -6459832 true "" "plotxy 4 (count turtles with [ shape = \"suit heart\" and personality > 8 ] / (count turtles with [ shape = \"suit heart\" ] + 1))"

PLOT
658
166
897
316
happy couples attractiveness
attractiveness
% of relationships
0.0
5.0
0.0
1.0
true
true
"" "clear-plot"
PENS
"(1-2)" 1.0 1 -16777216 true "" "plotxy 0 (count turtles with [ shape = \"suit heart\" and attractiveness <= 2 ] / (count turtles with [ shape = \"suit heart\" ] + 1))"
"(3-4)" 1.0 1 -7500403 true "" "plotxy 1 (count turtles with [ shape = \"suit heart\" and attractiveness > 2 and attractiveness <= 4 ] / (count turtles with [ shape = \"suit heart\" ] + 1))"
"(5-6)" 1.0 1 -2674135 true "" "plotxy 2 (count turtles with [ shape = \"suit heart\" and attractiveness > 4 and attractiveness <= 6 ] / (count turtles with [ shape = \"suit heart\" ] + 1))"
"(7-8)" 1.0 1 -955883 true "" "plotxy 3 (count turtles with [ shape = \"suit heart\" and attractiveness > 6 and attractiveness <= 8 ] / (count turtles with [ shape = \"suit heart\" ] + 1))"
"(9-10)" 1.0 1 -6459832 true "" "plotxy 4 (count turtles with [ shape = \"suit heart\" and attractiveness > 8 ] / (count turtles with [ shape = \"suit heart\" ] + 1))"

PLOT
660
322
895
472
happy couples tolerances
tolerance
% of relationships 
0.0
3.0
0.0
1.0
true
true
"" "clear-plot"
PENS
"low" 1.0 1 -16777216 true "" "plotxy 0 (count turtles with [ shape = \"suit heart\" and tolerance <= 0.33 ] / (count turtles with [ shape = \"suit heart\"] + 1))"
"med" 1.0 1 -7500403 true "" "plotxy 1 (count turtles with [ shape = \"suit heart\" and tolerance > 0.33 and tolerance <= 0.66 ] / (count turtles with [ shape = \"suit heart\"] + 1))"
"high" 1.0 1 -2674135 true "" "plotxy 2 (count turtles with [ shape = \"suit heart\" and tolerance > 0.66 ] / (count turtles with [ shape = \"suit heart\" ] + 1))"

PLOT
1108
10
1308
160
v. singles
introvertedness
% of singles
0.0
5.0
0.0
1.0
true
true
"" "clear-plot"
PENS
"(1-2)" 1.0 1 -16777216 true "" "plotxy 0 (count turtles with [ shape = \"person\" and personality <= 2 ] / (count turtles with [ shape = \"person\" ] + 1))"
"(3-4)" 1.0 1 -7500403 true "" "plotxy 1 (count turtles with [ shape = \"person\" and personality > 2 and personality <= 4 ] / (count turtles with [ shape = \"person\" ] + 1))"
"(5-6)" 1.0 1 -2674135 true "" "plotxy 2 (count turtles with [ shape = \"person\" and personality > 4 and personality <= 6 ] / (count turtles with [ shape = \"person\" ] + 1))"
"(7-8)" 1.0 1 -955883 true "" "plotxy 3 (count turtles with [ shape = \"person\" and personality > 6 and personality <= 8 ] / (count turtles with [ shape = \"person\" ] + 1))"
"(9-10)" 1.0 1 -6459832 true "" "plotxy 4 (count turtles with [ shape = \"person\" and personality > 8 ] / (count turtles with [ shape = \"person\" ] + 1))"

PLOT
1109
165
1309
315
v. singles
attractiveness
% of singles
0.0
5.0
0.0
1.0
true
true
"" "clear-plot"
PENS
"(1-2)" 1.0 1 -16777216 true "" "plotxy 0 (count turtles with [ shape = \"person\" and attractiveness <= 2 ] / (count turtles with [ shape = \"person\" ] + 1))"
"(3-4)" 1.0 1 -7500403 true "" "plotxy 1 (count turtles with [ shape = \"person\" and attractiveness > 2 and attractiveness <= 4 ] / (count turtles with [ shape = \"person\" ] + 1))"
"(5-6)" 1.0 1 -2674135 true "" "plotxy 2 (count turtles with [ shape = \"person\" and attractiveness > 4 and attractiveness <= 6 ] / (count turtles with [ shape = \"person\" ] + 1))"
"(7-8)" 1.0 1 -955883 true "" "plotxy 3 (count turtles with [ shape = \"person\" and attractiveness > 6 and attractiveness <= 8 ] / (count turtles with [ shape = \"person\" ] + 1))"
"(9-10)" 1.0 1 -6459832 true "" "plotxy 4 (count turtles with [ shape = \"person\" and attractiveness > 8 ] / (count turtles with [ shape = \"person\" ] + 1))"

PLOT
1109
321
1309
471
v. singles
tolerance
% of singles
0.0
3.0
0.0
1.0
true
true
"" "clear-plot"
PENS
"llow" 1.0 1 -16777216 true "" "plotxy 0 (count turtles with [ shape = \"person\" and tolerance <= 0.33 ] / (count turtles with [ shape = \"person\" ] + 1))"
"medium" 1.0 1 -7500403 true "" "plotxy 1 (count turtles with [ shape = \"person\" and tolerance > 0.33 and tolerance <= 0.66 ] / (count turtles with [ shape = \"person\" ] + 1))"
"high" 1.0 1 -2674135 true "" "plotxy 2 (count turtles with [ shape = \"person\" and tolerance > 0.66 ] / (count turtles with [ shape = \"person\" ] + 1))"

MONITOR
650
480
713
525
# singles
count turtles with [ shape = \"person\" ]
17
1
11

MONITOR
719
481
832
526
# bad relationship
count turtles with [ shape = \"face sad\" ]
17
1
11

MONITOR
837
481
964
526
# happy relationship
count turtles with [ shape = \"suit heart\" ]
17
1
11

PLOT
901
13
1101
163
v. unhappy couples
introvertedness
% of bad relationships
0.0
5.0
0.0
1.0
true
true
"" "clear-plot"
PENS
"(1-2)" 1.0 1 -16777216 true "" "plotxy 0 (count turtles with [ shape = \"face sad\" and personality <= 2 ] / (count turtles with [ shape = \"face sad\" ] + 1))"
"(3-4)" 1.0 1 -7500403 true "" "plotxy 1 (count turtles with [ shape = \"face sad\" and personality > 2 and personality <= 4 ] / (count turtles with [ shape = \"face sad\" ] + 1))"
"(5-6)" 1.0 1 -2674135 true "" "plotxy 2 (count turtles with [ shape = \"face sad\" and personality > 4 and personality <= 6 ] / (count turtles with [ shape = \"face sad\" ] + 1))"
"(7-8)" 1.0 1 -955883 true "" "plotxy 3 (count turtles with [ shape = \"face sad\" and personality > 6 and personality <= 8 ] / (count turtles with [ shape = \"face sad\" ] + 1))"
"(9-10)" 1.0 1 -6459832 true "" "plotxy 4 (count turtles with [ shape = \"face sad\" and personality > 8 ] / (count turtles with [ shape = \"face sad\" ] + 1))"

PLOT
902
166
1102
316
v. unhappy couples
attractiveness
% of bad relationship
0.0
5.0
0.0
1.0
true
true
"" "clear-plot"
PENS
"(1-2)" 1.0 1 -16777216 true "" "plotxy 0 (count turtles with [ shape = \"face sad\" and attractiveness <= 2 ] / (count turtles with [ shape = \"face sad\" ] + 1))"
"(3-4)" 1.0 1 -7500403 true "" "plotxy 1 (count turtles with [ shape = \"face sad\" and attractiveness > 2 and attractiveness <= 4 ] / (count turtles with [ shape = \"face sad\" ] + 1))"
"(5-6)" 1.0 1 -2674135 true "" "plotxy 2 (count turtles with [ shape = \"face sad\" and attractiveness > 4 and attractiveness <= 6 ] / (count turtles with [ shape = \"face sad\" ] + 1))"
"(7-8)" 1.0 1 -955883 true "" "plotxy 3 (count turtles with [ shape = \"face sad\" and attractiveness > 6 and attractiveness <= 8 ] / (count turtles with [ shape = \"face sad\" ] + 1))"
"(9-10)" 1.0 1 -6459832 true "" "plotxy 4 (count turtles with [ shape = \"face sad\" and attractiveness > 8 ] / (count turtles with [ shape = \"face sad\" ] + 1))"

PLOT
901
319
1101
469
v. unhappy couples
tolerance
% of bad relationships
0.0
3.0
0.0
1.0
true
true
"" "clear-plot"
PENS
"low" 1.0 1 -16777216 true "" "plotxy 0 (count turtles with [ shape = \"face sad\" and tolerance <= 0.33 ] / (count turtles with [ shape = \"face sad\" ] + 1))"
"medium" 1.0 1 -7500403 true "" "plotxy 1 (count turtles with [ shape = \"face sad\" and tolerance > 0.33 and tolerance <= 0.66 ] / (count turtles with [ shape = \"face sad\" ] + 1))"
"high" 1.0 1 -2674135 true "" "plotxy 2 (count turtles with [ shape = \"face sad\" and tolerance < 0.66 ] / (count turtles with [ shape = \"face sad\" ] + 1))"

BUTTON
29
392
171
426
follow random turtle
follow turtle (random population-count)
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
## WHAT IS IT?

This model attempts to replicate the real-world dating environment by allowing turtles to interact by making proposals as well as accept or reject them. 

The world is composed of single turtles, turtles in relationships, and turtles in unhappy relationships. Single turtles look for partners based on its preferences. Turtles in relationships stay in their happy relationships, while turtles in unhappy relationships are idle (i.e., it can’t be proposed to or make proposals) for a set period of time.

## HOW IT WORKS
The agents have a gender an attractiveness score (i.e., how others see them), a self-perceived attractiveness score (i.e., how they see themselves), an interests vector, a personality (i.e., degree of introversion) score, a tolerance level (i.e., how different can the partner be) and a strategy (i.e., looking for a short term relationship or a long term relationship). 

At each tick, the agent makes steps towards a random direction. It looks at its neighbors and depending on what its strategy is and how it perceives itself, it chooses a target among the neighbors and proposes a date. Each turtle can only propose a date once per tick. Then, each turtle checks the proposals it has received, and chooses one to accept based on its own preferences and characteristics. 

## HOW TO USE IT

Using the sliders, choosers and switches, the user can adjust the environment conditions. 
population-count: number of agents in the world
pct-male: the percentage of males in the world
start-pos: vary the agents' starting positions
	> sides: both genders line up on separate sides 
	> random: random positions
	> clusters: four distinct clusters by gender
	> similar interests: agents are situated near others that have similar interests
	> similar appearance: agents are situated near others that have similar attractiveness scores
	> similar tolerance: agents are situated near others that ahve similar tolerances 	> adapt?: whether or not there are adaptable turtles in the world; each agent is free to choose its own tendency to change parameter 
	> old-fashioned?: whether or not proposals can only be made by males
	> pct-wait: the percentage of agents that wait for the ideal match
	> ideal-phys, ideal-compatibility: characterisitcs of the ideal match

## THINGS TO NOTICE

- Unhappy agents turning into single agents; some take much longer than others
- The speed at which some agents get into relationships; for example, some agents receive many proposals but never get into a relationship
- The advantage of being one of the first to approach and/or propose to another agent
- Under certain conditions, although there are quite a few single turtles left, no proposals or rejections will be made because nobody fits anyone's standards ; the model reaches a "steady state" 
- The rates of increase and decrease and the values of numerical variables ; for example, the number of proposals and rejections that must happen for a certain number of relationships to occur, or the ratio of unhappy relationships to happy relationships 

## THINGS TO TRY

- Test how the results change when the percentage of one gender is much greater than the other gender 
- Adjust the characteristics for the ideal mate 
- Use different starting positions 

## EXTENDING THE MODEL
Any of the model's input parameters or turtles' behavior variables can be adjusted depending on the user's curiosities. Here are some suggestions for extensions:
- New starting positions can be modified or added in the set-positions function
- Currently, turtles will wander around indefinitely until a suitable match is found; loneliness can be incorporated into a turtle's behavior
- Introduce homosexual relationships
- Allow turtles to introduce friends who would be a great match
- Add more dimensions to behavior; use continous variables instead of boolean variables 

## CREDITS AND REFERENCES

Created by Melody Yin for the final project of EECS 472, taught by Professor Uri Wilensky in Spring 2015. 
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

suit heart
false
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>move</go>
    <exitCondition>ticks = 1000</exitCondition>
    <metric>count turtles with [ shape = "person" ]</metric>
    <metric>count turtles with [ shape = "person" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "face sad" ]</metric>
    <metric>count turtles with [ shape = "face sad" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" ]</metric>
    <metric>count turtles with [ shape = "suit heart" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and tolerance &lt;= 0.5 ]</metric>
    <enumeratedValueSet variable="pct-males">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pct-wait">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="old-fashioned?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-pos">
      <value value="&quot;sides&quot;"/>
      <value value="&quot;random&quot;"/>
      <value value="&quot;clusters&quot;"/>
      <value value="&quot;similar interests&quot;"/>
      <value value="&quot;similar appearance&quot;"/>
      <value value="&quot;similar tolerance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population-count">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 2" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>move</go>
    <exitCondition>ticks = 1000</exitCondition>
    <metric>count turtles with [ shape = "person" ]</metric>
    <metric>count turtles with [ shape = "person" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "face sad" ]</metric>
    <metric>count turtles with [ shape = "face sad" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" ]</metric>
    <metric>count turtles with [ shape = "suit heart" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and tolerance &lt;= 0.5 ]</metric>
    <enumeratedValueSet variable="pct-males">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pct-wait">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="old-fashioned?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-pos">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population-count">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>move</go>
    <exitCondition>ticks = 1000</exitCondition>
    <metric>count turtles with [ shape = "person" ]</metric>
    <metric>count turtles with [ shape = "person" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "face sad" ]</metric>
    <metric>count turtles with [ shape = "face sad" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" ]</metric>
    <metric>count turtles with [ shape = "suit heart" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and tolerance &lt;= 0.5 ]</metric>
    <enumeratedValueSet variable="pct-males">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pct-wait">
      <value value="0"/>
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ideal-phys">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ideal-compatibility">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="old-fashioned?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-pos">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population-count">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 4" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>move</go>
    <exitCondition>ticks = 1000</exitCondition>
    <metric>count turtles with [ shape = "person" ]</metric>
    <metric>count turtles with [ shape = "person" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "face sad" ]</metric>
    <metric>count turtles with [ shape = "face sad" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" ]</metric>
    <metric>count turtles with [ shape = "suit heart" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and tolerance &lt;= 0.5 ]</metric>
    <enumeratedValueSet variable="pct-males">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pct-wait">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="old-fashioned?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-pos">
      <value value="&quot;sides&quot;"/>
      <value value="&quot;random&quot;"/>
      <value value="&quot;clusters&quot;"/>
      <value value="&quot;similar appearance&quot;"/>
      <value value="&quot;similar interests&quot;"/>
      <value value="&quot;similar tolerance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population-count">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 5" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>move</go>
    <exitCondition>ticks = 1000</exitCondition>
    <metric>count turtles with [ shape = "person" ]</metric>
    <metric>count turtles with [ shape = "person" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "face sad" ]</metric>
    <metric>count turtles with [ shape = "face sad" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" ]</metric>
    <metric>count turtles with [ shape = "suit heart" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and tolerance &lt;= 0.5 ]</metric>
    <enumeratedValueSet variable="pct-males">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pct-wait">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="old-fashioned?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-pos">
      <value value="&quot;sides&quot;"/>
      <value value="&quot;random&quot;"/>
      <value value="&quot;clusters&quot;"/>
      <value value="&quot;similar appearance&quot;"/>
      <value value="&quot;similar interests&quot;"/>
      <value value="&quot;similar tolerance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population-count">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 6" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>move</go>
    <exitCondition>ticks = 1000</exitCondition>
    <metric>count turtles with [ shape = "person" ]</metric>
    <metric>count turtles with [ shape = "person" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "person" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "face sad" ]</metric>
    <metric>count turtles with [ shape = "face sad" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "face sad" and tolerance &lt;= 0.5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" ]</metric>
    <metric>count turtles with [ shape = "suit heart" and personality &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and attractiveness &lt;= 5 ]</metric>
    <metric>count turtles with [ shape = "suit heart" and tolerance &lt;= 0.5 ]</metric>
    <enumeratedValueSet variable="pct-males">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pct-wait">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="old-fashioned?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-pos">
      <value value="&quot;sides&quot;"/>
      <value value="&quot;random&quot;"/>
      <value value="&quot;clusters&quot;"/>
      <value value="&quot;similar appearance&quot;"/>
      <value value="&quot;similar interests&quot;"/>
      <value value="&quot;similar tolerance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population-count">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adapt?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
