CHPR = require 'child_process'

Q = require 'q'

EXECVP_REGEX = /^execvp\(\): /


# aOpts.command
# aOpts.args
# aOpts.timeout
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


# aOpts.command
# aOpts.args
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


# aOpts.command
# aOpts.args
# [aOpts.timeout = 1000]
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


exports.netstat = ->
    cmd =
        command: 'netstat'
        args: ['-a', '-n', '-p']
        timeout: 5000

    promise = exports.runCommand(cmd).then (proc) ->
        result = {}
        lines = proc.buffer.stdout.split('\n')
        lines.forEach (line) ->
            if /^(tcp|udp)/.test(line)
                line = parseLine(line)
                item = result[line.ip]
                if not item
                    item = result[line.ip] = []
                item.push({port: line.port, pid: line.pid, name: line.name})
            return
        return result

    parseLine = (line) ->
        parts = line.split(/[\s]+/)
        address = parts[3]
        proc = parts[6]
        parts = address.split(':')
        port = parts.pop()
        ip = parts.shift() or ''
        [pid, name] = proc.split('/')
        if not pid or pid is '-' then pid = null
        if not name then name = null
        return {ip: ip, port: port, pid: pid, name: name}
    return promise


exports.findOpenPort = (ip) ->
    promise = exports.netstat().then (result) ->
        used = []
        addresses = result['0.0.0.0'] or []
        addresses = addresses.concat(result[''] or [])
        addresses = addresses.concat(result[ip] or [])

        for addr in addresses
            used.push(addr.port)

        for port in [1024..65535]
            if not (port in used) then return port

        return null
    return promise
