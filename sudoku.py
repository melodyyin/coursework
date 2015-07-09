#!/usr/bin/env python
import struct, string, math
import time

# assignment 3 starts here
# ----------------------------------------------------------------
assignments = 0

# SudokuBoard [boolean boolean boolean boolean] -> SudokuBoard 
def solve(initial_board, forward_checking = False, MRV = False, MCV = False,
    LCV = False):
    """Takes an initial SudokuBoard and solves it using back tracking, and zero
    or more of the heuristics and constraint propagation methods (determined by
    arguments). Returns the resulting board solution. """
    
    arr = initial_board.CurrentGameBoard
    size = len(arr)
    assms = 0

    # if not fwd check, then backchecking
    if not forward_checking:
        t0 = time.time()
        new_board_arr = backtrack(arr, t0)
    # otherwise, fwd check with options
    else:
        t0 = time.time()
        new_board_arr = heuristics(arr, MRV, MCV, LCV, t0)
    
    # fill board with new values 
    for row in range(size):
        for col in range(size):
            initial_board.set_value(row, col, new_board_arr[row][col])

    # return new board
    return initial_board

# backtrack keeps assigns values from domain in the order they appear 
# to the variables in the order they appear
# until board is wrong
# list-of-nums -> list-of-nums or False (if unsolvable)
def backtrack(arr, t0):
    global assignments 

    # est a time upper limit
    passed_time = time.time() - t0
    if passed_time > 300:
        print "taking too long, printing..."
        print "passed time: ", passed_time
        print "assignments: ", assignments
        return 

    # est an assignment upper limit 
    if assignments > 100000:
        print "too many assignments, printing..."
        print "passed time: ", passed_time
        print "assignments: ", assignments
        return

    # if board is complete, return 
    if is_complete(arr):
        print "returning..."
        print "passed time: ", passed_time
        print "assignments: ", assignments
        return arr

    size = len(arr)
    dom = range(1, size+1)

    for row in range(size):
        for col in range(size):
            # if unassigned 
            if arr[row][col] == 0: 
                # look thru all the domain 
                for i in range(len(dom)): 
                    # assign to first val in dom
                    arr[row][col]= dom[i]
                    assignments = assignments + 1
                    # if value assignment has led to wrong board, backtrack
                    if check_board(arr):
                        result = backtrack(arr, t0)
                        if result:
                            return result 
                # done looking thru domain, need to backtrack
                arr[row][col] = 0
                return False

# forward check assigns only correct values to variables in the order they appear 
# heuristics imply fwd check ; mrv and mcv won't be turned on at the same time 
# list-of-nums -> list-of-nums or False (if unsolvable)
def heuristics(arr, mrv, mcv, lcv, t0):
    global assignments

    # est a time upper limit
    passed_time = time.time() - t0
    if passed_time > 300:
        print "taking too long, printing..."
        print "passed time: ", passed_time
        print "assignments: ", assignments
        return 

    # est an assignment upper limit 
    if assignments > 100000:
        print "too many assignments, printing..."
        print "passed time: ", passed_time
        print "assignments: ", assignments
        return

    # if board is complete, return 
    if is_complete(arr):
        print "returning..."
        print "passed time: ", passed_time
        print "assignments: ", assignments 
        return arr

    size = len(arr)
    dom = range(1, size+1)

    rows = []
    cols = []

    # MRV = minimum remaining values - select variable with smallest domain 
    if mrv == True:
        var_values = dict()

        for row in range(size):
            for col in range(size):
                val = arr[row][col]
                vv_list = []
                # if variable is unassigned 
                if val == 0:
                    # remember its pos 
                    pos = (row, col)
                    for d in dom:
                        # make a list of variable's legal values
                        if is_legal(d, row, col, arr):
                            vv_list.append(d)
                    # store in a dict 
                    var_values[pos] = len(vv_list)
                # otherwise do nothing 
        var_values_ascending = sorted(var_values.items(), key=lambda x: x[1])

        for pair in var_values_ascending:
            rows.append(pair[0][0])
            cols.append(pair[0][1])
    # MCV = most constrained variable - select variable that affects most variables 
    elif mcv == True:
        var_values = dict()

        for row in range(size):
            for col in range(size):
                val = arr[row][col]
                if val == 0:
                    pos = (row, col)
                    count = mcv_count(arr, row, col)
                    var_values[pos] = count 
        var_values_descending = sorted(var_values.items(), key=lambda x: x[1], reverse=True)

        for pair in var_values_descending:
            rows.append(pair[0][0])
            cols.append(pair[0][1])
    # no variable ordering heuristic 
    else:
        rows = range(size)
        cols = range(size)

    # LCV = least constraining value - select value that leads to the fewest illegal values for other unassigned vars in its row col and box
    if lcv == True:
        val_dom = dict()
        dom_counts = dict()

        for row in range(size):
            for col in range(size):
                val = arr[row][col]
                if val == 0:
                    pos = (row, col)
                    val_dom[pos] = []
                    doms = []

                    # keep a table of {value: #} pairs 
                    for d in dom:
                        dom_counts[d] = is_legal2(d, row, col, arr)
                    # sort this table by # 
                    dom_counts_ascending = sorted(dom_counts.items(), key=lambda x: x[1])

                    # get the values sorted by how many times it conflicts other values 
                    for dm in dom_counts_ascending:
                        doms.append(dm[0])
                    
                    # put it in val_dom 
                    val_dom[pos] = doms 
    # otherwise dom is intial setup 

    # forward checking         
    for row in rows:
        for col in cols:
            if arr[row][col] == 0:
                # LCV 
                if lcv == True:
                    pos = (row, col)
                    # look thru ordered domain
                    for d in val_dom[pos]:
                        if is_legal(d, row, col, arr):
                            arr[row][col] = d
                            assignments = assignments + 1
                            result = heuristics(arr, mrv, mcv, lcv, t0)
                            if result:
                                return result
                    arr[row][col] = 0
                    return False
                # no values ordering 
                else:
                    for d in dom: 
                        # checks if d is valid value before making the assignment
                        if is_legal(d, row, col, arr):
                            arr[row][col] = d
                            assignments = assignments + 1
                            result = heuristics(arr, mrv, mcv, lcv, t0)
                            if result:
                                return result
                    arr[row][col] = 0
                    return False

# returns the number of conflicting variables in box, row and col
# list-of-nums num num -> num
def mcv_count(arr, row, col):
    size = len(arr)
    # box has dim bdim x bdim 
    bdim = int(math.sqrt(size))

    # find start and end for row and col of box 
    rcount = 0
    ccount = 0

    while bdim*(rcount+1) <= size:
        if row < bdim*(rcount+1):
            break
        rcount = rcount + 1

    while bdim*(ccount+1) <= size: 
        if col < bdim*(ccount+1):
            break
        ccount = ccount + 1

    box_arr = []
    for i in range(rcount*bdim, (rcount+1)*bdim):
        for j in range(ccount*bdim, (ccount+1)*bdim):
            if arr[i][j] == 0:
                box_arr.append((i,j))

    row_arr = []
    for c in range(size):
        if arr[row][c] == 0:
            row_arr.append((row, c))

    col_arr = []
    for r in range(size):
        if arr[r][col] == 0:
            col_arr.append((r, col))

    # how many unassigned variables it affects 
    count = len(set(box_arr).union(set(row_arr).union(set(col_arr)))) - 1
    return count

# returns the box of a val in row and col
# num num num list-of-nums -> list-of-nums
def get_box(row, col, arr):
    size = len(arr)
    # box has dim bdim x bdim 
    bdim = int(math.sqrt(size))

    # find start and end for row and col of box 
    rcount = 0
    ccount = 0

    while bdim*(rcount+1) <= size:
        if row < bdim*(rcount+1):
            break
        rcount = rcount + 1

    while bdim*(ccount+1) <= size: 
        if col < bdim*(ccount+1):
            break
        ccount = ccount + 1

    box_arr = []
    for i in range(rcount*bdim, (rcount+1)*bdim):
        for j in range(ccount*bdim, (ccount+1)*bdim):
            box_arr.append(arr[i][j])

    return box_arr

# returns column col
# num list-of-nums -> list-of-nums
def get_col(col, arr):
    col_arr = []
    size = len(arr)
    for row in range(size):
        col_arr.append(arr[row][col])

    return col_arr

# returns if value is legal in specified position (MOVE NOT YET MADE)
# num num num list-of-nums -> boolean
def is_legal(val, row, col, arr):
    box_arr = get_box(row, col, arr)
    col_arr = get_col(col, arr)

    if val in arr[row] or val in col_arr or val in box_arr:
        return False
    else:
        return True

# returns how many conflicts a value would have (MOVE NOT YET MADE)
# num num num list-of-nums -> num
def is_legal2(val, row, col, arr):
    box_arr = get_box(row, col, arr)
    col_arr = get_col(col, arr)

    count = 0
    if val in arr[row]: 
        count = count + 1
    if val in col_arr:
        count = count + 1
    if val in box_arr:
        count = count + 1 

    return count

# checks if (incomplete) board is valid (MOVE ALREADY MADE)
# list-of-num -> boolean 
def check_board(arr):
    size = len(arr)

    # check for dupes in rows
    for row in range(size):
        counts = dict()
        count = 0
        for col in range(size):
            val = arr[row][col]
            if val != 0:
                if val in counts:
                    return False
                else: 
                    counts[val] = "here!"

    # check for dupes in cols 
    for col in range(size):
        counts = dict()
        count = 0
        for row in range(size):
            val = arr[row][col]
            if val != 0:
                if val in counts:
                    return False
                else: 
                    counts[val] = "here!"

    # check for dupes inboxes
    for row in range(size):
        counts = dict()
        count = 0
        for col in range(size):
            val = arr[row][col]
            if val != 0:
                if val in counts:
                    return False
                else:
                    counts[val] = "here!"

    return True