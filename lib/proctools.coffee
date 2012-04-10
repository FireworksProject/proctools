CHPR = require 'child_process'
Buffer = require('buffer').Buffer

Q = require 'q'

EXECVP_REGEX = /^execvp\(\): /

# aOpts.command
# aOpts.args
# aOpts.background
# aOpts.buffer
exports.runCommand = (aOpts) ->
    deferred = Q.defer()
    encoding = 'utf8'
    command = aOpts.command
    args = aOpts.args
    fBackground = aOpts.background
    timeLimit = 1000
    timeout = null

    if aOpts.buffer
        buffer = if typeof aOpts.buffer is 'number' then aOpts.buffer else 1
    else buffer = off

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

    if not fBackground and buffer is off
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


# aRegex A RegExp or string
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


exports.kill = (pid) ->
    if not pid then return Q.call(-> null)
    cmd =
        command: 'kill'
        args: [pid]
    return exports.runCommand(cmd)


exports.killByName = (name) ->
    promise = exports.findProcess(name).then (procs) ->
        kills = procs.map (proc) ->
            return exports.kill(proc.pid)
        return Q.all(kills)
    return promise
