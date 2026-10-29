(import "./stack")

(defdyn *stack*)
(setdyn *stack* (stack/new))

(def image {:forms @[] :width 400 :height 400})

(defn line [[x1 y1] [x2 y2]]
  (let [a (stack/point x1 y1)
        b (stack/point x2 y2)]
    (array/push
      (image :forms)
      {:kind :line
       :from a :to b
       :stroke :black})))

(defn write-xml [f m]
  (file/write f "<")
  (file/write f (string (m :tag)) " ")
  (each [key val] (m :properties)
    (file/write f (string/format "%s=%q " key (string val))))
  (when-let [stroke (m :stroke)]
    (file/write f (string/format "stroke=%q " stroke)))
  (file/write f "/>\n"))

(defn write-form [f form]
  (match form
    {:kind :line
     :from [x1 y1] :to [x2 y2]}
    (write-xml
      f
      {:tag :line
       :properties [[:x1 x2] [:y1 y1] [:x2 x2] [:y2 y2]]
       :stroke (form :stroke)})))

(defn flush-image [dest]
  (let [{:forms forms
         :width width
         :height height}
        image]
  (with [f (file/open dest :w)]
    (file/write f
      (string/format "<svg width=\"%d\" height=\"%d\" xmlns=\"http://www.w3.org/2000/svg\">\n" width height))
    (each form (image :forms)
      (write-form f form))
    (file/write f
      (string/format "</svg>\n" width height)))))

(stack/scale 2)
(stack/translate 100 0)
(line [10 10] [20 30])

(flush-image "out.svg")

(pp image)
