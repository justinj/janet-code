(import spork/json)

(defn chunk-string [str]
  (var unread true)
  (fn [buf _]
    (when unread
      (set unread false)
      (buffer/blit buf str))))

(defn evaluate [code env]
  (var result nil)
  (run-context
    {:env env
     :chunks (chunk-string code)
     :on-status
     (fn [fiber value]
       (set result value)
       (comment printf "> %q (%q)" value (fiber/status fiber)))})
  result)

(defn handle [input env]
  (let [decoded (json/decode input)
        {"code" code} decoded]
    (pp (evaluate code env))
    ))

(defn main [&]
  (def env (make-env root-env))
  (each msg [(json/encode {:code "(defn foo [a b] (+ a b))"})
             (json/encode {:code "(foo 8 1)"})]
    (handle msg env)))
