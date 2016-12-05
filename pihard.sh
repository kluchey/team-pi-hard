#!/usr/bin/expect
#Team Pi-Hard: John Fletcher and Kieran Cluchey/
#Uses GNUChess and Expect libraries.


# define function that allows conversion of board states into
# an exact algebraic notation move
proc convertMove {firstboard secondboard} {

# dumb way of defining chess board positions... indexed 0-63
set boardref [split "a8 b8 c8 d8 e8 f8 g8 h8 a7 b7 c7 d7 e7 f7 g7 h7 a6 b6 c6 d6 e6 f6 g6 h6 a5 b5 c5 d5 e5 f5 g5 h5 a4 b4 c4 d4 e4 f4 g4 h4 a3 b3 c3 d3 e3 f3 g3 h3 a2 b2 c2 d2 e2 f2 g2 h2 a1 b1 c1 d1 e1 f1 g1 h1"]

#	these variables will never be set to >63 so if either
#	is still 65 in loop then we aren't done searchin'
	set initPos 65
	set finaPos 65
	set thirPos 65
	set fourPos 65
	set i 0

#	loop that controls board comparison, when both positions
#	are not== 65 (i.e. determined) then loop terminates
	while {$i < 64} {

#		ignore all positions that are the same in both boards
		if {[string equal [lindex $firstboard $i] [lindex $secondboard $i]]} {
			incr i 1
			continue

#		else the position differs (two positions differ total)
		} else {

#			checks if after latest move, a board square
#			has a ".", implying this is the position from
#			which the piece has moved
			if {[string equal "." [lindex $secondboard $i]]} {
				if {$initPos == 65} {
					set initPos $i
				} else {
					set thirPos $i
				}
				incr i 1
				continue

#			else the position is necessarily the board square
#			onto which the piece has moved
			} else {
				if {$finaPos == 65} {
					set finaPos $i
				} else {
					set fourPos $i
				}
				incr i 1
				continue
			}
		}
	}
#puts "$initPos"
#puts "$finaPos"
#	we could return #exactAlgMove here but there might be a promotion of a pawn
	if {$thirPos == $fourPos} {
		set exactAlgMove [string cat [lindex $boardref $initPos] [lindex $boardref $finaPos]]
	} elseif {$fourPos == 65} {
		if {[string equal [lindex $secondboard $finaPos] [lindex $firstboard $initPos]]} {
			set exactAlgMove [string cat [lindex $boardref $initPos] [lindex $boardref $finaPos]]
		} else {
			set exactAlgMove [string cat [lindex $boardref $thirPos] [lindex $boardref $finaPos]]
			set initPos $thirPos
		}
	} else {
		if {[string equal -nocase "K" [lindex $secondboard $finaPos]]} {
			if {$finaPos == 2 || $finaPos == 6} {
				set initPos 4
			} else {
				set initPos 60
			}
		} else {
			set finaPos $fourPos
			if {$finaPos == 2 || $finaPos == 6} {
				set initPos 4
			} else {
				set initPos 60
			}
		}
		set exactAlgMove [string cat [lindex $boardref $initPos] [lindex $boardref $finaPos]]
	}
	set promotion ""

#	checks for promotion of pawn by seeing if initial position had a pawn and
#	final position does not have a pawn
	if { [string equal -nocase "P" [lindex $firstboard $initPos]] && ![string equal -nocase "P" [lindex $secondboard $finaPos]] } {
		set promotion [lindex $secondboard $finaPos]
	}

#	returns either concatenation of $exactAlMove and an empty string or the promotion
	return [string cat $exactAlgMove $promotion]
}

# test
#set b1 [split ". . . . . . . . . . . . . . . . P p . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."]
#set b2 [split ". . . . . . . . . P . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."]
#puts [convertMove $b1 $b2]



log_user 0
spawn "gnuchess" -m
expect " :"

# if the game plays white se pick the first move arbitarily
# afterward we go into an input loop.
# saves calling to show captures etc
 if {[string equal -nocase [lindex $argv 0] "white"]} {
 send "a2a3\r"
 expect " :"
send_user "a2a3\n"
}
# infinite outer loop to always be running
# right now user has to quit, which is an error
while {1 ==1} {
# interact enters standard input directly to GNUchess
interact "\r" return
# taking back control of process deletes the \r we add it back in
send "\r"
expect " :"
# following code parses the output from gnuchess into a list of nonwhitespace elements
set temp [regexp -all -inline {\S+} $expect_out(buffer)]
set ChessOutput [split $temp "\n "]
# check if the 3rd last element is "generated" => move quiry
set temp2 [expr {[llength $ChessOutput] -6}]
if {![string equal [lindex $ChessOutput $temp2] "generated"]} {
#send [lindex $ChessOutput $temp2]

# check if invalid move made
if {![string equal [lindex $ChessOutput $temp2] "Invalid"]} {
#send "[lindex $ChessOutput temp2]\r"
#expect " :"

# First obtain old board for converter
# should still be in chess output
set board1 [lrange $ChessOutput [expr [llength $ChessOutput] - 67] end]
#send_user "[lindex $board1 0]"
send "show capture\r"
expect ": "

# following code parses the output from gnuchess into a list of nonwhitespace elements
set temp [regexp -all -inline {\S+} $expect_out(buffer)]
set ChessOutput [split $temp "\n "]

# if no captures are possible the 11th index will be generated
# if captures are possible generated will have a higher index
if {![string equal [lindex $ChessOutput 11] "generated"]} {

	#Capture posible, first capture at index 8
	send "[lindex $ChessOutput 8]\r"
	expect " :"
	
	set temp [regexp -all -inline {\S+} $expect_out(buffer)]
	set ChessOutput [split $temp "\n "]
	
	set board2 [lrange $ChessOutput [expr [llength $ChessOutput] - 67] end]
	send_user "[convertMove $board1 $board2]\n"
} else {
	# capture not possible, move on to moving out of check
	send "show noncapture\r"
	expect ": "

	# following code parses the output from gnuchess into a list of nonwhitespace elements
	set temp [regexp -all -inline {\S+} $expect_out(buffer)]
	set ChessOutput [split $temp "\n "]	
#	if {![string equal [lindex $ChessOutput 11] "generated"]} {

		#need to escape check, first legal move at index 8
	send "[lindex $ChessOutput 8]\r"
	expect " :"

	set temp [regexp -all -inline {\S+} $expect_out(buffer)]
	set ChessOutput [split $temp "\n "]

	
	set board2 [lrange $ChessOutput [expr [llength $ChessOutput] - 67] end]

	send_user "[convertMove $board1 $board2]\n"

#	} else {
	#	send "show moves\r"
	#	expect ": "

		# following code parses the output from gnuchess into a list of nonwhitespace elements
	#	set temp [regexp -all -inline {\S+} $expect_out(buffer)]
	#	set Moves [split $temp "\n "]

		# if moves exist they start at index 8 every new move is up 2 indexes
		# show moves returns some illegal moves (such as moving into check)
		# we may need to check all moves.
		# -9 for "number of moves generated" -1 for indexing so moves end at size -10
		# should be a for loop but giving errors so its a while loop
		#set i 8
		#while {$i < [expr {[llength $ChessOutput] -10}]} {
		#	send "[lindex $ChessOutput $i]\r"
		#	expect " :"
		#	set temp [regexp -all -inline {\S+} $expect_out(buffer)]
		#	set ChessOutput [split $temp "\n "]
		#	if {[string equal [lindex $ChessOutput 8] "Invalid"]} {
		#		# invalid move move on to the next one
		#		set i [expr {$i + 2}]
		#	} else { 
		#		#valid move, break while
		#		break
		#	}
			
		#}
	#}
}
}
}
}
send "quit\r"
interact


