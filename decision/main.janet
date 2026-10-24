(import "./decision" :prefix "")

# Proposer sends prepare to everybody except himself, then waits.

(defn proposer [v]
  (fn [env]
    (def num-receivers (dec (env :node-count)))
    (for epoch 0 100
      (send {:kind :prepare
             :value v
             :epoch epoch})

      # now wait for all the replies
      (def replies @{})
      (while (< (length replies) num-receivers)
        (let [msg (recv)]
          (case ((msg :body) :kind)
            :ack-prepare
            (case ((msg :body) :result)
              :accept (put replies (msg :src) true)
              :reject (put replies (msg :src) false)))))
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
            (let [msg (recv)]
              (case ((msg :body) :kind)
                :ack-abort (++ acks))))
          )))))

(defn receiver []
  (fn [env]
    (var decided false)
    (while (not decided)
      (def msg (recv))
      (match (msg :body)
        {:kind :prepare :value v :epoch epoch}
        (do
          (send {:kind :ack-prepare
                 :result (if (< (math/random) 0.5) :accept :reject)})
          (var aborted false)
          (while (and (not decided) (not aborted))
            (let [next-msg (recv)]
              (case ((next-msg :body) :kind)
                :commit (do
                          (decide [v epoch])
                          (set decided true))
                :abort (do
                         (send {:kind :ack-abort} (next-msg :src))
                         (set aborted true))))))))))

(run
  (proposer :v)
  (receiver)
  (receiver)
  (receiver))
