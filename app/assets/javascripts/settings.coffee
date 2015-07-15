window.show_settings = ->
  settings =
    public_key: window.public_key_hex()
    private_key: sodium.to_hex(window.private_key())
  $('#current-settings').val(JSON.stringify(settings, null, 2))

window.setup_settings_button = ->
  $('#save-settings').click ->
    new_settings = JSON.parse($('#import-settings').val())
    window.set_public_private_keys(new_settings.public_key, new_settings.private_key)
