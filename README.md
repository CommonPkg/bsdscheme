# BSDScheme

This is a Scheme interpreter written in D intended to eventually target Scheme R7RS.

## Installation

### Mac

```
$ brew install ldc
$ make
```

## Example

```
$ cat test/exp.scm
(define exp (base pow)
  (if (= pow 0)
      1
      (* base (exp base (- pow 1)))))

(display (exp 3 3))
(newline)
$ ./bin/bsdscheme test/exp.scm
27
```

## Testing

BSDScheme uses the [btest](https://github.com/briansteffens/btest) test framework.