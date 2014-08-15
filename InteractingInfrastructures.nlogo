extensions [matpowerconnect rserve]

globals [
  total-adaptation-costs
  total-redundant-interdependencies
  total-capacity-increase
  mean-initial-network-capacity
  total-resilience
  number-of-components-to-fail
  matpower-total-bus-list
  matpower-total-generator-list
  matpower-total-link-list
  matpower-input-list
  matpower-output-list
]

breed [buses bus]
breed [generators generator]
breed [loads load]
breed [infra2-buses infra2-bus]

undirected-link-breed [bus-links bus-link]
undirected-link-breed [component-links component-link]
undirected-link-breed [interdependency-links interdependency-link]
undirected-link-breed [infra2-bus-links infra2-bus-link]
undirected-link-breed [infra2-component-links infra2-component-link]

buses-own [
  
  bus-protected?
  bus-list ;the matpower list for each bus  
  bus-power-injected
  
  ;matpower variables                                          
  bus-number ;matpower variable               
  bus-type-matpower ;matpower variable             
  bus-real-power-demand ;matpower variable
  bus-reactive-power-demand ;matpower variable
  bus-shunt-conductance ;matpower variable
  bus-shunt-susceptance ;matpower variable
  bus-area-number ;matpower variable
  bus-voltage-magnitude ;matpower variable
  bus-voltage-angle ;matpower variable
  bus-base-voltage ;matpower variable
  bus-loss-zone ;matpower variable
  bus-maximum-voltage-magnitude ;matpower variable
  bus-minimum-voltage-magnitude ;matpower variable
]

generators-own [
  
  generator-bus
  generator-number
  generator-list ;the matpower list for each generator
  
  ;matpower variables    
  generator-real-power-output             
  generator-reactive-power-output 
  generator-maximum-reactive-power-output
  generator-minimum-reactive-power-output 
  generator-voltage-magnitude-setpoint 
  generator-mbase
  generator-matpower-status  
  generator-maximum-real-power-output  
  generator-minimum-real-power-output 
  generator-lower-real-power-output  
  generator-upper-real-power-output  
  generator-mimimum-reactive-power-output-at-pc1   
  generator-maximum-reactive-power-output-at-pc1   
  generator-mimimum-reactive-power-output-at-pc2  
  generator-maximum-reactive-power-output-at-pc2 
  generator-ramp-rate-load
  generator-ramp-rate-10-min  
  generator-ramp-rate-30-min 
  generator-ramp-rate-reactive    
  generator-area-participation-factor
]

loads-own [
  load-power-demand
  load-power-received
  load-bus
  load-satisfaction
]

links-own [
  failed?
  failure-origin?
]

bus-links-own [
  
  link-load
  link-capacity
  link-overload
  link-list ;the matpower list for each link
  matpower-link-results-list ;the matpower output for the link
  
  ;matpower variables
  link-from-bus-number
  link-to-bus-number
  link-resistance
  link-reactance
  link-total-line-charging-susceptance
  link-rate-a
  link-rate-b
  link-rate-c
  link-ratio
  link-angle
  link-status
  link-minimum-angle-difference
  link-maximum-angle-difference
  
  link-power-injected-from-end
  link-power-injected-to-end
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; SETUP ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  
  clear-all
  reset-ticks
  set total-adaptation-costs 0
  set total-redundant-interdependencies 0
  set total-capacity-increase 0
  set total-resilience 0
  
  create-electricity-network
  create-infra2-network
  set-link-capacities
  ;adjust-network-layout
  update-visualization
  
end


to create-electricity-network

  if (case-to-load = "IEEE case 9") [file-open "casedata/case9_busdata"]
  if (case-to-load = "IEEE case 14") [file-open "casedata/case14_busdata"]
  if (case-to-load = "IEEE case 30") [file-open "casedata/case30_busdata"]
  if (case-to-load = "IEEE case 118") [file-open "casedata/case118_busdata"]
  while [not file-at-end?] [
    let current-line read-from-string (word "[" file-read-line "]")
    create-buses 1 [
      set bus-protected? false
      set bus-number item 0 current-line
      set bus-real-power-demand item 2 current-line
      set bus-reactive-power-demand item 3 current-line
      set bus-shunt-conductance item 4 current-line
      set bus-shunt-susceptance item 5 current-line
      set bus-area-number item 6 current-line
      set bus-voltage-magnitude item 7 current-line
      set bus-voltage-angle item 8 current-line
      set bus-base-voltage item 9 current-line
      set bus-loss-zone item 10 current-line
      set bus-maximum-voltage-magnitude item 11 current-line
      set bus-minimum-voltage-magnitude item 12 current-line
    ]
  ]
  file-close
  
  ask buses with [bus-real-power-demand > 0] [
    hatch-loads 1 [
      set load-power-demand [bus-real-power-demand] of myself
      set load-bus myself
      create-component-link-with myself
    ]
  ]
  
  if (case-to-load = "IEEE case 9") [file-open "casedata/case9_generatordata"]
  if (case-to-load = "IEEE case 14") [file-open "casedata/case14_generatordata"]
  if (case-to-load = "IEEE case 30") [file-open "casedata/case30_generatordata"]
  if (case-to-load = "IEEE case 118") [file-open "casedata/case118_generatordata"]
  let i 0
  while [not file-at-end?] [
    let current-line read-from-string (word "[" file-read-line "]")
    set i i + 1
    create-generators 1 [
      set generator-number i
      set generator-bus one-of buses with [bus-number = item 0 current-line]
      set generator-real-power-output item 1 current-line             
      set generator-reactive-power-output item 2 current-line 
      set generator-maximum-reactive-power-output item 3 current-line 
      set generator-minimum-reactive-power-output item 4 current-line 
      set generator-voltage-magnitude-setpoint item 5 current-line 
      set generator-mbase item 6 current-line 
      set generator-matpower-status item 7 current-line 
      set generator-maximum-real-power-output item 8 current-line 
      set generator-minimum-real-power-output item 9 current-line 
      set generator-lower-real-power-output item 10 current-line 
      set generator-upper-real-power-output item 11 current-line 
      set generator-mimimum-reactive-power-output-at-pc1 item 12 current-line 
      set generator-maximum-reactive-power-output-at-pc1 item 13 current-line 
      set generator-mimimum-reactive-power-output-at-pc2 item 14 current-line 
      set generator-maximum-reactive-power-output-at-pc2 item 15 current-line 
      set generator-ramp-rate-load item 16 current-line 
      set generator-ramp-rate-10-min item 17 current-line 
      set generator-ramp-rate-30-min item 18 current-line 
      set generator-ramp-rate-reactive item 19 current-line 
      set generator-area-participation-factor item 20 current-line 
      
      create-component-link-with generator-bus
    ]
  ]
  file-close
  
  if (case-to-load = "IEEE case 9") [file-open "casedata/case9_linedata"]
  if (case-to-load = "IEEE case 14") [file-open "casedata/case14_linedata"]
  if (case-to-load = "IEEE case 30") [file-open "casedata/case30_linedata"]
  if (case-to-load = "IEEE case 118") [file-open "casedata/case118_linedata"]
  while [not file-at-end?] [
    let current-line read-from-string (word "[" file-read-line "]")
    let bus1 one-of buses with [bus-number = item 0 current-line]
    let bus2 one-of buses with [bus-number = item 1 current-line]
    ask bus1 [
      create-bus-link-with bus2 [
        set link-capacity 0
        set link-from-bus-number item 0 current-line
        set link-to-bus-number item 1 current-line
        set link-resistance item 2 current-line
        set link-reactance item 3 current-line
        set link-total-line-charging-susceptance item 4 current-line
        set link-rate-a item 5 current-line
        set link-rate-b item 6 current-line
        set link-rate-c item 7 current-line
        set link-ratio item 8 current-line
        set link-angle item 9 current-line
        set link-status item 10 current-line
        set link-minimum-angle-difference item 11 current-line
        set link-maximum-angle-difference item 12 current-line
      ]
    ]
  ]
  file-close
  
end


to create-infra2-network
  
  create-infra2-buses number-of-infra2-buses [
    if (count infra2-buses > 1) [create-infra2-bus-link-with one-of other infra2-buses]
  ]
  while [count infra2-bus-links < number-of-infra2-links] [
    ask one-of infra2-buses [create-infra2-bus-link-with one-of other infra2-buses]
  ]
  
  ask infra2-buses [
    if (random-float 1 < number-of-interdependencies / count infra2-buses) [
      create-interdependency-link-with one-of buses
    ]
  ]
  
  ask buses [set bus-protected? false]
  if (adaptation-strategy = 2 or adaptation-strategy = 4) [
    let number-of-interdependency-buses 0
    ask buses [
      let interdependency-bus? false
      ask my-links [if (breed = interdependency-links) [set interdependency-bus? true]]
      if (interdependency-bus? = true) [set number-of-interdependency-buses number-of-interdependency-buses + 1]
    ]
    
    while [count buses with [bus-protected? = true] < number-of-known-interdependencies and count buses with [bus-protected? = true] < number-of-interdependency-buses] [
      ask one-of interdependency-links [
        ask both-ends [
          if (breed = buses) [
            if (bus-protected? = false) [
              set bus-protected? true
              set total-adaptation-costs total-adaptation-costs + 1
              set total-redundant-interdependencies total-redundant-interdependencies + 1
            ]
          ]
        ]
      ]
    ]
  ]
  
end


to set-link-capacities
  
  file-open "inputdata/linecapacities"
  
  while [not file-at-end?] [
    let current-line read-from-string (word "[" file-read-line "]")
    ask bus-links with [link-from-bus-number = item 0 current-line and link-to-bus-number = item 1 current-line] [
      set link-capacity item 2 current-line
    ]
  ]
  
  file-close
  
  set mean-initial-network-capacity mean [link-capacity] of bus-links
  
  if (adaptation-strategy = 3) [
    
    ask bus-links [
      set link-capacity link-capacity * 1.5
      set total-adaptation-costs total-adaptation-costs + (0.5 * link-capacity / 1.5) / mean-initial-network-capacity
      set total-capacity-increase total-capacity-increase + (0.5 * link-capacity / 1.5)
    ]
  ]
  
end


to calculate-and-save-link-capacities
  
  clear-all
  reset-ticks
  create-electricity-network
  calculate-link-capacities
  
end


to calculate-link-capacities
  
  ask bus-links [
    set failed? false
    set link-capacity 0
  ]
  
  ask bus-links [
    
    set failed? true
    calculate-electricity-network-loads
    ask bus-links [
      if (link-load > link-capacity) [set link-capacity link-load]
    ]
    
    set failed? false
  ]
  
  let total-capacity-list []
  ask bus-links [
    let capacity-list []
    set capacity-list lput link-from-bus-number capacity-list
    set capacity-list lput link-to-bus-number capacity-list
    set capacity-list lput link-capacity capacity-list
    set total-capacity-list lput capacity-list total-capacity-list
  ]
  
  file-open "inputdata/linecapacities"
  file-print total-capacity-list
  file-close

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; GO ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
   
  generate-failures
  
  if (count links with [failure-origin? = true] = 0) [calculate-electricity-network-loads]
   
  while [count links with [failure-origin? = true] > 0] [
    propagate-infra2-failures
    propagate-electricity-network-failures
    kill-interdependency-links
  ]

  calculate-demand-satisfaction
  apply-measure
  update-visualization
  
  tick
   
end


to generate-failures
  
  ask links [set failed? false]
  ask bus-links [set link-overload 0]
  
  rserve:init 6311 "localhost"
  rserve:eval "library(gPdtest)"
  rserve:eval (word "x <- rgp(1,0.25," pareto-scale-parameter ")")
  set number-of-components-to-fail round(rserve:get "x")
  rserve:close
  
  repeat number-of-components-to-fail [
    let unfailed-links (link-set bus-links with [failed? = false] infra2-bus-links with [failed? = false] interdependency-links with [failed? = false])
    if (count unfailed-links > 0) [
      ask one-of unfailed-links [
        set failed? true 
        set failure-origin? true
      ]
    ]
  ]
  
end

to test-rserve-connection
  
  rserve:init 6311 "localhost"
  rserve:eval "library(gPdtest)"
  rserve:eval (word "x <- rgp(1,0.25," pareto-scale-parameter ")")
  print round(rserve:get "x")
  rserve:close
  
end


to propagate-infra2-failures
  
  let failed-links (link-set infra2-bus-links with [failure-origin? = true] interdependency-links with [failure-origin? = true])
  ask failed-links [propagate-infra2-failure] 
  ask links [set failure-origin? false]
   
end


to propagate-infra2-failure
    ask both-ends [
      if (breed = infra2-buses) [
        let my-unfailed-links (link-set my-infra2-bus-links with [failed? = false] my-interdependency-links with [failed? = false])
        ask my-unfailed-links [
          if (random-float 1 < probability-of-infra2-failure-propagation) [
            set failed? true
            propagate-infra2-failure
          ]
        ]
      ]
      if (breed = buses) [
        if (bus-protected? = false) [
          ask my-bus-links [set failed? true]
          if (adaptation-strategy = 2 or adaptation-strategy = 4) [
            set bus-protected? true
            set total-adaptation-costs total-adaptation-costs + 1
            set total-redundant-interdependencies total-redundant-interdependencies + 1
          ]
        ]
      ]
    ]
end


to propagate-electricity-network-failures
  
  calculate-electricity-network-loads
  
  let links-overloaded? false
  ask bus-links [
    if (link-load > link-capacity) [
      set failed? true
      set links-overloaded? true
      if (link-load - link-capacity > link-overload) [set link-overload link-load - link-capacity]
    ]
  ]
  
  if (links-overloaded? = true) [
    propagate-electricity-network-failures
  ]
  
  ask bus-links [set failure-origin? false]

end


to calculate-electricity-network-loads
  
  set-bus-link-status
  set-generator-outputs
  set-power-demand-of-buses
  create-matpower-lists
  create-final-matpower-list
  run-matpower
  
end


to kill-interdependency-links
  
  ask interdependency-links with [failed? = false] [
     let kill-interdependency-link? true
     ask both-ends [
       if (breed = buses) [
         ask my-bus-links [
           if (failed? = false) [
             set kill-interdependency-link? false
           ]
         ]
       ]
     ]
     if (kill-interdependency-link? = true) [
       set failed? true
       set failure-origin? true
     ]
   ]
  
end


to calculate-demand-satisfaction
  
  ask loads [
    set load-power-received ([bus-power-injected] of one-of component-link-neighbors / [count component-link-neighbors with [breed = loads]] of one-of component-link-neighbors)
    set load-satisfaction load-power-received / load-power-demand
  ] 
  
  set total-resilience (total-resilience * (ticks + 1 - 1) + mean [load-satisfaction] of loads) / (ticks + 1)

end


to apply-measure
  
  if (adaptation-strategy = 1 or adaptation-strategy = 4) [
    let total-capacity-added 0
    ask bus-links [
      set link-capacity link-capacity + link-overload
      set total-capacity-added total-capacity-added + link-overload
    ]
    set total-adaptation-costs total-adaptation-costs + total-capacity-added / mean-initial-network-capacity
    set total-capacity-increase total-capacity-increase + total-capacity-added
  ]
  
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; MATPOWER PROCEDURES ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to set-bus-link-status
  
  ask bus-links with [failed? = true] [set link-status 0]
  ask bus-links with [failed? = false] [set link-status 1]
  
end


to set-generator-outputs
  
  let total-generation-capacity sum [generator-maximum-real-power-output] of generators
  let total-demand sum [load-power-demand] of loads
  let demand-supply-ratio total-demand / total-generation-capacity
  
  ask generators [
    ifelse (demand-supply-ratio <= 1) [
      set generator-real-power-output generator-maximum-real-power-output * demand-supply-ratio
    ]
    [
      set generator-real-power-output generator-maximum-real-power-output
    ]
  ]
  
end


to set-power-demand-of-buses
  
  ask buses [set bus-real-power-demand 0]
  
  ask loads [
    ask load-bus [
      set bus-real-power-demand bus-real-power-demand + [load-power-demand] of myself
      set bus-reactive-power-demand 0
    ]
  ]

end


;create the bus, generator and link lists for each individual bus, generator and link
to create-matpower-lists
  
  ask buses [
    set bus-list 
      (list 
        bus-number 
        bus-type-matpower 
        bus-real-power-demand
        bus-reactive-power-demand 
        bus-shunt-conductance 
        bus-shunt-susceptance 
        bus-area-number 
        bus-voltage-magnitude 
        bus-voltage-angle 
        bus-base-voltage 
        bus-loss-zone 
        bus-maximum-voltage-magnitude 
        bus-minimum-voltage-magnitude)
  ]
  
  ask generators [
    set generator-list 
        (list 
          [bus-number] of generator-bus
          generator-real-power-output 
          generator-reactive-power-output 
          generator-maximum-reactive-power-output 
          generator-minimum-reactive-power-output 
          generator-voltage-magnitude-setpoint 
          generator-mbase 
          generator-matpower-status 
          generator-maximum-real-power-output 
          generator-minimum-real-power-output 
          generator-lower-real-power-output 
          generator-upper-real-power-output 
          generator-mimimum-reactive-power-output-at-pc1 
          generator-maximum-reactive-power-output-at-pc1 
          generator-mimimum-reactive-power-output-at-pc2 
          generator-maximum-reactive-power-output-at-pc2 
          generator-ramp-rate-load 
          generator-ramp-rate-10-min 
          generator-ramp-rate-30-min 
          generator-ramp-rate-reactive 
          generator-area-participation-factor)
  ]
  
  ask bus-links [
    set link-list 
      (list 
        link-from-bus-number 
        link-to-bus-number 
        link-resistance 
        link-reactance 
        link-total-line-charging-susceptance 
        link-rate-a 
        link-rate-b 
        link-rate-c 
        link-ratio 
        link-angle 
        link-status 
        link-minimum-angle-difference 
        link-maximum-angle-difference)
  ]

end


to create-final-matpower-list
  
  ;create the bus list for matpower
  set matpower-total-bus-list [] ;create an empty total bus list
  ask buses [set matpower-total-bus-list lput bus-list matpower-total-bus-list] ;add each bus list to the total bus list
  set matpower-total-bus-list sort-by [first ?1 < first ?2] matpower-total-bus-list ;sort the total bus list by bus number. this is necessary; otherwise matpower sometimes fails
  
  ;create the gen list list for matpower
  set matpower-total-generator-list [] ;create an empty total generator list
  ;ask generators with [count [my-bus-links with [link-status = 1]] of generator-bus > 0] [
  ask generators [
    set matpower-total-generator-list lput generator-list matpower-total-generator-list ;add each generator list to the total generator list
  ]
  ;set total-generator-list sort-by [first ?1 < first ?2] total-generator-list ;sort the total generator list by the generator-number
  ;foreach total-generator-list [set ? remove-item 0 ?] ;delete the generator numbers from the total-generator-list. matpower doesn't need this - it's only for our own accounting
  
  ;create the link list for matpower
  set matpower-total-link-list [] ;create an empty total link list
  ask bus-links [set matpower-total-link-list lput link-list matpower-total-link-list] ;for each link that is functional, add the link list to the total link list
  ;set matpower-total-link-list sort-by [item 1 ?1 < item 1 ?2] matpower-total-link-list ;sort the total link list by the bus number of the from end
  ;set matpower-total-link-list sort-by [first ?1 < first ?2] matpower-total-link-list ;sort the total link list by the bus number of the to end
  
  ;set the extra variables for matpower
  let basemva 100
  let area [1 1]
  
  ;assemble the final list to be inputted to matpower
  ;set matpower-input-list (list basemva matpower-total-bus-list matpower-total-generator-list matpower-total-link-list matpower-total-gencost-list area analysis) 
  set matpower-input-list (list basemva matpower-total-bus-list matpower-total-generator-list matpower-total-link-list area) 
  if (print-power-flow-data?) [print matpower-input-list]

end


to run-matpower 
  
  ;reset the component values
  ask bus-links [set link-load 0]
  ask buses [set bus-power-injected 0]
  let total-generator-output 0
  
  ;check to make sure we're passing a feasible network to the matpowerconnect extension
  ifelse (length item 1 matpower-input-list > 0 and length item 2 matpower-input-list > 0 and length item 3 matpower-input-list > 0 and length item 4 matpower-input-list > 0) [    
    ;pass the input list to matpower
    set matpower-output-list matpowerconnect:octavetest matpower-input-list
    if (print-power-flow-data?) [print matpower-output-list]
    
    ;parse the output list
    let matpower-link-output-data item 0 matpower-output-list
    let matpower-generator-output-data item 1 matpower-output-list
    
    ask buses [set bus-power-injected 0] ;reset the bus-power-injected value
    
    ;set the link loads and bus injections based on the matpower results
    ask bus-links with [link-status = 1] [
      
      foreach matpower-link-output-data [
        if (item 0 ? = link-from-bus-number AND item 1 ? = link-to-bus-number) [set matpower-link-results-list ?] ;if the numbers of the from bus and the to bus match, extract the data for this link
      ]
      
      set link-power-injected-from-end item 2 matpower-link-results-list
      set link-power-injected-to-end item 3 matpower-link-results-list
      set link-load item 4 matpower-link-results-list
      
      ask one-of buses with [bus-number = [link-from-bus-number] of myself] [
        set bus-power-injected bus-power-injected - [link-power-injected-from-end] of myself
      ]
      ask one-of buses with [bus-number = [link-to-bus-number] of myself] [
        set bus-power-injected bus-power-injected - [link-power-injected-to-end] of myself
      ]
    ]
    
    ask bus-links with [link-status = 0] [
      set link-load 0
    ]
    
    ;add the generator injections to the buses and calculate the total generator output
    set total-generator-output 0
    foreach matpower-generator-output-data [
      ask one-of buses with [bus-number = item 0 ?] [
        set bus-power-injected bus-power-injected + item 1 ?
        set total-generator-output total-generator-output + item 1 ?
      ]
    ]
  ]
  [
    print "Infeasible network.  Network not passed to the extension."
  ]

end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; VISUALIZATION ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to adjust-network-layout
  
  repeat 5000 [ layout-spring (turtle-set buses generators loads infra2-buses) (link-set bus-links component-links infra2-bus-links infra2-component-links interdependency-links) 0.1 0.1 1 ]

end
   
   
to update-visualization
  
  ask patches [
    set pcolor white
  ]
  
  ask buses [
    set shape "circle"
    set size 0.5
    set color black
  ]
  
  ask generators [
    set shape "circle"
    set size 1
    set color blue
    
    if (show-labels?) [
      set label generator-maximum-real-power-output
      set label-color white
    ]
  ]
  
  ask loads [
    set shape "circle"
    set size 1
    set color green
    
    if (show-labels?) [
      set label round load-power-received
      set label-color white
    ]
  ]
  
  ask bus-links [
    if (failed? = false) [set color black]
    if (failed? = true) [set color red]
    
    if (show-labels?) [
      set label round link-load
      set label-color black
    ]
  ]

  ask infra2-buses [
    set shape "circle"
    set size 0.5
    set color gray
  ]
  
  ask infra2-bus-links [
    if (failed? = false) [set color gray]
    if (failed? = true) [set color red]
  ]
  
  ask interdependency-links [
    if (failed? = false) [set color black]
    if (failed? = true) [set color red]
  ]
  
  ask component-links [set color black]
  ask infra2-component-links [set color gray]
  
end


to visualize-infra2-network
  
  ask patches [
    set pcolor white
  ]
  
  ask buses [
    set hidden? true
  ]
  
  ask generators [
    set hidden? true
  ]
  
  ask loads [
    set hidden? true
  ]
  
  ask bus-links [
    set hidden? true
  ]

  ask infra2-buses [
    set hidden? false
    set shape "circle"
    set size 0.5
    set color black
  ]
  
  ask infra2-bus-links [
    set hidden? false
    if (failed? = false) [set color black]
    if (failed? = true) [set color black]
  ]
  
  ask interdependency-links [
    set hidden? true
  ]
  
  ask component-links [set hidden? true set color black]
  
  repeat 5000 [ layout-spring (turtle-set infra2-buses) (link-set infra2-bus-links) 0.1 0.1 10 ]
  
end


to visualize-electricity-network
  
  ask patches [
    set pcolor white
  ]
  
  ask buses [
    set hidden? false
    set shape "circle"
    set size 0.5
    set color black
  ]
  
  ask generators [
    set hidden? false
    set shape "circle"
    set size 1
    set color blue
    
    if (show-labels?) [
      set label generator-maximum-real-power-output
      set label-color white
    ]
  ]
  
  ask loads [
    set hidden? false
    set shape "circle"
    set size 1
    set color green
    
    if (show-labels?) [
      set label round load-power-received
      set label-color white
    ]
  ]
  
  ask bus-links [
    set hidden? false
    if (failed? = false) [set color black]
    if (failed? = true) [set color black]
    
    if (show-labels?) [
      set label round link-load
      set label-color black
    ]
  ]

  ask infra2-buses [
    set hidden? true
  ]
  
  ask infra2-bus-links [
    set hidden? true
  ]
  
  ask interdependency-links [
    set hidden? true
  ]
  
  ask component-links [set hidden? false set color black]
  
  repeat 5000 [ layout-spring (turtle-set buses generators loads ) (link-set bus-links component-links) 0.1 0.1 0.3]
  
  
end


to visualize-combined-network
  
  ask patches [
    set pcolor white
  ]
  
  ask buses [
    set hidden? false
    set shape "circle"
    set size 0.5
    set color black
  ]
  
  ask generators [
    set hidden? false
    set shape "circle"
    set size 1
    set color blue
    
    if (show-labels?) [
      set label generator-maximum-real-power-output
      set label-color white
    ]
  ]
  
  ask loads [
    set hidden? false
    set shape "circle"
    set size 1
    set color green
    
    if (show-labels?) [
      set label round load-power-received
      set label-color white
    ]
  ]
  
  ask bus-links [
    set hidden? false
    if (failed? = false) [set color black]
    if (failed? = true) [set color black]
    
    if (show-labels?) [
      set label round link-load
      set label-color black
    ]
  ]

  ask infra2-buses [
    set hidden? false
    set shape "circle"
    set size 0.5
    set color black
  ]
  
  ask infra2-bus-links [
    set hidden? false
    if (failed? = false) [set color grey]
    if (failed? = true) [set color grey]
  ]
  
  ask interdependency-links [
    set hidden? false
    if (failed? = false) [set color black]
    if (failed? = true) [set color black]
    set thickness 0
  ]
  
  ask component-links [set hidden? false set color black]
  
  repeat 5000 [ layout-spring (turtle-set buses generators loads infra2-buses) (link-set bus-links component-links infra2-bus-links interdependency-links) 0.1 0.1 1 ]
  
  
end
@#$#@#$#@
GRAPHICS-WINDOW
325
27
819
542
60
60
4.0
1
10
1
1
1
0
1
1
1
-60
60
-60
60
0
0
1
ticks
30.0

SLIDER
50
67
275
100
number-of-infra2-buses
number-of-infra2-buses
2
200
118
1
1
NIL
HORIZONTAL

CHOOSER
50
210
275
255
case-to-load
case-to-load
"IEEE case 9" "IEEE case 14" "IEEE case 30" "IEEE case 118"
3

SLIDER
49
103
275
136
number-of-infra2-links
number-of-infra2-links
0
200
186
1
1
NIL
HORIZONTAL

SWITCH
407
586
555
619
show-labels?
show-labels?
1
1
-1000

BUTTON
58
25
131
58
NIL
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

BUTTON
135
25
198
58
NIL
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

SWITCH
559
586
775
619
print-power-flow-data?
print-power-flow-data?
1
1
-1000

SLIDER
31
281
299
314
probability-of-infra2-failure-propagation
probability-of-infra2-failure-propagation
0
1
0.1
0.05
1
NIL
HORIZONTAL

SLIDER
32
318
299
351
pareto-scale-parameter
pareto-scale-parameter
0
50
35
1
1
NIL
HORIZONTAL

PLOT
831
30
1331
224
total failed links
NIL
no. links failed
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"failed" 1.0 0 -16777216 true "" "plot count links with [failed? = true]"
"killed" 1.0 0 -7500403 true "" "plot number-of-components-to-fail"

BUTTON
202
26
265
59
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

PLOT
831
228
1331
433
breakdown of failed links
NIL
no. links failed
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"electricity" 1.0 0 -2674135 true "" "plot count bus-links with [failed? = true]"
"infra2" 1.0 0 -13345367 true "" "plot count infra2-bus-links with [failed? = true] + count interdependency-links with [failed? = true]"

CHOOSER
53
373
271
418
adaptation-strategy
adaptation-strategy
0 1 2 3 4
4

PLOT
830
439
1111
643
fraction demand served
NIL
NIL
0.0
10.0
0.0
1.1
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "ifelse (count loads > 0) [plot mean [load-satisfaction] of loads][plot 1]"

PLOT
1116
438
1434
644
line capacity
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "ifelse (count bus-links > 0) [plot mean [link-capacity] of bus-links] [plot 0]"

BUTTON
386
549
603
582
NIL
calculate-and-save-link-capacities
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
38
139
286
172
number-of-interdependencies
number-of-interdependencies
0
100
100
1
1
NIL
HORIZONTAL

BUTTON
607
549
790
582
NIL
test-rserve-connection
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1337
29
1737
223
total adaptation costs
NIL
total costs
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total-adaptation-costs"

SLIDER
38
175
286
208
number-of-known-interdependencies
number-of-known-interdependencies
0
100
25
1
1
NIL
HORIZONTAL

MONITOR
831
649
1005
694
cumulative network resilience
total-resilience
2
1
11

BUTTON
41
458
267
491
NIL
visualize-electricity-network
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
41
495
267
528
NIL
visualize-infra2-network
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
42
532
269
565
NIL
visualize-combined-network
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
34
595
316
700
NOTE: BEFORE RUNNING MODEL, THE RSERVE EXTENSION MUST BE STARTED.  TO DO THIS, OPEN A R SESSION, TYPE \"library(Rserve)\", then \"Rserve()\".
12
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
NetLogo 5.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="TestExperiment" repetitions="2" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>total-adaptation-costs</metric>
    <metric>total-resilience</metric>
    <metric>total-redundant-interdependencies</metric>
    <metric>total-capacity-increase</metric>
    <enumeratedValueSet variable="pareto-scale-parameter">
      <value value="5"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-known-interdependencies">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptation-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-of-infra2-failure-propagation">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-interdependencies">
      <value value="25"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-labels?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-infra2-links">
      <value value="186"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case-to-load">
      <value value="&quot;IEEE case 118&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-infra2-buses">
      <value value="118"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="print-power-flow-data?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="TestExperiment2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>total-adaptation-costs</metric>
    <metric>total-resilience</metric>
    <metric>total-redundant-interdependencies</metric>
    <metric>total-capacity-increase</metric>
    <metric>mean [load-satisfaction] of loads</metric>
    <enumeratedValueSet variable="pareto-scale-parameter">
      <value value="5"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-known-interdependencies">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptation-strategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-of-infra2-failure-propagation">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-interdependencies">
      <value value="25"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-labels?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-infra2-links">
      <value value="186"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case-to-load">
      <value value="&quot;IEEE case 118&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-infra2-buses">
      <value value="118"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="print-power-flow-data?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="FinalExperiment1" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>total-adaptation-costs</metric>
    <metric>total-resilience</metric>
    <metric>total-redundant-interdependencies</metric>
    <metric>total-capacity-increase</metric>
    <metric>mean [load-satisfaction] of loads</metric>
    <enumeratedValueSet variable="pareto-scale-parameter">
      <value value="5"/>
      <value value="20"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-known-interdependencies">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptation-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-of-infra2-failure-propagation">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-interdependencies">
      <value value="25"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-labels?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-infra2-links">
      <value value="186"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case-to-load">
      <value value="&quot;IEEE case 118&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-infra2-buses">
      <value value="118"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="print-power-flow-data?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="FinalExperiment2" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>total-adaptation-costs</metric>
    <metric>total-resilience</metric>
    <metric>total-redundant-interdependencies</metric>
    <metric>total-capacity-increase</metric>
    <metric>mean [load-satisfaction] of loads</metric>
    <enumeratedValueSet variable="pareto-scale-parameter">
      <value value="5"/>
      <value value="20"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-known-interdependencies">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptation-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-of-infra2-failure-propagation">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-interdependencies">
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-labels?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-infra2-links">
      <value value="186"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case-to-load">
      <value value="&quot;IEEE case 118&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-infra2-buses">
      <value value="118"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="print-power-flow-data?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="FinalExperiment3" repetitions="25" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>total-adaptation-costs</metric>
    <metric>total-resilience</metric>
    <metric>total-redundant-interdependencies</metric>
    <metric>total-capacity-increase</metric>
    <metric>mean [load-satisfaction] of loads</metric>
    <enumeratedValueSet variable="pareto-scale-parameter">
      <value value="5"/>
      <value value="20"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-known-interdependencies">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptation-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-of-infra2-failure-propagation">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-interdependencies">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-labels?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-infra2-links">
      <value value="186"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="case-to-load">
      <value value="&quot;IEEE case 118&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-infra2-buses">
      <value value="118"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="print-power-flow-data?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
