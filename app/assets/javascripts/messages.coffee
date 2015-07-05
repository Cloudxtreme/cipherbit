sodium = window.sodium
host = window.location.host
public_key_key = "#{host}.public_key"
private_key_key = "#{host}.private_key"
storage = localStorage
public_key = -> sodium.from_hex(storage.getItem(public_key_key))
private_key = -> sodium.from_hex(storage.getItem(private_key_key))

generate_keys = ->
    keypair = sodium.crypto_box_keypair()
    storage.setItem(public_key_key, sodium.to_hex(keypair.publicKey))
    storage.setItem(private_key_key, sodium.to_hex(keypair.privateKey))

encrypt = (text, public_key) ->
    nonce = sodium.randombytes_buf(sodium.crypto_box_NONCEBYTES)
    sodium.crypto_box_easy(text, nonce, public_key, private_key())

$(document).ready ->
    generate_keys() if public_key() is null
    hex_public_key = sodium.to_hex(public_key())
    $('#pubkey').html(hex_public_key)
    $('#keyart').html("<pre>#{randomart(public_key())}</pre>")
    $('#encrypt').click ->
        # All values are raw byte arrays, to strings or hex, etc.
        destination_key = sodium.from_hex($('#destination_key').val())
        subject = $('#subject').val()
        body = $('#body').val()
        encrypted_subject = encrypt(subject, destination_key)
        encrypted_body = encrypt(body, destination_key)
        $('#subject').val(sodium.to_hex(encrypted_subject))
        $('#body').val(sodium.to_hex(encrypted_body))
