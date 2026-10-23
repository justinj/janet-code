(use jaylib)

(def window-width 400)
(def window-height 400)

# I'd like to load this from a file on disk, maybe I can just dump/load it
# directly somehow.
(def pomodoro-record
  @[
    {:conclusion-time (os/clock)}
    ])

(set-config-flags :msaa-4x-hint)
(def screen-center [(/ window-width 2) (/ window-height 2)])

(init-window window-width window-height "Pomobaby")
(set-target-fps 60)

(def font
   (load-font-ex "/System/Library/Fonts/Supplemental/Arial.ttf" 20))
(set-texture-filter (get-font-texture font) :bilinear)

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

(while (not (window-should-close))
  (begin-drawing)

  (clear-background [0 0 0])

  (def remaining-seconds (remaining state))

  (when (and (= :running (state :mode)) (<= remaining-seconds 0))
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

  (when (key-pressed? :r)
    (def new-kind (kind/next (state :kind)))
    (set state (state/paused (interval-duration new-kind) new-kind)))

  (def wedge-size (math/ceil (* (/ remaining-seconds (interval-duration (state :kind))) 360)))
  (def color
    (case (state :mode)
      :complete [0.3 0.9 0.3]
      :running [0.9 0.3 0.3]
      :paused [0.7 0.5 0.5]))

  (draw-ring screen-center 50 80 270 (- 270 wedge-size) 40 color)
  (draw-text-centered (remaining-str remaining-seconds) screen-center color)

  (end-drawing))

(unload-font font)
(close-window)
