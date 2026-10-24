(def rng (math/rng (os/cryptorand 16)))

# not entirely sure this is correct lol
(defn shuffle [ary]
  (for i 0 (length ary)
    (let [j (+ i (math/rng-int rng (- (length ary) i)))]
      (def a (ary i))
      (def b (ary j))
      (put ary i b)
      (put ary j a)))
  ary)

(defn run [& thunks]
  (var decisions @[])
  (var next-actor-id 1)

  (def actors
    (map
      (fn [[i thunk]]
        (def env {:node-count (length thunks)
                  :me i})
        (let [fiber (fiber/new |(thunk env))]
          (fiber/setenv fiber @{:actor-id i
                                :decisions decisions})
          @{:fiber fiber
            :actor-id i
            :inbox @[]
            :state :idle}))
      (pairs thunks)))

  (while (some |(not= ($ :state) :complete) actors)
    (when (all |(and (= ($ :state) :recv)
                     (empty? ($ :inbox))) actors)
      (error "Deadlock! All actors waiting."))

    (each actor actors
      (let [fiber (actor :fiber)]
        (var ran false)

        (case (actor :state)
          :idle (do (resume fiber)
                  (set ran true))
          :recv
          # if there's a message to be received, receive it. otherwise, skip
          # this fiber.
          (let [inbox (actor :inbox)]
            (when (> (length inbox) 0)
              # we can do like swap-take to make this O(1)
              (shuffle (actor :inbox))
              (def msg (array/pop (actor :inbox)))
              (resume fiber msg)
              (set ran true))))

        (when (= :dead (fiber/status fiber))
          (put actor :state :complete))

        (when ran
          (match (fiber/last-value fiber)
            {:type :send :value v :dest dest} 
            (do
              (array/push ((actors dest) :inbox)
                          {:src (actor :actor-id) :body v})
              (put actor :state :idle))
            {:type :send :value v} 
            (do
              (each recipient actors
                (unless (= recipient actor)
                  (array/push (recipient :inbox) {:src (actor :actor-id) :body v})))
              (put actor :state :idle))
            {:type recv} (put actor :state :recv)))))))

(defn recv []
  (yield {:type :recv}))

# send broadcasts a message to every node.
(defn send [v &opt dest]
  (let [actor-id (dyn :actor-id)]
    (yield {:type :send :value v :src actor-id :dest dest})))

(defn decide [v]
  (let [actor-id (dyn :actor-id)]
    (printf "Actor %d decided %j" actor-id v)
    (array/push (dyn :decisions) {:actor actor-id :decision v})))
