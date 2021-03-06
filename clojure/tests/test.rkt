#lang clojure

(require rackunit
         racket/list
         racket/stream
         (only-in racket/match (== =:)))

(prn [1 2 3])
(check-true (vector? [1 2 3]))
(check-true (vector? '[1 2 3]))
(check-true (immutable? [1 2 3]))
(check-true (immutable? '[1 2 3]))
(check-true (immutable? (vector 1 2 3)))
(check-equal? [1,2,3] [1 2 3])
(check-equal? [1 2 (+ 1 2)] [1 2 3])
(check-equal? '[1 2 (+ 1 2)] [1 2 '(+ 1 2)])
(check-equal? [1 2 [3]] (vector 1 2 (vector 3)))

(prn {:a 5 :b 7})
(prn {:a 5, :b 7})
(check-equal? {:a 5 :b 7} (hash-map :a 5 :b 7))
(check-pred map? {:a 5 :b 7})
(check-pred map? '{:a 5 :b 7})
(check-equal? '{:a 5 :b 7} {:a 5 :b 7})
(check-equal? #{:a 1 :b (+ 1 2)} #{:a 1 :b 3})
(check-equal? '#{:a 1 :b (+ 1 2)} #{:a 1 :b '(+ 1 2)})

(check-pred char? \a)

(check-pred set? #{1 2 3})
(check-pred set? '#{1 2 3})
(check-equal? #{1 2 3} (hash-set 1 2 3))
(check-equal? '#{1 2 3} (hash-set 1 2 3))
(check-equal? #{1 2 (+ 1 2)} #{1 2 3})
(check-equal? '#{1 2 (+ 1 2)} #{1 2 '(+ 1 2)})
(check-equal? #{1 2 #{3}} (hash-set 1 2 (hash-set 3)))

(def foo 3)
foo

(do 3 5)

(let [x 3 y 5]
  (+ x y))

((fn this [x y] (+ x y)) 5 5)
((fn [x y] (+ x y)) 5 5)
((fn [x] (if (zero? x) 1 (* x (recur (- x 1))))) 5)
((fn ([x] (if (zero? x) 1 (* x (recur (- x 1)))))
     ([x y] (+ (recur x) (recur y))))
 3 2)

(loop [x 3 y 5]
  (+ x y))

;; TODO: make `nil` reader syntax
(check-equal? (if #f 5) nil)

(check-equal?
 (loop [x 5 n 1]
   (if (zero? x)
       n
       (recur (- x 1) (* x n))))
 120)

(defn fact [x]
  (loop [x x n 1]
    (if (zero? x)
        n
        (recur (- x 1) (* x n)))))

(check-equal? (fact 5) 120)

(check-equal? (loop [x 1 y x] y) 1)

;; thrush operators
(require (only-in racket/string string-split string-replace))
(check-equal?
 (-> "a b c d"
     string-upcase
     (string-replace "A" "X")
     (string-split " ")
     car)
 "X")

(check-equal?
 (->> 5 (+ 3) (/ 2) (- 1))
 (/ 3 4))

(check-equal?
  (->> 1 ((fn [x] (+ x 1))))
  2)

;; quote behavior
(check-equal? (quote a b c d) (quote a))
(check-equal? (quote 5 a) 5)
(check-equal? (-> 5 'a) 5)

(check-equal? `(~(+ 1 2)) '(3))

;; boolean and not
(check-equal? (boolean true) true)
(check-equal? (boolean false) false)
(check-equal? (boolean nil) false)
(check-equal? (boolean "a string") true)
(check-equal? (boolean 0) true)
(check-equal? (boolean 1) true)
(check-equal? (not true) false)
(check-equal? (not false) true)
(check-equal? (not nil) true)
(check-equal? (not "a string") false)
(check-equal? (not 0) false)
(check-equal? (not 1) false)
(check-equal? (for/hash ((v (in-vector [true false nil [] {} '() #{} ""])))
                (values v (boolean v)))
              {true true, false false, nil false, [] true, {} true, '() true, #{} true, "" true})

;; if tests based on a post by Jay Fields
(check-equal? "yes" (if true "yes"))
(check-equal? "yes" (if true "yes" "no"))
(check-equal? "no" (if false "yes" "no"))
(check-equal? "no" (if nil "yes" "no"))
(check-equal? "still true" (if -1 "still true" "false"))
(check-equal? "still true" (if 0 "still true" "false"))
(check-equal? "still true" (if [] "still true" "false"))
(check-equal? "still true" (if (list) "still true" "false"))

;; cond tests
(defn factorial [n]
  (cond
   (<= n 1) 1
   :else (* n (factorial (dec n)))))
(check-equal? 120 (factorial 5))

(check-equal? "B" (let [grade 85]
                    (cond
                     (>= grade 90) "A"
                     (>= grade 80) "B"
                     (>= grade 70) "C"
                     (>= grade 60) "D"
                     :else "F")))

(defn pos-neg-or-zero [n]
  (cond
   (< n 0) "negative"
   (> n 0) "positive"
   :else "zero"))
(check-equal? "positive" (pos-neg-or-zero 5))
(check-equal? "negative" (pos-neg-or-zero -1))
(check-equal? "zero" (pos-neg-or-zero 0))

(check-equal? (cond) nil)
(check-equal? (cond false 5) nil)

(check-equal? (nth ["a" "b" "c" "d"] 0) "a")
(check-equal? (nth (list "a" "b" "c" "d") 0) "a")
(check-equal? (nth ["a" "b" "c" "d"] 1) "b")
(check-equal? (nth [] 0 "nothing found") "nothing found")
(check-equal? (nth [0 1 2] 77 1337) 1337)
(check-equal? (nth "Hello" 0) #\H)
(check-equal? (nth '(1 2 3) 0) 1)

(check-equal? (zipmap [:a :b :c :d :e] [1 2 3 4 5])
              {:a 1, :b 2, :c 3, :d 4, :e 5})
(check-equal? (zipmap [:a :b :c] [1 2 3 4])
              {:a 1, :b 2, :c 3})
(check-equal? (zipmap [:a :b :c] [1 2])
              {:a 1, :b 2})

(check-equal? (get {:a 1 :b 2} :a) 1)
(check-match (keys {:a 1 :b 2}) (or (=: '(:a :b)) (=: '(:b :a))))
(check-match (vals {:a 1 :b 2}) (or (=: '(1 2)) (=: '(2 1))))
(let [m {:a 1 :b 2}]
  (check-equal? (zipmap (keys m) (vals m)) m))
(check-equal? (assoc {:a 1 :b 2} :c 3) {:a 1 :b 2 :c 3})
(check-equal? (dissoc {:a 1 :b 2} :b) {:a 1})

(check-equal? (disj #{:a :b} :a) #{:b})

(check-true (= {:a [1 2 3] :b #{:x :y} :c {:foo 1 :bar 2}}
               {:a [1 2 3] :b #{:y :x} :c {:bar 2 :foo 1}}))
(check-false (= 4 4.0))
(check-true (== 4 4.0))

(check-equal? (str) "")
(check-equal? (str "some string") "some string")
(check-equal? (str nil) "")
(check-equal? (str 1) "1")
(check-equal? (str 1 2 3) "123")
(check-equal? (str 1 'symbol :keyword) "1symbol:keyword")
(check-equal? (apply str '(1 2 3)) "123")
(check-equal? (str [1 2 3]) "[1 2 3]")
(check-pred immutable? (str "I" " should be " "immutable"))

(check-equal? (+ 1 2 #_(this is ignored)) 3)

(check-equal? (pr-str) "")
(check-equal? (pr-str "foo") "\"foo\"")
(check-equal? (pr-str '()) "()")
(check-equal? (pr-str []) "[]")
(check-equal? (pr-str {}) "{}")
(check-match (pr-str {:foo "hello" :bar 34.5})
             (or "{:foo \"hello\" :bar 34.5}"
                 "{:foo \"hello\", :bar 34.5}"
                 "{:bar 34.5 :foo \"hello\"}"
                 "{:bar 34.5, :foo \"hello\"}"))
(check-match (pr-str #{1 2 3})
             (or "#{1 2 3}" "#{1 3 2}"
                 "#{2 1 3}" "#{2 3 1}"
                 "#{3 1 2}" "#{3 2 1}"))
(check-equal? (pr-str ['a :b "\n" \space "c"]) "[a :b \"\\n\" \\space \"c\"]")
(check-equal? (pr-str [1 2 3 4 5]) "[1 2 3 4 5]")
(check-equal? (pr-str '(a b foo :bar)) "(a b foo :bar)")
(check-equal? (pr-str 1 2) "1 2")

(check-equal? (stream->list (map #(* 2 %) (range 0 10)))
              '(0 2 4 6 8 10 12 14 16 18))
(check-equal? (#(+ %1 %2 %3) 1 2 3)
              6)
(check-equal? (#(apply list* % %&) 1 '(2 3))
              '(1 2 3))
(check-equal? (let [lambda "not lambda" define-syntax "not define-syntax"]
                (#(do %) 3))
              3)

