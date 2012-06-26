PATH = require 'path'

PROCT = require '../dist/'

FIXTURES = PATH.join(__dirname, 'fixtures')


describe 'netstat', ->

    it 'should return a object of open addresses', (done) ->
        @expectCount(1)
        promise = PROCT.netstat()

        promise.fail(done)

        promise.then (result) ->
            expect(Array.isArray(result['0.0.0.0'])).toBeTruthy()
            return done()

        return

    return

describe 'findOpenPort', ->
    it 'should', (done) ->
        @expectCount(1)
        promise = PROCT.findOpenPort('127.0.0.1')

        promise.fail(done)

        promise.then (result) ->
            expect(result).toBe(1024)
            return done()

        return
    return
