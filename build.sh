cat header.md > README.md
echo '\r\n' >>  README.md
#find . -type d | grep -v '^\./\.git' | grep -v '^\.$' | awk -F '/' '{print "* ["$4"](https://github.com/lenxeon/notes/tree/master/"$2"/"$3"/"$4")"}'  | grep -v "\[\]" >>  README.md
find . -type d | grep -v '^\./\.git' | grep -v '^\.$' | awk -F '/' '{print "* ["$2"-"$3"-"$4"](https://github.com/lenxeon/notes/tree/master/"$2"/"$3"/"$4")"}'  | grep -v "\-\]" | sort >>  README.md
