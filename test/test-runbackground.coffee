PATH = require 'path'

PROCT = require '../dist/'

FIXTURES = PATH.join(__dirname, 'fixtures')


describe 'stdio', ->

    it 'should decode stdout', (done) ->
        @expectCount(2)
        stdout = ''
        stderr = ''

        proc = PROCT.runBackground({command: 'ls'})

        proc.stdout.on 'data', (chunk) ->
            stdout += chunk
            return

        proc.stderr.on 'data', (chunk) ->
            stderr += chunk
            return

        proc.on 'exit', ->
            expect(stdout.length > 0).toBe(true)
            expect(stderr.length).toBe(0)
            return done()

        return


    it 'should decode stderr', (done) ->
        @expectCount(2)
        stdout = ''
        stderr = ''

        proc = PROCT.runBackground({command: PATH.join(FIXTURES, 'err-out')})

        proc.stdout.on 'data', (chunk) ->
            stdout += chunk
            return

        proc.stderr.on 'data', (chunk) ->
            stderr += chunk
            return

        proc.on 'exit', ->
            expect(stderr.length > 0).toBe(true)
            expect(stdout.length).toBe(0)
            return done()

        return

    return


describe 'error reporting', ->

    it 'should fire error event on bad command', (done) ->
        @expectCount(1)
        proc = PROCT.runBackground({command: 'foo'})
        proc.on 'error', (err) ->
            expect(err.message).toBe('No such file or directory\n')
            return done()
        return

    return


describe 'command line arguments', ->

    it 'should pass arguments to the command', (done) ->
        @expectCount(1)
        cmd =
            command: PATH.join(FIXTURES, 'echo-arguments')
            args: ['foo', 'bar']

        proc = PROCT.runBackground(cmd)

        stdout = ''
        proc.stdout.on 'data', (chunk) ->
            stdout += chunk
            return

        proc.on 'exit', ->
            expect(stdout).toBe('foo bar\n')
            return done()

        return

    return


describe 'start', ->

    gServerProc = null

    afterEach (done) ->
        if gServerProc then gServerProc.kill()
        return done()


    it 'should report stderr if no stdout detected after a timeout', (done) ->
        @expectCount(3)
        cmd =
            command: PATH.join(FIXTURES, 'err-out')
            timeout: 50

        proc = PROCT.start cmd, (err, proc) ->
            expect(proc).toBeUndefined()
            expect(err.buffer.stdout).toBe('')
            expect(err.buffer.stderr).toBe('stderr error out\n')
            return done()
        return


    it 'should call the callback after stdout', (done) ->
        @expectCount(2)
        cmd =
            command: 'node'
            args: [PATH.join(FIXTURES, 'server.js'), 8154]

        gServerProc = PROCT.start cmd, (err, proc) ->
            expect(proc.buffer.stdout).toBe('http server started on 127.0.0.1:8154\n')
            expect(proc.buffer.stderr).toBe('')
            return done()
        return

    return
