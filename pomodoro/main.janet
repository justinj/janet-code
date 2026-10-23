(use jaylib)

(def window-width 400)
(def window-height 400)

(def screen-center [(/ window-width 2) (/ window-height 2)])

(init-window 400 400 "Pomobaby")
(set-target-fps 60)
(hide-cursor)

(def start (os/clock))
(defn elapsed [] (- (os/clock) start))
(def pomodoro-time (* 60 1))

(while (not (window-should-close))
  (begin-drawing)

  (clear-background [0 0 0])

  (let [[x y] (get-mouse-position)]
    # (draw-circle-gradient (math/floor x) (math/floor y) (/ x 10) :lime :red)
    (draw-ring
      screen-center
      30.0 # inner radius
      50.0 # outer radius
      0.0 # start angle 
      (math/floor (* (/ (elapsed) pomodoro-time) 360)) # end angle
      40 # segments
      :red)

    # (draw-poly [500 200] 5 40 0 :magenta)
    # (draw-line-bezier
    #   [(- x 100) y]
    #   [(+ x 100) (+ y 50)]
    #   4 :pink)
    # (draw-line-ex
    #   [x (- y 10)]
    #   [x (+ y 10)]
    #   4 :sky-blue)
    # (draw-line-strip
    #   [[x 0] [x 100] [50 y] [10 180]]
    #   :ray-white)
    )

  (end-drawing))

(close-window)
