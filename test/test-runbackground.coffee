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
