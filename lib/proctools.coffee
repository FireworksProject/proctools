CHPR = require 'child_process'
Buffer = require('buffer').Buffer

Q = require 'q'

EXECVP_REGEX = /^execvp\(\): /

# Run a command
# aOpts.command The name of the command to run
# aOpts.args An Array of arguments to pass to the command
# aOpts.timeLimit A number of milliseconds to wait before timing out
# aOpts.background Flag for background processes
# aOpts.buffer Flag for buffering stdout
#
# If the background flag is set, then runCommand() resolves the process handle
# after a single turn of the event loop and does not wait for an exit or stdout
# event.
#
# If the buffer flag is set to true, then runCommand() resolves the process
# handle after the first stdout event. If the buffer flag is a number greater
# than 0, runCommand() will not resolve until the byte length of the stdout
# buffer reaches the given number. When the buffer flag is set, runCommand()
# will still reject with a timeout if the buffer is not reached within the
# timelimit specified on aOpts.timelimit.
exports.runCommand = (aOpts) ->
    deferred = Q.defer()
    encoding = 'utf8'
    command = aOpts.command
    args = aOpts.args
    fBackground = aOpts.background

    timeLimit = if typeof aOpts.timeLimit is 'number'
        aOpts.timeLimit
    else 1000

    if aOpts.buffer
        buffer = if typeof aOpts.buffer is 'number' then aOpts.buffer else 1
    else buffer = off

    timeout = null
    resolve = (err, result) ->
        if timeout isnt null
            clearTimeout(timeout)
            timeout = null
        if err then return deferred.reject(err)
        return deferred.resolve(result)

    timeoutHandler = ->
        msg = "process timeout: #{command}"
        if Array.isArray(args) and args.length
            msg += (" #{args.join(' ')}")
        err = new Error(msg)
        err.code = 'PROCHUNG'
        return resolve(err)

    if not fBackground
        timeout = setTimeout(timeoutHandler, timeLimit)

    child = CHPR.spawn(command, args)
    child.stdout.setEncoding encoding
    child.stderr.setEncoding encoding
    child.stdoutBuffer = ''
    child.stderrBuffer = ''

    child.stdout.on 'data', (chunk) ->
        child.stdoutBuffer += chunk
        if buffer and Buffer.byteLength(child.stdoutBuffer, encoding) >= buffer
            return resolve(null, child)
        return

    child.stderr.on 'data', (chunk) ->
        child.stderrBuffer += chunk

        if EXECVP_REGEX.test(chunk)
            err = new Error("failed to start child process")
            err.stack = child.stderrBuffer.replace(EXECVP_REGEX, '')
            return resolve(err)
        return

    child.on 'exit', (code) ->
        if code
            err = new Error("child process exited with code #{code}")
            err.code = code
            err.stack = child.stderrBuffer
            return resolve(err)

        child.exited = yes
        return resolve(null, child)

    if fBackground then resolve(null, child)
    return deferred.promise


# Find a running process by the given name
# aName May be a string name or RegExp to match
# Processes can be named in Node.js using `process.title = "myname"`
exports.findProcess = (aRegex) ->
    cmd =
        command: 'ps'
        args: ['x']

    promise = exports.runCommand(cmd).then (result) ->
        regex = if aRegex instanceof RegExp then aRegex
        else new RegExp(aRegex)

        isNotEmpty = (char) ->
            if char then return yes else return no

        lines = result.stdoutBuffer.split('\n')
        results = []
        for line in lines
            if regex.test(line)
                parts = line.split(/\s/).filter(isNotEmpty)
                results.push({pid: parseInt(parts[0], 10), title: parts[4]})
        return results

    return promise


# Kill a process by process id
# aPID If aPID is a number then it is assumed to be a process ID to kill
exports.kill = (aPID) ->
    if typeof aPID isnt 'number' then return Q.call(-> null)
    cmd =
        command: 'kill'
        args: [aPID]
    return exports.runCommand(cmd)


# Kill a process by name
# aName May be a string name or RegExp
# Processes can be named in Node.js using `process.title = "myname"`
exports.killByName = (aName) ->
    promise = exports.findProcess(aName).then (procs) ->
        kills = procs.map (proc) ->
            return exports.kill(proc.pid)
        return Q.all(kills)
    return promise


# Find an open port on the local machine (uses netstat)
exports.findOpenPort = ->
    parseNetstat = (result) ->
        usedPorts = []
        lines = result.stdoutBuffer.split('\n').filter (line) ->
            if /^unix/.test(line) then return no else return yes

        for line in lines
            addr = line.split(/[\s]+/)[3]
            if /:[0-9]{1,5}/.test(addr)
                portString = addr.split(':').pop()
                try
                    port = parseInt(portString, 10)
                catch intErr
                    continue
                usedPorts.push(port)

        for port in [1024..65535]
            if not (port in usedPorts) then return port
        return null

    opts =
        command: 'netstat'
        args: ['-a', '-n']

    promise = exports.runCommand(opts).then(parseNetstat)
    return promise
