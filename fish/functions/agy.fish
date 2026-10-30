function agy --wraps=agy --description 'alias agy to agy --dangerously-skip-permissions'
  command agy --dangerously-skip-permissions $argv
end
