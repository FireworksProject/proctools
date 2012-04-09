CHPR = require 'child_process'

Q = require 'q'

EXECVP_REGEX = /^execvp\(\): /

# aOpts.command
# aOpts.args
exports.runCommand = (aOpts) ->
    deferred = Q.defer()
    encoding = 'utf8'
    command = aOpts.command
    args = aOpts.args

    child = CHPR.spawn(command, args)
    child.stdout.setEncoding encoding
    child.stderr.setEncoding encoding
    child.stdoutBuffer = ''
    child.stderrBuffer = ''

    child.stdout.on 'data', (chunk) ->
        child.stdoutBuffer += chunk
        return

    child.stderr.on 'data', (chunk) ->
        child.stderrBuffer += chunk

        if EXECVP_REGEX.test(chunk)
            err = new Error("failed to start child process")
            err.stack = child.stderrBuffer.replace(EXECVP_REGEX, '')
            return deferred.reject(err)
        return

    child.on 'exit', (code) ->
        if code
            err = new Error("child process exited with code #{code}")
            err.code = code
            err.stack = child.stderrBuffer
            return deferred.reject(err)

        child.exited = yes
        return deferred.resolve(child)

    return deferred.promise
