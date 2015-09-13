# Signing keypair
pub_key = '4ea22c84ee4119e5a8867dd3605cd8c2714b076a48d78db51a0dfda771be0c8d'
pvt_key = '3fb6819d49a06c655766987054752a6374028a8f71a5e1fe487189c6bc86ef9b4ea22c84ee4119e5a8867dd3605cd8c2714b076a48d78db51a0dfda771be0c8d'

create_sandbox = -> window.sandbox = sinon.sandbox.create()
restore_sandbox = -> sandbox.restore()
hooks =
  beforeEach: create_sandbox
  afterEach: restore_sandbox


module 'When accessing storage', hooks

test 'public key is fetched correctly', ->
  sandbox.stub(window.storage, 'getItem').withArgs('public_key').returns(pub_key)
  ok(public_key_hex() == pub_key, 'Keys matched')

test 'private key is fetched correctly', ->
  sandbox.stub(window.storage, 'getItem').withArgs('private_key').returns(pvt_key)
  ok(sodium.to_hex(private_key()) == pvt_key, 'Keys matched')


module 'When encrypting and signing'

obj = encrypt_and_sign('cipherbit test', sodium.from_hex(pub_key))
hex_regex = /^[0-9a-f]+$/

test 'it returns an object with ciphertext', ->
  ok(obj.hasOwnProperty('ciphertext'), 'Ciphertext present')

test 'the ciphertext is a hex string', ->
  ctext = obj.ciphertext
  ok(hex_regex.test(ctext), "Ciphertext #{ctext} is a hex string")

test 'it returns an object with nonce', ->
  ok(obj.hasOwnProperty('nonce'), 'Nonce present')

test 'the nonce is a hex string', ->
  nonce = obj.nonce
  ok(hex_regex.test(nonce), "Nonce #{nonce} is a hex string")

test 'it returns an object with signature', ->
  ok(obj.hasOwnProperty('signature'), 'Signature present')

test 'the signature is a hex string', ->
  sig = obj.signature
  ok(hex_regex.test(sig), "Signature #{sig} is a hex string")

module 'When decrypting and verifying', hooks

test 'safe_decrypt_string escapes strings', ->
  window.decrypt_string = sandbox.stub().returns('<&?>')
  ok(safe_decrypt_string(null, null, null) == '&lt;&amp;?&gt;',
     'String was escaped')

test 'safe_decrypt_json escapes value strings', ->
  unsafe_json = { 'foo': '<&?>', 'bar': 'hi&' }
  window.decrypt_json = sandbox.stub().returns(unsafe_json)
  ok(safe_decrypt_json(null, null, null).foo == '&lt;&amp;?&gt;',
     'First value was escaped')
  ok(safe_decrypt_json(null, null, null).bar == 'hi&amp;',
     'Second value was escaped')
