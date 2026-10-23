(use jaylib)

(def window-width 400)
(def window-height 400)

(set-config-flags :msaa-4x-hint)
(def screen-center [(/ window-width 2) (/ window-height 2)])

(init-window 400 400 "Pomobaby")
(set-target-fps 60)

(def font
   (load-font-ex "/System/Library/Fonts/Supplemental/Arial.ttf" 32))
(set-texture-filter (get-font-texture font) :bilinear)

# The total time, in seconds.
(def pomodoro-time (* 60 0.5))

(defn state/paused [remaining]
  {:mode :paused
    :remaining remaining})

(defn state/running [consumed started-at]
  {:mode :running
    :consumed consumed
    :started-at started-at})

(def state/initial (state/paused pomodoro-time))

(var state state/initial)

(var start (os/clock))
(defn remaining [state]
  (case (state :mode)
    :paused (state :remaining)
    :running (- pomodoro-time
                (+ (state :consumed) (- (os/clock) (state :started-at))))))

(defn remaining-str [state]
  (def rem (math/ceil (remaining state)))
  (def rem-seconds (mod rem 60))
  (def rem-minutes (div rem 60))
  (string/format "%02d:%02d" rem-minutes rem-seconds))

(def text-size 20)
(defn draw-text-centered [text [x y] color]
  (let [[w h] (measure-text-ex font text text-size 1)]
    (draw-text-ex font text [(- x (/ w 2)) (- y (/ h 2))] text-size 1 color)))

(while (not (window-should-close))
  (begin-drawing)

  (clear-background [0 0 0])

  (when (key-pressed? :space)
    (case (state :mode)
      :paused (set state (state/running (- pomodoro-time (state :remaining)) (os/clock)))
      :running (set state (state/paused (remaining state)))))

  (when (key-pressed? :r)
    (set state state/initial))

  (def wedge-size (math/ceil (* (/ (remaining state) pomodoro-time) 360)))
  (def color
    (case (state :mode)
      :running [0.9 0.3 0.3]
      :paused [0.7 0.5 0.5]))

  (draw-ring screen-center 30.0 50.0 270 (- 270 wedge-size) 40 color)
  (draw-text-centered (remaining-str state) screen-center color)

  (end-drawing))

(unload-font font)
(close-window)
