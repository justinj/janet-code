# https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner.Compiler/Grammars/YarnSpinnerParser.g4

(def kv
  ~(sequence
     (<- (some :w))
     ":"
     (any :s)
     (<- (to "\n"))))

(def kvs
  ~(some
     (/
      (sequence ,kv "\n")
      ,(fn [k v] {:key k :value v}))))

(def text
  ~(some
     (+ :w " " "<" ">" ":" "!")))

(def line
  ~(sequence
     (<- (some ,text))
     "\n"))

(def body
  ~(sequence
     (group (some ,line))))

(pp
  (peg/match body "foo\nbar\nbaz\n===\n"))

(def node
  ~(sequence
     (group ,kvs)
     "---\n"
     ,body
     "==="))

(pp (peg/match node "title: one\nnext: two\n---\nhello\n===\n"))

(def nodes ~(some (/ (sequence ,node :s+)
                     ,(fn [kvs lines] {:kvs kvs :lines body}))))

(pp (peg/match nodes (slurp "test.Yarn")))
