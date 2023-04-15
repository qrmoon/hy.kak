# https://hylang.org
# ------------------

# Detection
# ---------

hook global BufCreate .*\.(hy) %{
    set-option buffer filetype hy
}

# Initialization
# --------------

hook global WinSetOption filetype=hy %{
    require-module hy

    set-option window static_words %opt{hy_static_words}

    hook window ModeChange pop:insert:.* -group hy-trim-indent lisp-trim-indent
    hook window InsertChar \n -group hy-indent lisp-indent-on-new-line

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window hy-.+ }
}

hook -group hy-highlight global WinSetOption filetype=hy %{
    add-highlighter window/hy ref hy
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/hy }
}

provide-module hy %§

require-module lisp

# Highlighters
# ------------

add-highlighter shared/hy regions
add-highlighter shared/hy/code default-region group

# Quotes
add-highlighter shared/hy/quote-paren region \
  -recurse "\(" "('|`|~|~@|#\*|#\*\*)\(" "\)" fill variable
add-highlighter shared/hy/quote-square region \
  -recurse "\[" "('|`|~|~@|#\*|#\*\*)\[" "\]" fill variable
add-highlighter shared/hy/quote-bracket region \
  -recurse "\{" "('|`|~|~@|#\*|#\*\*)\{" "\}" fill variable
add-highlighter shared/hy/quote-word region %{('|`|~|~@|#\*|#\*\*)[^()\[\]{};"'`~\s]} \
                                       %{(?=[\s()\[\]{};"'`~\s])} fill variable

# Strings
add-highlighter shared/hy/string region %{[a-z]?"} (?<!\\)(\\\\)*" fill string
# TODO: bracket strings

add-highlighter shared/hy/shebang region "#!" "$" fill comment
add-highlighter shared/hy/comment region ";"  "$" fill comment

# Numeric literals
add-highlighter shared/hy/code/ regex "[+-]?(0[oxb])?[0-9_,]+j?" 0:value
add-highlighter shared/hy/code/ regex "[+-]?(0[oxb])?[0-9_,]*\.[0-9]*j?" 0:value
# add-highlighter shared/hy/code/ regex "(NaN|Inf|\-Inf)" 0:value

add-highlighter shared/hy/code/ regex %{:[^()\[\]{};"'`~\s]*} 0:keyword

add-highlighter shared/hy/code/ regex %{(?<!\()[^()\[\]{};"'`~\s]+} 0:Default

# Keywords
evaluate-commands %sh{
    values="True False None self inf NaN"
    meta="import"

    attributes="__annotations__ __closure__ __code__ __defaults__ __dict__ __doc__ \
                __globals__ __kwdefaults__ __module__ __name__ __qualname__"
    methods="__abs__ __add__ __aenter__ __aexit__ __aiter__ __and__ __anext__ \
             __await__ __bool__ __bytes__ __call__ __complex__ __contains__ \
             __del__ __delattr__ __delete__ __delitem__ __dir__ __divmod__ \
             __enter__ __eq__ __exit__ __float__ __floordiv__ __format__ \
             __ge__ __get__ __getattr__ __getattribute__ __getitem__ \
             __gt__ __hash__ __iadd__ __iand__ __ifloordiv__ __ilshift__ \
             __imatmul__ __imod__ __imul__ __index__ __init__ \
             __init_subclass__ __int__ __invert__ __ior__ __ipow__ \
             __irshift__ __isub__ __iter__ __itruediv__ __ixor__ __le__ \
             __len__ __length_hint__ __lshift__ __lt__ __matmul__ \
             __missing__ __mod__ __mul__ __ne__ __neg__ __new__ __or__ \
             __pos__ __pow__ __radd__ __rand__ __rdivmod__ __repr__ \
             __reversed__ __rfloordiv__ __rlshift__ __rmatmul__ __rmod__ \
             __rmul__ __ror__ __round__ __rpow__ __rrshift__ __rshift__ \
             __rsub__ __rtruediv__ __rxor__ __set__ __setattr__ \
             __setitem__ __set_name__ __slots__ __str__ __sub__ \
             __truediv__ __xor__"

    exceptions="ArithmeticError AssertionError AttributeError BaseException BlockingIOError \
                BrokenPipeError BufferError BytesWarning ChildProcessError \
                ConnectionAbortedError ConnectionError ConnectionRefusedError \
                ConnectionResetError DeprecationWarning EOFError Exception \
                FileExistsError FileNotFoundError FloatingPointError FutureWarning \
                GeneratorExit ImportError ImportWarning IndentationError \
                IndexError InterruptedError IsADirectoryError KeyboardInterrupt \
                KeyError LookupError MemoryError ModuleNotFoundError NameError \
                NotADirectoryError NotImplementedError OSError OverflowError \
                PendingDeprecationWarning PermissionError ProcessLookupError \
                RecursionError ReferenceError ResourceWarning RuntimeError \
                RuntimeWarning StopAsyncIteration StopIteration SyntaxError \
                SyntaxWarning SystemError SystemExit TabError TimeoutError TypeError \
                UnboundLocalError UnicodeDecodeError UnicodeEncodeError UnicodeError \
                UnicodeTranslateError UnicodeWarning UserWarning ValueError Warning \
                ZeroDivisionError"
    keywords="and as assert async await break chainc class cond continue cut def defclass defn del \
              dfor do elif else eval-and-compile eval-when-compile except exec finally for get gfor \
              global if in is lambda let lfor match nonlocal not not? not-in or pass print py \
              pys quasiquote quote raise require return setv setx sfor try unpack-iterable \
              unpack-mapping unquote unquote-splice while with with/a yield yield-from"

    types="bool buffer bytearray bytes complex dict file float frozenset int \
           list long memoryview object set str tuple unicode xrange"

    functions="abs all any ascii bin breakpoint callable chr classmethod compile complex \
               delattr dict dir divmod enumerate eval exec filter \
               format frozenset getattr globals hasattr hash help \
               hex id __import__ input isinstance issubclass iter \
               len locals map max memoryview min next oct open ord \
               pow print property range repr reversed round \
               setattr slice sorted staticmethod sum super type vars zip"

    words="$values $meta $attributes $methods $exceptions $keywords $types $functions"
    printf "%s\n" "declare-option str-list hy_static_words $words)"

    printf "%s\n" "
        add-highlighter shared/hy/code/ regex '\b($(echo $values | tr ' ' '|'))\b' 0:value
        add-highlighter shared/hy/code/ regex '\b($(echo $meta | tr ' ' '|'))\b' 0:meta
        add-highlighter shared/hy/code/ regex '\b($(echo $attributes | tr ' ' '|'))\b' 0:attribute
        add-highlighter shared/hy/code/ regex '\b($(echo $methods | tr ' ' '|'))\b' 0:function
        add-highlighter shared/hy/code/ regex '\b($(echo $exceptions | tr ' ' '|'))\b' 0:function
        add-highlighter shared/hy/code/ regex '\b($(echo $keywords | tr ' ' '|'))\b' 0:keyword
        add-highlighter shared/hy/code/ regex '\b($(echo $functions | tr ' ' '|'))\b' 0:builtin
        add-highlighter shared/hy/code/ regex '\b($(echo $types | tr ' ' '|'))\b' 0:type
    "
}

§
