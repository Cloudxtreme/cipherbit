BLANK_KEY_HEX = '00'

sodium = window.sodium
public_key_key = "public_key"
private_key_key = "private_key"
window.storage = localStorage

window.private_key = -> sodium.from_hex(storage.getItem(private_key_key) || BLANK_KEY_HEX)
window.private_encryption_key = -> sodium.crypto_sign_ed25519_sk_to_curve25519(private_key())

destination_key = ->
  field_content = $('#destination').val()
  expected_key_length = sodium.crypto_sign_PUBLICKEYBYTES * 2 # hex strings use two characters per byte
  if field_content.length != expected_key_length
    alert("Recipient's key must be #{expected_key_length} characters")
    return
  sodium.from_hex(field_content)

# Return a JSON object with hex-encoded keys for the ciphertext, nonce, and detached signature.
window.encrypt_and_sign = (text, public_key) ->
  nonce = sodium.randombytes_buf(sodium.crypto_box_NONCEBYTES)
  public_encryption_key = sodium.crypto_sign_ed25519_pk_to_curve25519(public_key)
  ciphertext = sodium.crypto_box_easy(text, nonce, public_encryption_key, private_encryption_key())
  signature = sodium.crypto_sign_detached(sodium.to_hex(ciphertext), private_key())
  {
    ciphertext: sodium.to_hex(ciphertext),
    nonce: sodium.to_hex(nonce),
    signature: sodium.to_hex(signature)
  }

# Accepts hex strings
window.decrypt = (ciphertext, nonce, source) ->
  c = sodium.from_hex(ciphertext)
  n = sodium.from_hex(nonce)
  pub = sodium.crypto_sign_ed25519_pk_to_curve25519(sodium.from_hex(source))
  pvt = private_encryption_key()
  sodium.crypto_box_open_easy(c, n, pub, pvt)

window.decrypt_string = (ciphertext, nonce, source) ->
  sodium.to_string(decrypt(ciphertext, nonce, source))

window.safe_decrypt_string = (ciphertext, nonce, source) ->
  _.escape(decrypt_string(ciphertext, nonce, source))

window.decrypt_json = (ciphertext, nonce, source) ->
  JSON.parse(decrypt_string(ciphertext, nonce, source))

window.safe_decrypt_json = (ciphertext, nonce, source) ->
  raw_obj = decrypt_json(ciphertext, nonce, source)
  safe_obj = {}
  _.each(raw_obj, (value, key, list) ->
    safe_obj[key] = _.escape(value))
  safe_obj

populate_message_and_submit = (bundle) ->
  metadata = JSON.stringify(bundle.metadata)
  body = JSON.stringify(bundle.body)
  $('#source').val(bundle.source_key)
  $('#metadata').val(metadata)
  $('#body').val(body)
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

window.public_key_hex = -> storage.getItem(public_key_key) || BLANK_KEY_HEX
window.public_key = -> sodium.from_hex(public_key_hex())

window.initialize = ->
  generate_keys() if public_key().length == 1
  populate_key_info()

window.generate_keys = ->
  keypair = sodium.crypto_sign_keypair()
  pub_hex = sodium.to_hex(keypair.publicKey)
  pvt_hex = sodium.to_hex(keypair.privateKey)
  set_public_private_keys(pub_hex, pvt_hex)

window.set_public_private_keys = (public_key_hex, private_key_hex) ->
  storage.setItem(public_key_key, public_key_hex)
  storage.setItem(private_key_key, private_key_hex)

window.populate_key_info = ->
  $('#pubkey').html(public_key_hex())
  $('#keyart').html("<pre>#{randomart(public_key())}</pre>")


# Used by /messages/inbox

window.retrieve_messages = ->
  $.getJSON("/messages?key=#{public_key_hex()}", (data) ->
    table_html = document.createElement('table')
    $.each(data, ->
      id = this.id
      source = this.source
      metadata = safe_decrypt_json(this.metadata.ciphertext, this.metadata.nonce, source)
      table_html += message_row({id: id, metadata: metadata, source: source}))
    $('#messagelist').append(table_html))

# Used by /messages/:id/view

window.decrypt_message = ->
  msg = JSON.parse($('#message').text())
  metadata = safe_decrypt_json(msg.metadata.ciphertext, msg.metadata.nonce, msg.source)
  body = safe_decrypt_string(msg.body.ciphertext, msg.body.nonce, msg.source)
  $('#subject').html(metadata.subject)
  $('#date').html(metadata.sent_at)
  $('#body').html(body)


# Used by /messages/new

window.encrypt_and_send = ->
  dest_key = destination_key()
  return if not dest_key
  source_key = public_key_hex()
  metadata =
    sent_at: new Date().toUTCString()
    subject: $('#form_subject').val()
  body = $('#form_body').val()

  bundle =
    source_key: source_key
    dest_key: dest_key
    metadata: encrypt_and_sign(JSON.stringify(metadata), dest_key)
    body: encrypt_and_sign(body, dest_key)

  populate_message_and_submit(bundle)

$(document).ready ->
  initialize()
