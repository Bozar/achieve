" daily achievement "{{{1

" variables "{{{2

let s:Today_Ach = '^\d\{1,2} 月 \d\{1,2} 日'
let s:Today_Ach .= ' {\{3}\d$'

let s:Buffer_Ach = '^缓冲区 {\{3}\d$'

let s:Count_Ach = '\(第 \)\(\d\{1,2}\)\( 次，\)'
let s:Time_Ach = '\(共 \)\(\d\{2,3}\)\( 分钟\)'

let s:Progress_Ach = s:Count_Ach
let s:Progress_Ach .= s:Time_Ach
let s:Progress_Ach .= '$'

 "}}}2
" functions "{{{2

" <f1> "{{{3

" undone (*) and done (~)

function Finished_Ach() "{{{

	if substitute(getline('.'),
	\'^\t\*','','') != getline('.')
		s/^\t\*/\t\~/
	elseif substitute(getline('.'),
	\'^\t\~','','') != getline('.')
		s/^\t\~/\t\*/
	endif

endfunction "}}}

function F1_Ach() "{{{

	nnoremap <buffer> <silent> <f1>
	\ :call Finished_Ach()<cr>

endfunction "}}}

 "}}}3
" <f2> "{{{3

function AnotherDay_Ach() "{{{

	let l:cursor_current = getpos('.')

	" check fold head
	call CursorAtFoldBegin()
	execute 'normal [z'
	if substitute(getline('.'),
	\s:Today_Ach,'','') == getline('.')
		echo "ERROR: '" . s:Today_Ach .
		\ "' not found!"
		call setpos('.', l:cursor_current)
		return
	else
		call setpos('.', l:cursor_current)
	endif

	" insert new lines for another day
	call MoveFoldMarker(2)
	" fix substitution errors on rare occasions:
	" the second day in a month
	" in which case both }2 will be changed
	'l-1
	call search('}\{3}2$','c')
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
	" substitute done (~) with undone (*)
	'h,'ls/\(\d\+-\)\@<=
		\\(\d\+\)/
		\\=submatch(0)+1/e
	'h,'ls/\d\+-\(\d\+\)/\1-/e
	'h,'ls/\t\~/\t\*/e

	'h+2
	execute 'normal wma'

endfunction "}}}

function F2_Ach() "{{{

	nnoremap <buffer> <silent> <f2>
	\ :call AnotherDay_Ach()<cr>

endfunction "}}}

 "}}}3
" <f3> "{{{3

function MoveTask_Ach() "{{{

	let l:cursor_top = [bufnr('%'),line('w0'),
	\1,'off']
	set nofoldenable

	if substitute(getline('.'),
	\'^\t\(\~\|\*\)','','') == getline('.')
		set foldenable
		call setpos(l:cursor_top)
		execute 'normal zt'
		''
		echo 'ERROR: Task line not found!'
		return
	endif

	" move today's first task into buffer
	" set new marker 'a'
	if substitute(getline(line('.')-2),
	\s:Today_Ach,'','')!=getline(line('.')-2)
		+1
		execute 'normal wma'
		-1
	endif

	" move tasks between buffer and today
	+1mark h
	execute 'normal [z'
	" from today into buffer
	if substitute(getline('.'),
	\s:Today_Ach,'','') != getline('.')
		'h-1delete
		call search(s:Buffer_Ach)
		+1put
		s/^\(\t\)\~/\1*/e
	" from buffer into today
	elseif substitute(getline('.'),
	\s:Buffer_Ach,'','') != getline('.')
		'h-1delete
		call search(s:Today_Ach)
		execute 'normal ]z'
		-2put
		s/^\(\t\)\~/\1*/e
	endif

	set foldenable
	call setpos('.', l:cursor_top)
	execute 'normal zt'
	'h

endfunction "}}}

function F3_Ach() "{{{

	nnoremap <buffer> <silent> <f3>
	\ :call MoveTask_Ach()<cr>

endfunction "}}}

 "}}}3
" <f4> "{{{3

function ProgressBar_Ach() "{{{

	if substitute(getline("'<"),
	\s:Progress_Ach,'','') == getline("'<")
		return
	elseif substitute(getline("'>"),
	\s:Progress_Ach,'','') == getline("'>")
		return
	else
		'<mark j
		'>mark k
		let l:begin = substitute(getline("'<"),
		\'^.*' . s:Progress_Ach,'\2','')
		execute "'j,'ks/" .
		\ s:Progress_Ach . "//"
		let l:i = l:begin | 'j,'kg/$/s/$/\=l:i/ |
		\ let l:i = l:i + 1
		'j,'ks/$/#/
		let l:i = l:begin |
		\ 'j,'kg/$/s/$/\=l:i*30/ |
		\ let l:i = l:i + 1
		'j,'ks/\(\d\{1,2}\)#\(\d\{2,3}\)$/
		\第 \1 次，共 \2 分钟/
	endif

endfunction "}}}

function F4_Ach() "{{{

	nnoremap <buffer> <silent> <f4>
	\ :s/$/，第 1 次，共 30 分钟/<cr>
	inoremap <buffer> <silent> <f4>
	\ ，第 1 次，共 30 分钟<esc>
	vnoremap <buffer> <silent> <f4>
	\ <esc>:call ProgressBar_Ach()<cr>

endfunction "}}}

 "}}}3
" time spent in total "{{{3

function TimeSpent_Ach() "{{{

	let l:register = @"
	call search(l:register)
	if substitute(getline('.'),l:register,
	\'','') == getline('.')
		echo 'ERROR: Nothing matched for @"!'
		return
	endif

	execute 'g!/' . l:register . '/delete'
	if substitute(getline('.'),s:Progress_Ach,
	\'','') == getline('.')
		undo
		echo 'ERROR: Incorrect @"!'
		return
	endif

	sort
	let l:highest = substitute(getline('$'),
	\'^\(.*\)' . s:Count_Ach . '\(.*\)$',
	\'\3','')
	undo
	execute 'g!/' . l:register . '/delete'

	let l:count = 2
	while l:count < l:highest + 1
		let l:smaller = l:count - 1
		execute 'g/第 ' . l:count .
		\ ' 次/-1s/第 ' . l:smaller .
		\ ' 次/###MARK###/'
		let l:count = l:count + 1
	endwhile
	g/###MARK###/delete

	let l:time = 0
	let l:line = 1
	$s/$/\r
	while l:line < line('$')
		let l:time = l:time +
		\ substitute(getline(l:line),
		\'^\(.*\)' . s:Time_Ach . '$',
		\'\3','')
		let l:line = l:line +1
	endwhile

	echo 'NOTE: ' . string(l:time / 60.0) .
	\ ' hour(s).'

endfunction "}}}

 "}}}3
" main function "{{{3

function KeyMap_Main_Ach() "{{{

	let l:i = 1
	while l:i < 5
		execute 'call F' . l:i . '_Ach()'
		let l:i = l:i + 1
	endwhile

endfunction "}}}

 "}}}3
 "}}}2
" commands "{{{2

command KeAchieve call KeyMap_Main_Ach()
command AchTimeSpent call TimeSpent_Ach()

autocmd BufRead achieve.note
\ call KeyMap_Main_Ach()

 "}}}2
 "}}}1
