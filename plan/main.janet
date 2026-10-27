(defn relation [schema & rows]
  {:schema schema
   :rows rows})

(def users
  (relation
    [:first :last]
    ["Justin" "Jaffray"]
    ["Smudge" "McCann"]))

(defn run [query]
  (match query
    ['scan rel] (rel :rows)
    ['select rel p] (run rel)))

(defn eval-expr [row expr]
  (match expr
    [

(defn scan [rel]
  ~(scan ,rel))

(defn select [rel p]
  ~(select ,rel ,p))

(defn p/= [lhs rhs]
  ~(= ,lhs ,rhs))

(defn p/and [lhs rhs]
  ~(and ,lhs ,rhs))

(pp
  (run
    (select
      (scan users)
      (p/= :first :last))))

