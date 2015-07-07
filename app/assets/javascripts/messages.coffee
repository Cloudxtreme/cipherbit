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
        ciphertext: sodium.crypto_box_easy(text, nonce, public_key, private_key()),
        nonce: nonce
    }

$(document).ready ->
    generate_keys() if public_key() is null
    $('#pubkey').html(sodium.to_hex(public_key()))
    $('#keyart').html("<pre>#{randomart(public_key())}</pre>")

    # /new
    $('#encryptandsend').click ->
        # All values are raw byte arrays that have had sodium.to_hex called on them
        dest_key = destination_key()
        return if not dest_key

        # To be encrypted with the destination key
        metadata =
            sent_at: new Date().toUTCString()
            subject: $('#form_subject').val()
        body = $('#form_body').val()

        encrypted_metadata = encrypt(JSON.stringify(metadata), dest_key)
        encrypted_body = encrypt(body, dest_key)

        # Set form values for submission
        $('#source').val(sodium.to_hex(public_key()))

        $('#metadata').val(sodium.to_hex(encrypted_metadata['ciphertext']))
        $('#metadata_nonce').val(sodium.to_hex(encrypted_metadata['nonce']))

        $('#body').val(sodium.to_hex(encrypted_body['ciphertext']))
        $('#body_nonce').val(sodium.to_hex(encrypted_body['nonce']))

        $('#messageform').submit()
