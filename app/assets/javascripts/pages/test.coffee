$(document).on 'page:change', ->
  return unless document.body.id == 'test_test'

  faye = new Faye.Client('https://agileseason.com/faye')
  faye.subscribe '/events/test', (message) ->
    console.log(message)
