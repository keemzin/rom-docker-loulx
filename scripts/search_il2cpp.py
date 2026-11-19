import zipfile

with zipfile.ZipFile('ROM.apk') as apk:
    so64 = apk.read('lib/arm64-v8a/libslua.so')
    
for s in [b'czjz', b'gqde', b'czjzgqde']:
    idx = so64.find(s)
    found = hex(idx) if idx >= 0 else 'NOT FOUND'
    print(s, found)

# Check libil2cpp for czjzgqde - only search first 10MB to be fast
with zipfile.ZipFile('ROM.apk') as apk:
    libil2 = apk.read('lib/armeabi-v7a/libil2cpp.so')

print('libil2cpp armeabi-v7a len:', len(libil2))
idx = libil2.find(b'czjzgqde')
print('czjzgqde in libil2cpp:', hex(idx) if idx >= 0 else 'NOT FOUND')
if idx >= 0:
    print('Context:', list(libil2[max(0,idx-16):idx+32]))
