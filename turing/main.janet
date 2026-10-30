(defn machine/new [rules]
  @{:cells @{0 0}
    :state :a
    :head 0
    :min 0
    :max 0
    :rules rules})

(defn machine/set [machine cell value]
  (put (machine :cells) cell value)
  (when (< cell (machine :min))
    (put machine :min cell))
  (when (> cell (machine :max))
    (put machine :max cell)))

(defn machine/move-head [machine direction]
  (case direction
    :left (put machine :head (dec (machine :head)))
    :right (put machine :head (inc (machine :head))))
  (put machine :min (min (machine :head) (machine :min)))
  (put machine :max (max (machine :head) (machine :max))))

(defn machine/step [machine]
  (let [{:rules rules
         :head head
         :cells cells
         :state state} machine
        cell-value (or (cells head) 0)
        rule (rules state)
        [write dir new-state] (rule cell-value)]
    (if (= new-state :halt)
      false
      (do
        (machine/set machine head write)
        (machine/move-head machine dir)
        (put machine :state new-state)
        true))))

(defn machine/str [machine]
  (let [lo (machine :min)
        hi (machine :max)]
    (do
      (def out (buffer))
      (loop [i :range [lo (inc hi)]]
        (if (= i (machine :head))
          (buffer/push out (string/format " %s " (machine :state)))
          (buffer/push out "   ")))
      (buffer/push out "\n")
      (loop [i :range [lo (inc hi)]]
        (buffer/push out
                     (string/format "[%d]"
                                    (or ((machine :cells) i) 0))))
      out)))

(def t
  (machine/new
    {:a [[1 :right :b] [1 :left :b]]
     :b [[1 :left :a] [0 :left :c]]
     :c [[1 :right :halt] [1 :left :d]]
     :d [[1 :right :d] [0 :right :a]]}))

(var steps 1)
(print (machine/str t))
(while (machine/step t)
  (++ steps)
  (print (machine/str t)))

(printf "halted after %d steps" steps)
