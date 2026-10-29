(def id
  [1 0 0
   0 1 0])

(defn mul
  [[x11 x21 x31
    x12 x22 x32]
   [y11 y21 y31
    y12 y22 y32]]
  [(+ (* x11 y11) (* x21 y12))
   (+ (* x11 y21) (* x21 y22))
   (+ (* x11 y31) (* x21 y32) x31)
   (+ (* x12 y11) (* x22 y12))
   (+ (* x12 y21) (* x22 y22))
   (+ (* x12 y31) (* x22 y32) x32)])

(defn transform
  [[x11 x21 tx
    x12 x22 ty]
   [x y]]
  [(+ (* x x11) (* y x21) tx)
   (+ (* x x12) (* y x22) ty)])

(defn translate [x y]
  [1 0 x
   0 1 y])

(defn scale [s]
  [s 0 0
   0 s 0])

(defn rotate [theta]
  [(math/cos theta) (- (math/sin theta)) 0
   (math/sin theta) (math/cos theta)     0])
