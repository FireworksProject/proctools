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


it 'should flag an exited command', ->
    promise = PROCT.runCommand({command: 'ls'})

    promise.then (result) ->
        expect(result.exited).toBe(true)
        return done()

    promise.fail (err) ->
        expect().not.toExecute()
        return done()
    return


describe 'buffers', ->

    it 'should buffer stdout', ->
        promise = PROCT.runCommand({command: 'ls'})

        promise.then (result) ->
            expect(result.stdoutBuffer).toBeA('string')
            expect(result.stderrBuffer).toBeA('string')
            expect(result.stdoutBuffer.length > 0).toBe(true)
            expect(result.stderrBuffer.length).toBe(0)
            expect(result.exited).toBe(true)
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
            expect(result.exited).toBe(true)
            return done()

        promise.fail (err) ->
            err or= {}
            expect().not.toExecute()
            return done()

        return

    return


describe 'command line arguments', ->

    it 'should pass arguments to the command', ->
        cmd =
            command: PATH.join(FIXTURES, 'echo-arguments')
            args: ['foo', 'bar']

        promise = PROCT.runCommand(cmd)

        promise.then (result) ->
            expect(result.exited).toBe(true)
            expect(result.stdoutBuffer).toBe('foo bar\n')
            return done()

        promise.fail (err) ->
            expect().not.toExecute()
            return done()
        return

    return


describe 'background processes', ->

    afterEach ->
        killed = ->
            return done()

        PROCT.killByName('server-fixture')
            .then(killed).fail(reportError)
        return


    it 'should return a timeout error for hung processes', ->
        cmd =
            command: 'node'
            args: [PATH.join(FIXTURES, 'server.js'), 8754]

        promise = PROCT.runCommand(cmd)

        promise.then (result) ->
            expect().not.toExecute()
            return done()

        promise.fail (err) ->
            err or= {}
            expect(err.code).toBe('PROCHUNG')
            expect(err.message).toMatch(/^process timeout: /)
            return done()
        return


    it 'should return immediately when background flag is set', ->
        cmd =
            command: 'node'
            args: [PATH.join(FIXTURES, 'server.js'), 8755]
            background: yes

        promise = PROCT.runCommand(cmd)

        promise.then (result) ->
            expect(result.exited).not.toBeTruthy()
            expect(result.stdoutBuffer).toBe('')
            expect(result.stderrBuffer).toBe('')

            result.stdout.on 'data', (chunk) ->
                expect(chunk).toBe('http server started on 127.0.0.1:8755\n')
                return done()
            return

        promise.fail (err) ->
            expect().not.toExecute()
            return done()
        return


    it 'should return after stdout when buffer flag is set', ->
        cmd =
            command: 'node'
            args: [PATH.join(FIXTURES, 'delay.js')]
            buffer: 13

        promise = PROCT.runCommand(cmd)

        promise.then (result) ->
            expect(result.exited).not.toBeTruthy()
            expect(result.stdoutBuffer).toBe('first stdout second stdout')
            expect(result.stderrBuffer).toBe('')
            return done()

        promise.fail (err) ->
            reportError(err)
            expect().not.toExecute()
            return done()
        return

    return


reportError = (err) ->
    console.error()
    console.error("testing error:")
    console.error(err.stack)
    return
