" daily achievement "{{{1

" Last Update: Nov 20, Thu | 22:30:07 | 2014

"TODO "{{{2

" decouple key-mappings with functions
" define buffer local commands and key-mappings

 "}}}2
" variables "{{{2

let s:Today = '^\d\{1,2} 月 \d\{1,2} 日'
let s:Today .= ' {\{3}\d$'

let s:Buffer = '^缓冲区 {\{3}\d$'

let s:Count = '\(\d\{1,2}\)\(\.\)'
let s:Time = '\(\d\{2,3}\)'

let s:Progress = s:Count
let s:Progress .= s:Time
let s:Progress .= '$'

let s:Bullet_Pre = '    \*'
let s:Bullet_Post = '    \~'
let s:Bullet_OR = '\(' . s:Bullet_Pre . '\)\|\('
let s:Bullet_OR .=  s:Bullet_Post . '\)'

let s:Mark = '###LONG_PLACEHOLDER_FOR_ACHIEVE_###'

 "}}}2
" functions "{{{2

" <f1> "{{{3

" undone (*) and done (~)

function s:Finished() "{{{4

    if substitute(getline('.'),
    \ s:Bullet_Pre,'','') != getline('.')

        execute 's/^' . s:Bullet_Pre . '/' .
        \ s:Bullet_Post . '/'

    elseif substitute(getline('.'),
    \ s:Bullet_Post,'','') != getline('.')

        execute 's/^' . s:Bullet_Post . '/' .
        \ s:Bullet_Pre . '/'

    endif

endfunction "}}}4

function s:F1() "{{{4

    nnoremap <buffer> <silent> <f1>
    \ :call <sid>Finished()<cr>

endfunction "}}}4

 "}}}3
" <f2> "{{{3

function s:AnotherDay() "{{{4

    let l:cursor = getpos('.')

    " check fold head

    if substitute(getline('.'),
    \'{\{3}\d\{0,2}$','','') != getline('.')

        +1

    endif

    execute 'normal [z'

    if substitute(getline('.'),
    \s:Today,'','') == getline('.')

        echo 'ERROR:' . " '" . s:Today . "'" .
        \ ' not found!'

        call setpos('.', l:cursor)
        return

    else

        call setpos('.', l:cursor)

    endif

    " insert new lines for another day

    call MoveFoldMarker(2)

    " fix substitution errors on rare occasions:
    " the second day in a month
    " in which case both }2 will be changed

    'l-1
    call search('}\{3}2$','cW')
    mark l

    'h,'l-1yank
    'h-2mark z
    'zput

    " change date and foldlevel

    'z+1s/\d\{1,2}\( 日\)\@=/\=submatch(0)+1/

    call MappingMarker(1)
    call ChangeFoldLevel(2)

    'zdelete
    execute 'normal mh]zml'

    " substitute 'page 2-5' with 'page 6-'

    'h,'ls/\(\d\+-\)\@<=\(\d\+\)/\=submatch(0)+1/e
    'h,'ls/\d\+-\(\d\+\)/\1-/e

    " substitute done (~) with undone (*)

    execute "'h,'ls/^" . s:Bullet_Post . '/' .
    \ s:Bullet_Pre . '/e'

    'h+2
    execute 'normal wma'

endfunction "}}}4

function s:F2() "{{{4

    nnoremap <buffer> <silent> <f2>
    \ :call <sid>AnotherDay()<cr>

endfunction "}}}4

 "}}}3
" <f3> "{{{3

function s:MoveTask() "{{{4

    let l:cursor =
    \ [bufnr('%'),line('w0'),1,0]

    set nofoldenable

    if substitute(getline('.'),
    \ '^' . s:Bullet_OR,'','') == getline('.')

        set foldenable
        call setpos(l:cursor)
        execute 'normal zt'
        ''
        echo 'ERROR: Task line not found!'
        return

    endif

    " move today's first task into buffer
    " set new marker 'a'

    if substitute(getline(line('.')-2),
    \s:Today,'','') != getline(line('.')-2)

        +1
        execute 'normal wma'
        -1

    endif

    " move tasks between buffer and today

    +1mark h
    execute 'normal [z'

    " from today into buffer

    if substitute(getline('.'),
    \s:Today,'','') != getline('.')

        'h-1delete
        call search(s:Buffer,'bW')
        +1put

    " from buffer into today

    elseif substitute(getline('.'),
    \ s:Buffer,'','') != getline('.')

        'h-1delete
        call search(s:Today,'W')
        execute 'normal ]z'
        -2put

    endif

    execute 's/^' . s:Bullet_Post . '/' .
    \ s:Bullet_Pre . '/e'

    set foldenable
    call setpos('.', l:cursor)
    execute 'normal zt'
    'h

endfunction "}}}4

function s:F3() "{{{4

    nnoremap <buffer> <silent> <f3>
    \ :call <sid>MoveTask()<cr>

endfunction "}}}4

 "}}}3
" <f4> "{{{3

function s:ProgressBar() "{{{4

    if substitute(getline("'<"),
    \ s:Progress,'','') == getline("'<")

        return

    elseif substitute(getline("'>"),
    \s:Progress,'','') == getline("'>")

        return

    else

        '<mark j
        '>mark k

        let l:begin = substitute(getline("'j"),
        \'^.*' . s:Progress,'\1','')

        execute "'j,'ks/" . s:Progress . '//'

        let l:i = l:begin |
        \ 'j,'kg/$/s//\=l:i/ |
        \ let l:i = l:i + 1

        'j,'ks/$/#/

        let l:j = l:begin |
        \ 'j,'kg/$/s//\=l:j*30/ |
        \ let l:j = l:j + 1

        'j,'ks/#/./

    endif

endfunction "}}}4

function s:F4() "{{{4

    nnoremap <buffer> <silent> <f4>
    \ :s/$/，1.30/<cr>

    inoremap <buffer> <silent> <f4>
    \ ，1.30<esc>

    vnoremap <buffer> <silent> <f4>
    \ <esc>:call <sid>ProgressBar()<cr>

endfunction "}}}4

 "}}}3
" time spent in total "{{{3

function s:TimeSpent() "{{{4

    let l:register = @"

    if search(l:register,'cnw') == 0

        echo 'ERROR: Nothing matched for @"!'
        return

    endif

    execute 'g!/' . l:register . '/delete'

    if substitute(getline('.'),s:Progress,'','')
    \ == getline('.')

        undo
        echo 'ERROR: Incorrect @"!'
        return

    endif

    execute '%s/^\(.*，\)' . s:Progress .
    \ '/\2\1\2\3\4/'

    sort

    let l:highest = substitute(getline('$'),
    \ '^\(.*\)' . s:Count . '\(.*\)$',
    \ '\2','')

    undo

    execute 'g!/' . l:register . '/delete'

    let l:count = 2

    while l:count < l:highest + 1

        let l:smaller = l:count - 1

        execute 'g/，' . l:count . '\./' .
        \ '-1s/，' . l:smaller . '\./' . s:Mark .
        \ '/'

        let l:count = l:count + 1

    endwhile

    execute 'g/' . s:Mark . '/delete'

    let l:time = 0
    let l:line = 1

    $s/$/\r

    while l:line < line('$')

        let l:time = l:time +
        \ substitute(getline(l:line),
        \'^\(.*\.\)' . s:Time . '$','\2','')

        let l:line = l:line + 1

    endwhile

    echo 'NOTE: ' . string(l:time / 60.0) .
    \ ' hour(s).'

endfunction "}}}4

 "}}}3
" key map all-in-one "{{{3

function s:KeyMap() "{{{4

    let l:i = 1

    while l:i < 5

        execute 'call <sid>F' . l:i . '()'
        let l:i = l:i + 1

    endwhile

"command -buffer AchDone call <sid>Finished()
"exe 'nno <buffer> ' . g:Key . ' :AchDone<cr>'
"com! -buffer -range NewMark <line1>,<line2>s;^;###;

endfunction "}}}4

 "}}}3
 "}}}2
" commands "{{{2

command Ach0TimeSpent call <sid>TimeSpent()
command Ach1Keymap call <sid>KeyMap()

autocmd BufRead achieve.daily call <sid>KeyMap()

 "}}}2
 "}}}1
