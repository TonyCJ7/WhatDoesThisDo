(ns core)

(println (+ cljlimit (cljattempt 1)) (->CljConfig 1))

(def cljlimit 3)

(defn cljattempt [n] n)

(defrecord CljConfig [n])
