
nickname = ''

showError = (msg) ->
  block = $("#errorblock")
  block.html "<em>ERROR: #{msg}</em>"
  block.css "display", "block"

showMessage = (msg) ->
  block = $("#messages")
  block.append "<p>#{msg}</p>"

setNickname = (nick) ->
  nickname = nick
  $("#nickname").text nick

onEvent = (event) ->
  json = JSON.parse(event.data)
  switch json['type']
    when 'join'
      showMessage "<b>#{json['nickname']}</b> has joined"
    when 'depart'
      showMessage "<b>#{json['nickname']}</b> has left"
  console.log "Event received: #{JSON.stringify(json)}"

sendDepartMsg = ->
  navigator.sendBeacon "/depart", JSON.stringify({ nickname: nickname })
  undefined

initializeConnection = ->
  nick = await $.ajax '/request_nick'
  setNickname(nick.nickname)
  $("#messages").html ''
  src = new EventSource('/subscribe')
  src.addEventListener 'message', onEvent
  $.ajax
    type: 'GET'
    url: '/join'
    data: { 'nickname': nickname }
    error: -> showError "Could not connect to server"
  window.onunload = sendDepartMsg

$.readyException = console.error

$ ->
  unless EventSource?
    showError "Server-Sent Events are not supported in your browser"
    return
  await initializeConnection()
