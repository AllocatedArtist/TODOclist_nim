import std/terminal as t
import std/strformat
import std/strutils as str

const save_path = "save_file.txt"

type
  Chore = object
    name: string
    completed: bool
  InvalidInput = object of CatchableError
  ChoreCommand = enum cDelete, cComplete

proc createChore(name: string, completed: bool = false): Chore = result = Chore(name: name, completed: completed)

proc listChores(chores: seq[Chore]) = 
  for index, chore in chores:
    let i = index + 1
    if chore.completed:
      t.styledWriteLine(stdout, fgGreen, fmt"{i}: {chore.name} [COMPLETE]")
    else:
      t.styledWriteLine(stdout, fgRed, fmt"{i}: {chore.name} [INCOMPLETE]")
  
proc invalidInput(exception: ref InvalidInput, code: var bool) = 
  t.styledWriteLine(stdout, fgRed, exception.msg)
  code = true


proc executeChoreCommand(chores: var seq[Chore], cmd: ChoreCommand) = 
  var r = getch()
  var i: int
  if str.isAlphaNumeric(r):
    try: 
      i = str.parseInt($r) 
      if i <= 0:
        raise newException(InvalidInput, "Index inputted was too low")
      elif i >= chores.len + 1:
        raise newException(InvalidInput, "Index inputted was too high")
    except ValueError: 
      raise newException(InvalidInput, "Invalid number")

  case cmd:
    of cDelete:
      chores.del(i - 1)
    of cComplete:
      chores[i - 1].completed = not chores[i - 1].completed
  



proc displayMenu() = 
  t.styledWriteLine(stdout, fgWhite, "--TODO LIST--")
  t.styledWriteLine(stdout, fgRed, "(q) Quit")
  t.styledWriteLine(stdout, fgMagenta, "(w) List Chores")
  t.styledWriteLine(stdout, fgRed, "(e) Remove Chore")
  t.styledWriteLine(stdout, fgGreen, "(a) Add Chore")
  t.styledWriteLine(stdout, fgGreen, "(s) Save to File")
  t.styledWriteLine(stdout, fgCyan, "(d) Complete Chore")
  

when isMainModule:

  var is_over = false
  var chores: seq[Chore]
  var invalid_chore: bool = false
  var save_file: File

  if open(save_file, "save_file.txt", fmRead):
    defer: close(save_file)
    for line in save_file.lines:
      var vals = rsplit(line, ", ", maxsplit = 1)
      chores.add(Chore(name: vals[0], completed: (try: parseBool(vals[1]) except ValueError: false)))
    

  while not is_over:
    t.setBackgroundColor(stdout, bgBlack)

    if invalid_chore:
      t.styledWriteLine(stdout, fgRed, "Invalid input")
      invalid_chore = false

    displayMenu()

    var input = t.getch()
    case input:
      of 'q': 
        is_over = true
        t.styledWriteLine(stdout, fgGreen, "Have a good day!")
      of 'a':
        t.styledWriteLine(stdout, fgWhite, "Name of chore:")
        var new_chore:string 
        try: 
          new_chore = readLine(stdin) 
        except IOError, EOFError, CatchableError: 
          invalid_chore = true
          continue
        finally:
          if str.isEmptyOrWhitespace(new_chore):
            invalid_chore = true
            continue
        chores.add(createChore(new_chore)) 
      of 'w':
        t.styledWriteLine(stdout, fgWhite, "Chores List:")
        listChores(chores) 
      of 'e':
        t.styledWriteLine(stdout, fgWhite, "Which chore do you want to delete? Type number:")
        listChores(chores) 
        try:
          executeChoreCommand(chores, cDelete)
        except InvalidInput as err:
          invalidInput(err, invalid_chore) 
          continue
      of 'd':
        t.styledWriteLine(stdout, fgWhite, "Change chore: [COMPLETED]->[INCOMPLETE] & [INCOMPLETE]->[COMPLETE]")
        listChores(chores)
        try:
          executeChoreCommand(chores, cComplete)
        except InvalidInput as err:
          invalidInput(err, invalid_chore) 
          continue
      of 's':
        if open(save_file, save_path, fmWrite):
          defer: close(save_file)
          for chore in chores:
            writeLine(save_file, fmt"{chore.name}, {chore.completed}")
          echo "Save was successful!"
        else:
          echo "Unable to save"
      else: 
        echo "\n"
        continue

    echo "\n"
   
    t.resetAttributes(stdout)