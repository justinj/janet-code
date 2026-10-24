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
        (case (actor :state)
          :idle (resume fiber)
          :recv
          # if there's a message to be received, receive it. otherwise, skip
          # this fiber.
          (let [inbox (actor :inbox)]
            (when (> (length inbox) 0)
              # we can do like swap-take to make this O(1)
              (shuffle (actor :inbox))
              (def msg (array/pop (actor :inbox)))
              (resume fiber msg))))
        (when (= :dead (fiber/status fiber))
          (put actor :state :complete))
        (match (fiber/last-value fiber)
          {:type :send :value v} 
          (do
            (each recipient actors
              (unless (= recipient actor)
                (array/push (recipient :inbox) {:sender (actor :actor-id) :body v})))
            (put actor :state :idle))
          {:type recv} (put actor :state :recv))))))

(defn recv []
  (yield {:type :recv}))

# send broadcasts a message to every node.
(defn send [v]
  (yield {:type :send :value v}))

(defn decide [v]
  (let [actor-id (dyn :actor-id)]
    (printf "Actor %d decided %j" actor-id v)
    (array/push (dyn :decisions) {:actor actor-id :decision v})))

(defn proposer [v]
  (fn [env]
    (def num-receivers (dec (env :node-count)))
    (var epoch 0)
    (while true
      (++ epoch)
      (send {:kind :prepare
             :value v
             :epoch epoch})

      # now wait for all the replies
      (def replies @{})
      (while (< (length replies) num-receivers)
        (let [msg (recv)]
          (case ((msg :body) :kind)
            :accept (put replies (msg :sender) true)
            :reject (put replies (msg :sender) false))))
      (if (all |$ replies)
        (do
          (send {:kind :commit
                 :epoch epoch})
          (decide v)
          (break))
        # Someone rejected, tell them all to abort.
        (do
          (send {:kind :abort})
          # Now wait for everyone to acknowledge my abort.
          (var acks 0)
          (while (< acks num-receivers)
            (case (((recv) :body) :kind)
              :ack-abort (++ acks))))))))

(defn receiver []
  (fn [env]
    (var decided false)
    (while (not decided)
      (let [msg (recv)]
        (match (msg :body)
          {:kind :prepare :value v :epoch epoch}
          (do
            (if (< (math/random) 0.5)
              (send {:kind :accept})
              (send {:kind :reject}))
            (while (not decided)
              (let [next-msg (recv)]
                (case ((next-msg :body) :kind)
                  :commit (do
                            (decide [v epoch])
                            (set decided true))
                  :abort (do
                           (send {:kind :ack-abort})
                           (break)))))))))))

(run
  (proposer :v)
  (receiver)
  (receiver)
  (receiver))
