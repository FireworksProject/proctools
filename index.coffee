CHPR = require 'child_process'

Q = require 'q'

EXECVP_REGEX = /^execvp\(\): /


exports.runCommand = (aOpts) ->
    deferred = Q.defer()
    encoding = 'utf8'
    command = aOpts.command
    args = aOpts.args
    timeout = if typeof aOpts.timeout is 'number' then aOpts.timeout
    else null
    stderrBuffer = ''
    stdoutBuffer = ''

    resolve = (err, proc) ->
        if timeout isnt null
            clearTimeout(timeout)
            timeout = null

        buffer =
            stderr: stderrBuffer
            stdout: stdoutBuffer

        if err
            err.buffer = buffer
            return deferred.reject(err)

        proc.buffer = buffer
        return deferred.resolve(proc)

    if timeout isnt null
        timeout = setTimeout(->
            proc.kill()
            msg = "process timeout: #{command}"
            if Array.isArray(args) and args.length
                msg += (" #{args.join(' ')}")
            err = new Error(msg)
            err.code = 'TIMEOUT'
            return resolve(err)
        , timeout)

    proc = CHPR.spawn(command, args)

    proc.stdout.setEncoding(encoding)
    proc.stderr.setEncoding(encoding)

    proc.stderr.on 'data', (chunk) ->
        stderrBuffer += chunk
        if EXECVP_REGEX.test(chunk)
            err = new Error(stderrBuffer.replace(EXECVP_REGEX, ''))
            return resolve(err)
        return

    proc.stdout.on 'data', (chunk) ->
        stdoutBuffer += chunk
        return

    proc.on 'exit', (code) ->
        if code
            err = new Error("child process exited with code #{code}")
            err.code = code
            return resolve(err)

        return resolve(null, proc)

    return deferred.promise


exports.runBackground = (aOpts) ->
    encoding = 'utf8'
    command = aOpts.command
    args = aOpts.args

    proc = CHPR.spawn(command, args)

    stderrBuffer = ''
    proc.stdout.setEncoding(encoding)
    proc.stderr.setEncoding(encoding)

    onerror = (chunk) ->
        stderrBuffer += chunk
        if EXECVP_REGEX.test(chunk)
            err = new Error(stderrBuffer.replace(EXECVP_REGEX, ''))
            return proc.emit('error', err)

        if stderrBuffer.length > 2048
            proc.stderr.removeListener('data', onerror)
            return
        return

    proc.stderr.on('data', onerror)
    return proc


exports.start = (aOpts, aCallback) ->
    timeout = if typeof aOpts.timeout is 'number' then aOpts.timeout
    else 1000
    stdoutBuffer = ''
    stderrBuffer = ''

    resolved = no
    resolve = (err) ->
        if resolved then return
        resolved = yes
        if timeout isnt null then clearTimeout(timeout)
        buffer =
            stdout: stdoutBuffer
            stderr: stderrBuffer

        if err
            err.buffer = buffer
            aCallback(err)
        else
            proc.buffer = buffer
            aCallback(null, proc)
        proc.stdout.removeListener('data', onstdout)
        proc.stderr.removeListener('data', onstderr)
        return

    timeout = setTimeout(->
        proc.kill()
        msg = "process timeout: #{aOpts.command}"
        if Array.isArray(aOpts.args) and aOpts.args.length
            msg += (" #{aOpts.args.join(' ')}")
        err = new Error(msg)
        err.code = 'TIMEOUT'
        return resolve(err)
    , timeout)

    onstdout = (chunk) ->
        stdoutBuffer = chunk
        return resolve()

    onstderr = (chunk) ->
        stderrBuffer += chunk
        return

    proc = exports.runBackground(aOpts)

    proc.on('error', resolve)
    proc.stdout.on('data', onstdout)
    proc.stderr.on('data', onstderr)
    return proc


exports.kill = (aPID) ->
    if typeof aPID isnt 'number'
        msg = "process id parameter must be a number"
        throw new Error(msg)

    cmd =
        command: 'kill'
        args: [aPID]

    onfail = (err) ->
        stderr = err.buffer.stderr
        if /No such process/.test(stderr)
            return false
        return Q.reject(err)

    promise = exports.runCommand(cmd).fail(onfail).then (result) ->
        if result then return true
        return false

    return promise
