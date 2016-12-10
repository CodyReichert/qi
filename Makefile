.PHONY: t

t:
	sbcl --noinform --non-interactive \
	     --load init.lisp \
	     --eval "(asdf:load-system :prove)" \
	     --eval "(prove:run :qi-test)"
