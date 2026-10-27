(use jaylib)

(def window-width 400)
(def window-height 400)

(os/setenv "TZ" "America/New_York")

(pp (os/date (os/time) true))

(def pomodoro-record
  (parse (try (slurp "data.jdn") ([_] "@[]"))))

(defn sync []
  (spit "data.jdn" (string/format "%j" pomodoro-record)))

(defn days-in-year [year]
  (cond
    (zero? (mod year 100)) 365
    (zero? (mod year 4)) 366
    365))

(defn day-epoch [time]
  (let [parsed (os/date time true)]
    (+ (days-in-year (parsed :year))
       (parsed :year-day))))

(defn days-ago [time]
  (- (day-epoch (os/time))
     (day-epoch time)))

(defn record-pomodoro [time]
  (array/push pomodoro-record {:completion-time time})
  (sync))

(set-config-flags :msaa-4x-hint)
(def screen-center [(/ window-width 2) (/ window-height 2)])

(init-window window-width window-height "Pomobaby")
(set-target-fps 60)

(def font
   (load-font-ex "/System/Library/Fonts/Supplemental/Arial.ttf" 20))
(set-texture-filter (get-font-texture font) :bilinear)

(defn inner-radius [squeezed]
  (if squeezed 40 50))

(defn interval-duration [kind]
  (case kind
    :pomodoro (* 60 25)
    :cooldown (* 60 5)))

(defn kind/next [kind]
  (case kind
    :pomodoro :cooldown
    :cooldown :pomodoro))

(defn state/paused [remaining kind]
  {:mode :paused
   :remaining remaining
   :kind kind})

(defn state/running [consumed started-at kind]
  {:mode :running
   :consumed consumed
   :started-at started-at
   :kind kind})

(defn state/complete [kind]
  {:mode :complete
   :kind kind})

(def state/initial (state/paused (interval-duration :pomodoro) :pomodoro))
(var state state/initial)

(var rendered-inner-radius (inner-radius false))

(defn remaining [state]
  (case (state :mode)
    :complete 0
    :paused (state :remaining)
    :running (- (interval-duration (state :kind))
                (+ (state :consumed) (- (os/clock) (state :started-at))))))

(defn remaining-str [rem]
  (def rem-sec (math/ceil rem))
  (def rem-seconds (mod rem-sec 60))
  (def rem-minutes (div rem-sec 60))
  (string/format "%02d:%02d" rem-minutes rem-seconds))

(def text-size 20)
(defn draw-text-centered [text [x y] color]
  (let [[w h] (measure-text-ex font text text-size 1)]
    (draw-text-ex font text [(- x (/ w 2)) (- y (/ h 2))] text-size 1 color)))

# Draw the small circles that correspond to individual completions.
(def completion-rad 5)
(def completion-diam (* 2 completion-rad))
(def completion-pad 2)

(defn draw-completions []
  (def completions
    (map
      (fn [[k v]] {:days-ago k :count (length v)})
      (pairs
        (group-by |(days-ago ($ :completion-time)) pomodoro-record))))

  (each {:days-ago days-ago :count cnt} completions
    (for i 0 cnt
      (draw-circle
        (+ completion-pad completion-rad (* (+ completion-diam completion-pad) i))
        (+ completion-pad completion-rad (* (+ completion-diam completion-pad) days-ago))
        completion-rad
        [0.6 0.3 0.3]))))

(while (not (window-should-close))
  (begin-drawing)

  (clear-background [0 0 0])

  (def remaining-seconds (remaining state))

  (when (and (= :running (state :mode)) (<= remaining-seconds 0))
    (when (= (state :kind) :pomodoro)
      (record-pomodoro (os/time)))
    (set state (state/complete (kind/next (state :kind)))))

  (when (key-pressed? :space)
    (match state
      {:mode :complete
       :kind kind}
      (set state
           (state/paused (interval-duration kind) kind))
      {:mode :paused
       :kind kind
       :remaining remaining}
      (set state
           (state/running
             (- (interval-duration kind) remaining)
             (os/clock) kind))
      {:mode :running :kind kind} 
        (set state (state/paused (remaining state) kind))))

  (when (key-pressed? :a)
    (record-pomodoro (os/time)))

  (when (key-pressed? :r)
    (def new-kind (kind/next (state :kind)))
    (set state (state/paused (interval-duration new-kind) new-kind)))

  (def wedge-size (math/ceil (* (/ remaining-seconds (interval-duration (state :kind))) 360)))
  (def color
    (case (state :mode)
      :complete [0.3 0.9 0.3]
      :running [0.9 0.3 0.3]
      :paused [0.7 0.5 0.5]))

  (def squeezed (key-down? :space))
  (def inner (inner-radius squeezed))

  (set rendered-inner-radius
       (/ (+ rendered-inner-radius inner) 2))

  (def annulus-width 30)

  (draw-completions)

  (draw-ring
    screen-center
    rendered-inner-radius
    (+ rendered-inner-radius annulus-width)
    270
    (- 270 wedge-size)
    40
    color)
  (draw-text-centered (remaining-str remaining-seconds) screen-center color)

  (def annulus-middle 
    (+ rendered-inner-radius (/ annulus-width 2)))

  (draw-circle
    (math/floor (screen-center 0))
    (math/floor (- (screen-center 1) annulus-middle))
    (/ annulus-width 2)
    color)


  (def wedge-angle
    (-> wedge-size
        -
        (/ 360)
        (* (* 2 math/pi))))
  (def cx (-> wedge-angle
              (- (/ math/pi 2))
              math/cos
              (* annulus-middle)
              (+ (screen-center 0))))
  (def cy (-> wedge-angle
              (- (/ math/pi 2))
              math/sin
              (* annulus-middle)
              (+ (screen-center 1))))

  (draw-circle
    (math/floor cx)
    (math/floor cy)
    (/ annulus-width 2)
    color)


  (end-drawing))

(unload-font font)
(close-window)
