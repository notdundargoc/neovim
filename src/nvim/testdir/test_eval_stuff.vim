" Tests for various eval things.

function s:foo() abort
  try
    return [] == 0
  catch
    return 1
  endtry
endfunction

func Test_catch_return_with_error()
  call assert_equal(1, s:foo())
endfunc

func Test_nocatch_restore_silent_emsg()
  silent! try
    throw 1
  catch
  endtry
  echoerr 'wrong'
  let c1 = nr2char(screenchar(&lines, 1))
  let c2 = nr2char(screenchar(&lines, 2))
  let c3 = nr2char(screenchar(&lines, 3))
  let c4 = nr2char(screenchar(&lines, 4))
  let c5 = nr2char(screenchar(&lines, 5))
  call assert_equal('wrong', c1 . c2 . c3 . c4 . c5)
endfunc

func Test_mkdir_p()
  call mkdir('Xmkdir/nested', 'p')
  call assert_true(isdirectory('Xmkdir/nested'))
  try
    " Trying to make existing directories doesn't error
    call mkdir('Xmkdir', 'p')
    call mkdir('Xmkdir/nested', 'p')
  catch /E739:/
    call assert_report('mkdir(..., "p") failed for an existing directory')
  endtry
  " 'p' doesn't suppress real errors
  call writefile([], 'Xfile')
  call assert_fails('call mkdir("Xfile", "p")', 'E739')
  call delete('Xfile')
  call delete('Xmkdir', 'rf')
endfunc

func Test_line_continuation()
  let array = [5,
	"\ ignore this
	\ 6,
	"\ more to ignore
	"\ more moreto ignore
	\ ]
	"\ and some more
  call assert_equal([5, 6], array)
endfunc

func Test_E963()
  " These commands used to cause an internal error prior to vim 8.1.0563
  let v_e = v:errors
  let v_o = v:oldfiles
  call assert_fails("let v:errors=''", 'E963:')
  call assert_equal(v_e, v:errors)
  call assert_fails("let v:oldfiles=''", 'E963:')
  call assert_equal(v_o, v:oldfiles)
endfunc

func Test_for_invalid()
  call assert_fails("for x in 99", 'E1098:')
  call assert_fails("for x in function('winnr')", 'E1098:')
  call assert_fails("for x in {'a': 9}", 'E1098:')

  if 0
    /1/5/2/s/\n
  endif
  redraw
endfunc

func Test_readfile_binary()
  new
  call setline(1, ['one', 'two', 'three'])
  setlocal ff=dos
  silent write XReadfile
  let lines = readfile('XReadfile')
  call assert_equal(['one', 'two', 'three'], lines)
  let lines = readfile('XReadfile', '', 2)
  call assert_equal(['one', 'two'], lines)
  let lines = readfile('XReadfile', 'b')
  call assert_equal(["one\r", "two\r", "three\r", ""], lines)
  let lines = readfile('XReadfile', 'b', 2)
  call assert_equal(["one\r", "two\r"], lines)

  bwipe!
  call delete('XReadfile')
endfunc

func Test_let_errmsg()
  call assert_fails('let v:errmsg = []', 'E730:')
  let v:errmsg = ''
  call assert_fails('let v:errmsg = []', 'E730:')
  let v:errmsg = ''
endfunc

func Test_string_concatenation()
  call assert_equal('ab', 'a'.'b')
  call assert_equal('ab', 'a' .'b')
  call assert_equal('ab', 'a'. 'b')
  call assert_equal('ab', 'a' . 'b')

  call assert_equal('ab', 'a'..'b')
  call assert_equal('ab', 'a' ..'b')
  call assert_equal('ab', 'a'.. 'b')
  call assert_equal('ab', 'a' .. 'b')

  let a = 'a'
  let b = 'b'
  let a .= b
  call assert_equal('ab', a)

  let a = 'a'
  let a.=b
  call assert_equal('ab', a)

  let a = 'a'
  let a ..= b
  call assert_equal('ab', a)

  let a = 'a'
  let a..=b
  call assert_equal('ab', a)
endfunc

" Test fix for issue #4507
func Test_skip_after_throw()
  try
    throw 'something'
    let x = wincol() || &ts
  catch /something/
  endtry
endfunc

" scriptversion 1
func Test_string_concat_scriptversion1()
  call assert_true(has('vimscript-1'))
  let a = 'a'
  let b = 'b'

  echo a . b
  let a .= b
  let vers = 1.2.3
  call assert_equal('123', vers)

  if has('float')
    call assert_fails('let f = .5', 'E15:')
  endif
endfunc

" scriptversion 1
func Test_vvar_scriptversion1()
  call assert_equal(15, 017)
  call assert_equal(15, 0o17)
  call assert_equal(15, 0O17)
  call assert_equal(18, 018)
  call assert_equal(511, 0o777)
endfunc

func Test_number_max_min_size()
  " This will fail on systems without 64 bit number support or when not
  " configured correctly.
  call assert_equal(64, v:numbersize)

  call assert_true(v:numbermin < -9999999)
  call assert_true(v:numbermax > 9999999)
endfunc

func Assert_reg(name, type, value, valuestr, expr, exprstr)
  call assert_equal(a:type, getregtype(a:name))
  call assert_equal(a:value, getreg(a:name))
  call assert_equal(a:valuestr, string(getreg(a:name, 0, 1)))
  call assert_equal(a:expr, getreg(a:name, 1))
  call assert_equal(a:exprstr, string(getreg(a:name, 1, 1)))
endfunc

func Test_let_register()
  let @" = 'abc'
  call Assert_reg('"', 'v', "abc", "['abc']", "abc", "['abc']")
  let @" = "abc\n"
  call Assert_reg('"', 'V', "abc\n", "['abc']", "abc\n", "['abc']")
  let @" = "abc\<C-m>"
  call Assert_reg('"', 'V', "abc\r\n", "['abc\r']", "abc\r\n", "['abc\r']")
  let @= = '"abc"'
  call Assert_reg('=', 'v', "abc", "['abc']", '"abc"', "['\"abc\"']")
endfunc

func Assert_regput(name, result)
  new
  execute "silent normal! o==\n==\e\"" . a:name . "P"
  call assert_equal(a:result, getline(2, line('$')))
  bwipe!
endfunc

func Test_setreg_basic()
  call setreg('a', 'abcA', 'c')
  call Assert_reg('a', 'v', "abcA", "['abcA']", "abcA", "['abcA']")
  call Assert_regput('a', ['==', '=abcA='])

  call setreg('A', 'abcAc', 'c')
  call Assert_reg('A', 'v', "abcAabcAc", "['abcAabcAc']", "abcAabcAc", "['abcAabcAc']")
  call Assert_regput('a', ['==', '=abcAabcAc='])

  call setreg('A', 'abcAl', 'l')
  call Assert_reg('A', 'V', "abcAabcAcabcAl\n", "['abcAabcAcabcAl']", "abcAabcAcabcAl\n", "['abcAabcAcabcAl']")
  call Assert_regput('a', ['==', 'abcAabcAcabcAl', '=='])

  call setreg('A', 'abcAc2','c')
  call Assert_reg('A', 'v', "abcAabcAcabcAl\nabcAc2", "['abcAabcAcabcAl', 'abcAc2']", "abcAabcAcabcAl\nabcAc2", "['abcAabcAcabcAl', 'abcAc2']")
  call Assert_regput('a', ['==', '=abcAabcAcabcAl', 'abcAc2='])

  call setreg('b', 'abcB', 'v')
  call Assert_reg('b', 'v', "abcB", "['abcB']", "abcB", "['abcB']")
  call Assert_regput('b', ['==', '=abcB='])

  call setreg('b', 'abcBc', 'ca')
  call Assert_reg('b', 'v', "abcBabcBc", "['abcBabcBc']", "abcBabcBc", "['abcBabcBc']")
  call Assert_regput('b', ['==', '=abcBabcBc='])

  call setreg('b', 'abcBb', 'ba')
  call Assert_reg('b', "\<C-V>5", "abcBabcBcabcBb", "['abcBabcBcabcBb']", "abcBabcBcabcBb", "['abcBabcBcabcBb']")
  call Assert_regput('b', ['==', '=abcBabcBcabcBb='])

  call setreg('b', 'abcBc2','ca')
  call Assert_reg('b', "v", "abcBabcBcabcBb\nabcBc2", "['abcBabcBcabcBb', 'abcBc2']", "abcBabcBcabcBb\nabcBc2", "['abcBabcBcabcBb', 'abcBc2']")
  call Assert_regput('b', ['==', '=abcBabcBcabcBb', 'abcBc2='])

  call setreg('b', 'abcBb2','b50a')
  call Assert_reg('b', "\<C-V>50", "abcBabcBcabcBb\nabcBc2abcBb2", "['abcBabcBcabcBb', 'abcBc2abcBb2']", "abcBabcBcabcBb\nabcBc2abcBb2", "['abcBabcBcabcBb', 'abcBc2abcBb2']")
  call Assert_regput('b', ['==', '=abcBabcBcabcBb                                    =', ' abcBc2abcBb2'])

  call setreg('c', 'abcC', 'l')
  call Assert_reg('c', 'V', "abcC\n", "['abcC']", "abcC\n", "['abcC']")
  call Assert_regput('c', ['==', 'abcC', '=='])

  call setreg('C', 'abcCl', 'l')
  call Assert_reg('C', 'V', "abcC\nabcCl\n", "['abcC', 'abcCl']", "abcC\nabcCl\n", "['abcC', 'abcCl']")
  call Assert_regput('c', ['==', 'abcC', 'abcCl', '=='])

  call setreg('C', 'abcCc', 'c')
  call Assert_reg('C', 'v', "abcC\nabcCl\nabcCc", "['abcC', 'abcCl', 'abcCc']", "abcC\nabcCl\nabcCc", "['abcC', 'abcCl', 'abcCc']")
  call Assert_regput('c', ['==', '=abcC', 'abcCl', 'abcCc='])

  call setreg('d', 'abcD', 'V')
  call Assert_reg('d', 'V', "abcD\n", "['abcD']", "abcD\n", "['abcD']")
  call Assert_regput('d', ['==', 'abcD', '=='])

  call setreg('D', 'abcDb', 'b')
  call Assert_reg('d', "\<C-V>5", "abcD\nabcDb", "['abcD', 'abcDb']", "abcD\nabcDb", "['abcD', 'abcDb']")
  call Assert_regput('d', ['==', '=abcD =', ' abcDb'])

  call setreg('e', 'abcE', 'b')
  call Assert_reg('e', "\<C-V>4", "abcE", "['abcE']", "abcE", "['abcE']")
  call Assert_regput('e', ['==', '=abcE='])

  call setreg('E', 'abcEb', 'b')
  call Assert_reg('E', "\<C-V>5", "abcE\nabcEb", "['abcE', 'abcEb']", "abcE\nabcEb", "['abcE', 'abcEb']")
  call Assert_regput('e', ['==', '=abcE =', ' abcEb'])

  call setreg('E', 'abcEl', 'l')
  call Assert_reg('E', "V", "abcE\nabcEb\nabcEl\n", "['abcE', 'abcEb', 'abcEl']", "abcE\nabcEb\nabcEl\n", "['abcE', 'abcEb', 'abcEl']")
  call Assert_regput('e', ['==', 'abcE', 'abcEb', 'abcEl', '=='])

  call setreg('f', 'abcF', "\<C-v>")
  call Assert_reg('f', "\<C-V>4", "abcF", "['abcF']", "abcF", "['abcF']")
  call Assert_regput('f', ['==', '=abcF='])

  call setreg('F', 'abcFc', 'c')
  call Assert_reg('F', "v", "abcF\nabcFc", "['abcF', 'abcFc']", "abcF\nabcFc", "['abcF', 'abcFc']")
  call Assert_regput('f', ['==', '=abcF', 'abcFc='])

  call setreg('g', 'abcG', 'b10')
  call Assert_reg('g', "\<C-V>10", "abcG", "['abcG']", "abcG", "['abcG']")
  call Assert_regput('g', ['==', '=abcG      ='])

  call setreg('h', 'abcH', "\<C-v>10")
  call Assert_reg('h', "\<C-V>10", "abcH", "['abcH']", "abcH", "['abcH']")
  call Assert_regput('h', ['==', '=abcH      ='])

  call setreg('I', 'abcI')
  call Assert_reg('I', "v", "abcI", "['abcI']", "abcI", "['abcI']")
  call Assert_regput('I', ['==', '=abcI='])

  " Error cases
  call assert_fails('call setreg()', 'E119:')
  call assert_fails('call setreg(1)', 'E119:')
  call assert_fails('call setreg(1, 2, 3, 4)', 'E118:')
  call assert_fails('call setreg([], 2)', 'E730:')
  call assert_fails('call setreg(1, 2, [])', 'E730:')
  call assert_fails('call setreg("/", ["1", "2"])', 'E883:')
  call assert_fails('call setreg("=", ["1", "2"])', 'E883:')
  call assert_fails('call setreg(1, ["", "", [], ""])', 'E730:')
endfunc

func Test_curly_assignment()
  let s:svar = 'svar'
  let g:gvar = 'gvar'
  let lname = 'gvar'
  let gname = 'gvar'
  let {'s:'.lname} = {'g:'.gname}
  call assert_equal('gvar', s:gvar)
  let s:gvar = ''
  let { 's:'.lname } = { 'g:'.gname }
  call assert_equal('gvar', s:gvar)
  let s:gvar = ''
  let { 's:' . lname } = { 'g:' . gname }
  call assert_equal('gvar', s:gvar)
  let s:gvar = ''
  let { 's:' .. lname } = { 'g:' .. gname }
  call assert_equal('gvar', s:gvar)

  unlet s:svar
  unlet s:gvar
  unlet g:gvar
endfunc

" vim: shiftwidth=2 sts=2 expandtab
