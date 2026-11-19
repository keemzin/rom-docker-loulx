import zipfile

# Search for DES key in both libslua.so files
qj_key = bytes([64, 160, 144, 192, 96, 128, 0, 128])  # Known QJ APK key

with zipfile.ZipFile('client/quick_jump_rom.apk') as apk:
    so_qj = apk.read('lib/armeabi-v7a/libslua.so')
    idx = so_qj.find(b'czjzgqde')
    print('QJ czjzgqde at:', hex(idx))
    print('QJ after:', list(so_qj[idx+8:idx+48]))
    
    ki = so_qj.find(qj_key)
    print('QJ key idx in QJ libslua:', hex(ki) if ki >= 0 else 'NOT FOUND')
    if ki >= 0:
        print('Context:', list(so_qj[ki-8:ki+16]))

with zipfile.ZipFile('ROM.apk') as apk:
    so_rom = apk.read('lib/armeabi-v7a/libslua.so')
    
    # Search for QJ key in ROM libslua
    ki_rom = so_rom.find(qj_key)
    print('QJ key in ROM libslua:', hex(ki_rom) if ki_rom >= 0 else 'NOT FOUND')
    
    idx = so_rom.find(b'czjzgqde')
    print('ROM czjzgqde at:', hex(idx))
    
    # Search around czjzgqde for any 8-byte sequences that look like DES keys
    # DES key parity: each byte has odd parity on the low 7 bits
    region = so_rom[max(0,idx-200):idx+200]
    print('Region around czjzgqde:')
    for i in range(0, len(region), 8):
        chunk = region[i:i+8]
        if len(chunk) == 8:
            # Check if it could be a key (non-zero, varied)
            if max(chunk) > 100 and min(chunk) < 200 and len(set(chunk)) > 4:
                print(f'  offset {i}: {list(chunk)}')
