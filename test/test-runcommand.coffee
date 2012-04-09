PATH = require 'path'

PROCT = require '../'

FIXTURES = PATH.join(__dirname, 'fixtures')


it 'should report error on bad command', ->
    promise = PROCT.runCommand({command: 'foo'})

    promise.then ->
        expect().not.toExecute()
        return done()

    promise.fail (err) ->
        err or= {}
        expect(err.message).toBe('failed to start child process')
        return done()

    return


it 'should buffer stdout', ->
    promise = PROCT.runCommand({command: 'ls'})

    promise.then (result) ->
        expect(result.stdoutBuffer).toBeA('string')
        expect(result.stderrBuffer).toBeA('string')
        expect(result.stdoutBuffer.length > 0).toBe(true)
        expect(result.stderrBuffer.length).toBe(0)
        return done()

    promise.fail (err) ->
        err or= {}
        expect().not.toExecute()
        return done()

    return


it 'should buffer stderr', ->
    promise = PROCT.runCommand({command: PATH.join(FIXTURES, 'err-out')})

    promise.then (result) ->
        expect(result.stdoutBuffer).toBeA('string')
        expect(result.stderrBuffer).toBeA('string')
        expect(result.stderrBuffer).toBe('stderr error out\n')
        expect(result.stdoutBuffer.length > 0).toBe(false)
        return done()

    promise.fail (err) ->
        err or= {}
        expect().not.toExecute()
        return done()

    return


it 'should report error code and buffer stderr', ->
    promise = PROCT.runCommand({command: PATH.join(FIXTURES, 'err-std-out-exit')})

    promise.then (result) ->
        expect().not.toExecute()
        return done()

    promise.fail (err) ->
        err or= {}
        expect(err.code).toBe(1)
        expect(err.message).toBe('child process exited with code 1')
        expect(err.stack).toBe('stderr error out\n')
        return done()

    return


it 'should pass arguments to the command', ->
    cmd =
        command: PATH.join(FIXTURES, 'echo-arguments')
        args: ['foo', 'bar']

    promise = PROCT.runCommand(cmd)

    promise.then (result) ->
        expect(result.stdoutBuffer).toBe('foo bar\n')
        return done()

    promise.fail (err) ->
        expect().not.toExecute()
        return done()
    return


it 'should flag an exited command', ->
    promise = PROCT.runCommand({command: 'ls'})

    promise.then (result) ->
        expect(result.exited).toBeTruthy()
        return done()

    promise.fail (err) ->
        expect().not.toExecute()
        return done()
    return
