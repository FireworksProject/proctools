PATH = require 'path'

PROCT = require '../dist/'

FIXTURES = PATH.join(__dirname, 'fixtures')

it 'should throw an error for invalid parameters', (done) ->
    @expectCount(1)
    try
        PROCT.kill('foo')
    catch err
        expect(err.message).toBe("process id parameter must be a number")
    return done()


it 'should resolve `false` if the process does not exist', (done) ->
    @expectCount(1)
    promise = PROCT.kill(999999999)

    promise.fail(done).then (result) ->
        expect(result).toBe(false)
        return done()

    return


it 'should resolve `true` if the process exists', (done) ->
    @expectCount(2)

    gotData = no
    gotExit = no
    maybeDone = (ondata, onexit) ->
        if ondata then gotData = yes
        if onexit then gotExit = yes
        if gotData and gotExit then done()
        return

    cmd =
        command: 'node'
        args: [PATH.join(FIXTURES, 'server.js'), 8254]

    child = PROCT.runBackground(cmd)
    child.stdout.on 'data', (chunk) ->
        promise = PROCT.kill(child.pid)

        promise.fail(done).then (result) ->
            expect(result).toBe(true)
            return maybeDone(true)
        return

    child.on 'exit', (code) ->
        expect(code).toBe(1)
        return maybeDone(null, true)

    return
