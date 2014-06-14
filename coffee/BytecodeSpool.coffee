class BytecodeSpool

  constructor: (bytecodes) ->
    try
      @spool = Opal.BytecodeSpool.$new bytecodes
    catch e
      console.error e.stack
      throw e

  visibleState: ->
    try
      map = @spool.$visible_state().map
      breakpoint:     map.breakpoint
      numStepsQueued: map.num_steps_queued
      isDone:         map.is_done
    catch e
      console.error e.stack
      throw e

  queueRunUntil: (breakpoint) ->
    try
      @spool.$queue_run_until breakpoint
    catch e
      console.error e.stack
      throw e

  getNextBytecode: (isResultTruthy, gosubbingLabel, gotoingLabel, stackSize) ->
    gosubbingLabel = Opal.NIL if gosubbingLabel == null
    gotoingLabel   = Opal.NIL if gotoingLabel == null
    stackSize      = Opal.NIL if stackSize == null
    try
      result = @spool.$get_next_bytecode isResultTruthy,
        gosubbingLabel, gotoingLabel, stackSize
      if result == Opal.NIL then null else result
    catch e
      console.error e.stack
      throw e

  isDone: ->
    try
      @spool['$is_done?']()
    catch e
      console.error e.stack
      throw e

  terminateEarly: ->
    try
      @spool['$terminate_early']()
    catch e
      console.error e.stack
      throw e

  goto: (label, stackSize) ->
    label = Opal.NIL if label == null
    stackSize = Opal.NIL if stackSize == null
    try
      @spool['$goto'](label, stackSize)
    catch e
      console.error e.stack
      throw e

  gosub: (label) ->
    label = Opal.NIL if label == null
    try
      @spool['$gosub'](label)
    catch e
      console.error e.stack
      throw e

module.exports = BytecodeSpool
