PATH = require 'path'

PROCT = require '../dist/'

FIXTURES = PATH.join(__dirname, 'fixtures')


describe 'error reporting', ->

    it 'should report error on bad command', (done) ->
        @expectCount(3)

        promise = PROCT.runCommand({command: 'foo'})

        promise.then ->
            expect().not.toExecute()
            return done()

        promise.fail (err) ->
            err or= {}
            expect(err.message).toBe('No such file or directory\n')
            expect(err.buffer.stderr).toBe('execvp(): No such file or directory\n')
            expect(err.buffer.stdout).toBe('')
            return done()

        return


    it 'should report error code and buffer stderr', (done) ->
        @expectCount(4)

        promise = PROCT.runCommand({command: PATH.join(FIXTURES, 'err-std-out-exit')})

        promise.then (result) ->
            expect().not.toExecute()
            return done()

        promise.fail (err) ->
            err or= {}
            expect(err.code).toBe(1)
            expect(err.message).toBe('child process exited with code 1')
            expect(err.buffer.stderr).toBe('stderr error out\n')
            expect(err.buffer.stdout).toBe('stdout standard out\n')
            return done()

        return


    it 'should return a timeout error on timeout', (done) ->
        @expectCount(4)

        cmd =
            command: 'node'
            args: [PATH.join(FIXTURES, 'server.js'), 8754]
            timeout: 100

        promise = PROCT.runCommand(cmd)

        promise.then (result) ->
            expect().not.toExecute()
            return done()

        promise.fail (err) ->
            err or= {}
            expect(err.code).toBe('TIMEOUT')
            expect(err.message).toMatch(/^process timeout: /)
            expect(err.buffer.stderr).toBe('')
            expect(err.buffer.stdout).toBe('http server started on 127.0.0.1:8754\n')
            return done()
        return

    return


describe 'command line arguments', ->

    it 'should pass arguments to the command', (done) ->
        @expectCount(2)
        cmd =
            command: PATH.join(FIXTURES, 'echo-arguments')
            args: ['foo', 'bar']

        promise = PROCT.runCommand(cmd)

        promise.then (result) ->
            expect(result.buffer.stdout).toBe('foo bar\n')
            expect(result.buffer.stderr).toBe('')
            return done()

        promise.fail (err) ->
            expect().not.toExecute()
            return done()
        return

    return


describe 'buffers', ->

    it 'should buffer stdout', (done) ->
        @expectCount(4)
        promise = PROCT.runCommand({command: 'ls'})

        promise.then (result) ->
            expect(result.buffer.stdout).toBeA('string')
            expect(result.buffer.stderr).toBeA('string')
            expect(result.buffer.stdout.length > 0).toBe(true)
            expect(result.buffer.stderr.length).toBe(0)
            return done()

        promise.fail (err) ->
            err or= {}
            expect().not.toExecute()
            return done()

        return


    it 'should buffer stderr', (done) ->
        @expectCount(4)
        promise = PROCT.runCommand({command: PATH.join(FIXTURES, 'err-out')})

        promise.then (result) ->
            expect(result.buffer.stdout).toBeA('string')
            expect(result.buffer.stderr).toBeA('string')
            expect(result.buffer.stdout.length).toBe(0)
            expect(result.buffer.stderr.length > 0).toBe(true)
            return done()

        promise.fail (err) ->
            err or= {}
            expect().not.toExecute()
            return done()

        return

    return


###
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
            timeLimit: 2000
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
###


reportError = (err) ->
    console.error()
    console.error("testing error:")
    console.error(err.stack)
    return
