
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

messyEscape = (str) ->
  # I know this isn't the neatest way to do this, but meh. This is
  # just a prototype.
  $("<div>").text(str).html()

onEvent = (event) ->
  json = JSON.parse(event.data)
  switch json['type']
    when 'join'
      showMessage "<b>#{messyEscape json['nickname']}</b> has joined"
    when 'depart'
      showMessage "<b>#{messyEscape json['nickname']}</b> has left"
    when 'change_nick'
      old_ = messyEscape json['old']
      new_ = messyEscape json['new']
      showMessage "<b>#{old_}</b> is now known as <b>#{new_}</b>"
    when 'message'
      sender = messyEscape json['sender']
      contents = messyEscape json['contents']
      showMessage "<b>#{sender}: </b> #{contents}"
    else
      console.log "Event received: #{JSON.stringify(json)}"

sendDepartMsg = ->
  navigator.sendBeacon "/depart", JSON.stringify({ nickname: nickname })
  undefined

isValidNick = (nick) ->
  return false if nick.length < 1 or nick.length > 25
  return false if /[^-A-Za-z0-9_ +]/.test(nick)
  true

inputNewNick = ->
  result = prompt "New nickname:", nickname
  if result and isValidNick(result)
    $.ajax
      type: 'GET'
      url: '/change_nick'
      data: { 'old': nickname, 'new': result }
    setNickname(result)
  else
    alert "Invalid nickname (must be between 1 and 25 characters and only consist of alphanumerics, space, or _-+"

sendMessage = ->
  value = $("#message_text").val()
  $("#message_text").val ""
  $.ajax
    type: 'POST'
    url: '/send'
    data: JSON.stringify({ 'sender': nickname, 'contents': value })

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
  $("#message_text").val ""
  $("#change_nick").click inputNewNick
  $("#send_message").click sendMessage
  $("#message_text").keyup (event) ->
    if event.keyCode == 13
      event.preventDefault()
      sendMessage()
