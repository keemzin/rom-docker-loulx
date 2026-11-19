with open('TROUBLESHOOTING.md', 'r', encoding='utf-8') as f:
    text = f.read()

old = '1. **Cipher**: DES in ECB mode.'
new = '''1. **Key Origin in APK**: Found in `lib/armeabi-v7a/libslua.so` (and `lib/arm64-v8a/libslua.so`) right beside the string `"czjzgqde"` inside the native `luaL_loadbuffer` C++ loader.
2. **Cipher**: DES in ECB mode.'''

if old in text:
    text = text.replace(old, new)
    text = text.replace('2. **Key**:', '3. **Key**:').replace('3. **Header**:', '4. **Header**:').replace('4. **Padding**:', '5. **Padding**:')
    with open('TROUBLESHOOTING.md', 'w', encoding='utf-8') as f:
        f.write(text)
    print('Updated!')
