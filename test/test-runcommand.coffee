PROCT = require '../'

it 'should bomb', ->
    promise = PROCT.runCommand({command: 'foo'})

    promise.then ->
        expect('should never be called').toBe('')
        return done()

    promise.fail (err) ->
        err or= {}
        expect(err.message).toBe('failed to start child process')
        return done()

    return
