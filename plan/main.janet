(defn relation [schema & rows]
  {:schema schema
   :rows rows})

(def users
  (relation
    [:first :last]
    ["Justin" "Jaffray"]
    ["Smudge" "McCann"]))

(defn scan [rel]
  (rel :rows))

(each user (scan users)
  (pp user))
