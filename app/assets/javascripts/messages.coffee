sodium = window.sodium
host = window.location.host
public_key_key = "#{host}.public_key"
private_key_key = "#{host}.private_key"
storage = localStorage

window.public_key = -> sodium.from_hex(storage.getItem(public_key_key) || '00')
window.private_key = -> sodium.from_hex(storage.getItem(private_key_key) || '00')

destination_key = ->
  field_content = $('#destination').val()
  expected_key_length = sodium.crypto_box_PUBLICKEYBYTES * 2 # hex strings use two characters per byte
  if field_content.length != expected_key_length
    alert("Recipient's key must be #{expected_key_length} characters")
    return
  sodium.from_hex(field_content)

encrypt = (text, public_key) ->
  nonce = sodium.randombytes_buf(sodium.crypto_box_NONCEBYTES)
  {
    ciphertext: sodium.crypto_box_easy(text, nonce, public_key, window.private_key()),
    nonce: nonce
  }

decrypt = (ciphertext, nonce, source) ->
  c = sodium.from_hex(ciphertext)
  n = sodium.from_hex(nonce)
  pub = sodium.from_hex(source)
  pvt = window.private_key()
  sodium.crypto_box_open_easy(c, n, pub, pvt)

decrypt_string = (ciphertext, nonce, source) ->
  sodium.to_string(decrypt(ciphertext, nonce, source))

decrypt_json = (ciphertext, nonce, source) ->
  JSON.parse(decrypt_string(ciphertext, nonce, source))

populate_message_and_submit = (bundle) ->
  $('#source').val(bundle.source_key)
  $('#metadata').val(sodium.to_hex(bundle.encrypted_metadata['ciphertext']))
  $('#metadata_nonce').val(sodium.to_hex(bundle.encrypted_metadata['nonce']))
  $('#body').val(sodium.to_hex(bundle.encrypted_body['ciphertext']))
  $('#body_nonce').val(sodium.to_hex(bundle.encrypted_body['nonce']))
  $('#messageform').submit()

# Template to render rows in the message inbox
message_row = _.template("""
  <tr>
    <td width="40%"><a href="/messages/<%= id %>/view"><%= metadata.subject %></a></td>
    <td width="20%"><%= metadata.sent_at %></td>
    <td width="15%"><%= source %></td>
  </tr>
""")

# Top-level functions called by views

window.initialize = ->
  generate_keys() if window.public_key().length == 1
  window.populate_key_info()

window.generate_keys = ->
  keypair = sodium.crypto_box_keypair()
  storage.setItem(public_key_key, sodium.to_hex(keypair.publicKey))
  storage.setItem(private_key_key, sodium.to_hex(keypair.privateKey))

window.populate_key_info = ->
  $('#pubkey').html(sodium.to_hex(window.public_key()))
  $('#keyart').html("<pre>#{randomart(window.public_key())}</pre>")


# Used by /messages/inbox

window.retrieve_messages = ->
  $.getJSON("/messages?key=#{sodium.to_hex(window.public_key())}", (data) ->
    table_html = document.createElement('table')
    $.each(data, ->
      id = this.id
      source = this.source
      metadata = decrypt_json(this.metadata.metadata, this.metadata.nonce, source)
      table_html += message_row({id: id, metadata: metadata, source: source}))
    $('#messagelist').append(table_html))

# Used by /messages/:id/view

window.decrypt_message = ->
  msg = JSON.parse($('#message').text())
  metadata = decrypt_json(msg.metadata.metadata, msg.metadata.nonce, msg.source)
  body = decrypt_string(msg.body.body, msg.body.nonce, msg.source)
  $('#subject').html(metadata.subject)
  $('#date').html(metadata.sent_at)
  $('#body').html(body)


# Used by /messages/new

window.encrypt_and_send = ->
  dest_key = destination_key()
  return if not dest_key
  source_key = sodium.to_hex(window.public_key())
  metadata =
    sent_at: new Date().toUTCString()
    subject: $('#form_subject').val()
  body = $('#form_body').val()

  bundle =
    source_key: source_key
    dest_key: dest_key
    encrypted_metadata: encrypt(JSON.stringify(metadata), dest_key)
    encrypted_body: encrypt(body, dest_key)

  populate_message_and_submit(bundle)

$(document).ready ->
  window.initialize()
