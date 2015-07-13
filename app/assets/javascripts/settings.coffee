window.show_settings = ->
  $('#jsonsettings').val(JSON.stringify(
    public_key: sodium.to_hex(window.public_key())
    private_key: sodium.to_hex(window.private_key())
  ))
