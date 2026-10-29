(import "./matrix")

(defn new []
  @[matrix/id])
(defdyn *stack*)
(setdyn *stack* (new))

(defn- apply-mat [stack mat]
  (array/push
    stack
    (matrix/mul mat (array/pop stack))))

(defn push []
  (array/push
    (dyn *stack*)
    (last (dyn *stack*))))

(defn pop []
  (array/pop
    (dyn *stack*)))

(defn translate [x y]
  (apply-mat
    (dyn *stack*)
    (matrix/translate x y)))

(defn scale [s]
  (apply-mat
    (dyn *stack*)
    (matrix/scale s)))

(defn rotate [theta]
  (apply-mat
    (dyn *stack*)
    (matrix/rotate theta)))

(defn point [x y]
  (matrix/transform (last (dyn *stack*))
             [x y]))


# (translate 1 0)
# (scale 2)
# (rotate math/pi)
#
# (pp
#   (point 1 0))
