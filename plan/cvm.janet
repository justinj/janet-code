(def rng (math/rng (os/cryptorand 32)))
(def thresh 100)

(defn cvm/new []
  @{:weight 0 :elems @{}})

(defn cvm/add [sketch v]
  (let [{:elems elems :weight weight} sketch]
    (put elems v nil)
    (when (< (math/rng-uniform rng) (math/pow 0.5 weight))
      (put elems v true)
      (while (= thresh (length elems))
        (put sketch :weight (inc weight))
        (def new-elems @{})
        (eachk k elems
          (def rand (math/rng-uniform rng))
          (when (< rand 0.5)
            (put new-elems k true)))
        (put sketch :elems new-elems))))
  sketch)

(defn cvm/count [sketch]
  (let [{:weight weight :elems elems} sketch]
    (* (math/pow 2 weight)
       (length elems))))
