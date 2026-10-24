(import "./decision" :prefix "")

# Proposer sends prepare to everybody except himself, then waits.

(defn wait-for-all [kind num-receivers]
  (var result @[])
  (while (< (length result) num-receivers)
    (let [msg (recv)]
      (when (= ((msg :body) :kind) kind)
        (array/push result msg))))
  result)

(defn proposer [v]
  (fn [env]
    (def num-receivers (dec (env :node-count)))
    (var decided false)
    (var epoch 0)
    (while (not decided)
      (++ epoch)
      (send {:kind :prepare
             :value v
             :epoch epoch})

      (def replies (wait-for-all :ack-prepare num-receivers))

      (if (all |(= :accept (($ :body) :result)) replies)
        (do
          (send {:kind :commit :epoch epoch})
          (decide v)
          (set decided true))
        (do
          (send {:kind :abort})
          (wait-for-all :ack-abort num-receivers))))))

(defn receiver []
  (fn [env]
    (var decided false)
    (while (not decided)
      (def {:body body} (recv))
      (match body
        {:kind :prepare :value v :epoch epoch}
        (do
          (send {:kind :ack-prepare
                 :result (if (< (math/random) 0.5)
                           :accept
                           :reject)})
          (var aborted false)
          (while (and (not decided) (not aborted))
            (def {:body msg :src src} (recv))

            (case (msg :kind)
              :commit (do
                        (decide v)
                        (set decided true))
              :abort (do
                       (send {:kind :ack-abort} src)
                       (set aborted true)))))))))

(run
  (proposer :v)
  (receiver)
  (receiver)
  (receiver))


